package org.dphibernate.persistence.state;

import static ch.lambdaj.Lambda.filter;
import static ch.lambdaj.Lambda.on;
import static ch.lambdaj.function.matcher.HasArgumentWithValue.havingValue;
import static org.hamcrest.Matchers.is;

import java.io.Serializable;
import java.security.Principal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import javax.annotation.Resource;


import org.dphibernate.core.IHibernateProxy;
import org.dphibernate.persistence.interceptors.IChangeMessageInterceptor;
import org.dphibernate.serialization.DPHibernateCache;
import org.hibernate.SessionFactory;
import org.hibernate.TransactionException;
import org.hibernate.TypeMismatchException;
import org.springframework.security.Authentication;
import org.springframework.security.context.SecurityContextHolder;
import org.springframework.transaction.annotation.Transactional;

/**
 * This class is not thread-safe. Use with prototype scope.
 * 
 * @author owner
 * 
 */
@Transactional
public class ObjectChangeUpdater implements IObjectChangeUpdater
{

	public ObjectChangeUpdater(){}
	public ObjectChangeUpdater(SessionFactory sessionFactory,IProxyResolver proxyResolver,DPHibernateCache cache)
	{
		this.sessionFactory = sessionFactory;
		this.proxyResolver = proxyResolver;
		this.cache = cache;
	}
	public ObjectChangeUpdater(SessionFactory sessionFactory,IProxyResolver proxyResolver)
	{
		this.sessionFactory = sessionFactory;
		this.proxyResolver = proxyResolver;
		this.cache = new DPHibernateCache();
	}
	@Resource
	private SessionFactory sessionFactory;

	@Resource
	private IProxyResolver proxyResolver;

	@Resource
	private DPHibernateCache cache;

	private Map<String,Set<ObjectChangeResult>> processedKeys = new HashMap<String,Set<ObjectChangeResult>>();

	// When creating a chain of entities, we only commit the very top level
	// and let hibernate do the rest
	private IHibernateProxy topLevelEntity;

	private HashMap<IHibernateProxy, ObjectChangeMessage> entitiesAwaitingCommit = new HashMap<IHibernateProxy, ObjectChangeMessage>();

	private List<IChangeMessageInterceptor> postProcessors;

	private List<IChangeMessageInterceptor> preProcessors;


	@SuppressWarnings("unchecked")
	public Set<ObjectChangeResult> update(ObjectChangeMessage changeMessage)
	{
		Set<ObjectChangeResult> result = processUpdate(changeMessage);
		return result;
	}


	private void applyPostProcessors(ObjectChangeMessage changeMessage)
	{
		applyInterceptors(changeMessage, getPostProcessors());
	}


	private void applyInterceptors(ObjectChangeMessage changeMessage, List<IChangeMessageInterceptor> interceptors)
	{
		if (interceptors == null)
			return;
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		for (IChangeMessageInterceptor interceptor : interceptors)
		{
			if (interceptor.appliesToMessage(changeMessage))
			{
				if (authentication != null && !authentication.getPrincipal().equals("roleAnonymous"))
				{
					interceptor.processMessage(changeMessage, proxyResolver, (Principal) authentication.getPrincipal());
				} else
				{
					interceptor.processMessage(changeMessage, proxyResolver);
				}
			}
		}
	}


	private void applyPreProcessors(ObjectChangeMessage changeMessage) throws ObjectChangeAbortedException
	{
		applyInterceptors(changeMessage, getPreProcessors());
	}


	private Set<ObjectChangeResult> processUpdate(ObjectChangeMessage changeMessage)
	{
		Set<ObjectChangeResult> result = new HashSet<ObjectChangeResult>();
		if (changeMessage.getResult() != null)
		{
			// We've already processed this message.
			result.add(changeMessage.getResult());
			return result;
		}
		String changeMessageKey = changeMessage.getOwner().getKey();
		if (processedKeys.containsKey(changeMessageKey))
		{
			// WORKAROUND:
			// Sometimes we can get multiple instances of change messages
			// for new objects when adding to a collection.
			// The "CREATE" has already been processed, and the result is stored,
			// but needs to be set on other collection member messages
			result = processedKeys.get(changeMessageKey);
			if (result.size() == 1 && changeMessage.getResult() == null)
			{
				changeMessage.setResult(result.iterator().next());
				changeMessage.setCreatedEntity(proxyResolver.resolve(changeMessage.getOwner()));
			}
			return result;
		}
		processedKeys.put(changeMessageKey,result);
		if (!changeMessage.hasChanges() && !changeMessage.getIsDeleted())
			return result;
		IHibernateProxy entity = getEntity(changeMessage);
		if (changeMessage.getIsNew())
		{
			proxyResolver.addInProcessProxy(changeMessage.getOwner().getKey(), entity);
			if (topLevelEntity == null)
				topLevelEntity = entity;
		}
		if (entity == null)
		{
			if (changeMessage.getIsDeleted())
			{
				// Let's not stress too much if we can't find the entity -- we were gonna kill it anyway...
				return result;
			}
			throw new IllegalArgumentException("No entity found or created");
		}
		if (changeMessage.getIsDeleted())
		{
			sessionFactory.getCurrentSession().delete(entity);
			return result;
		}
		for (PropertyChangeMessage propertyChangeMessage : changeMessage.getChangedProperties())
		{
			IChangeUpdater updater = getPropertyChangeUpdater(propertyChangeMessage, entity, proxyResolver);
			result.addAll(updater.update());
		}
		if (changeMessage.getIsNew())
		{
			if (entity == topLevelEntity)
			{
				Serializable pk = sessionFactory.getCurrentSession().save(entity);
				ObjectChangeResult messageResult = new ObjectChangeResult(entity.getClass(), changeMessage.getOwner().getProxyId(), pk);
				changeMessage.setResult(messageResult);
				result.add(messageResult);
				/*
				 * proxyResolver.removeInProcessProxy(changeMessage.getOwner()
				 * .getKey(), entity);
				 */
				for (Entry<IHibernateProxy, ObjectChangeMessage> entityAwaitingCommit : entitiesAwaitingCommit.entrySet())
				{
					IHibernateProxy proxy = entityAwaitingCommit.getKey();
					if (proxy.getProxyKey() != null)
					{
						ObjectChangeMessage dependantChangeMessage = entityAwaitingCommit.getValue();
						ObjectChangeResult dependentMessageResult = new ObjectChangeResult(dependantChangeMessage, proxy.getProxyKey());
						dependantChangeMessage.setResult(dependentMessageResult);
						result.add(dependentMessageResult);
						entitiesAwaitingCommit.remove(entityAwaitingCommit);
					}
				}
				topLevelEntity = null;
			} else
			{
				entitiesAwaitingCommit.put(entity, changeMessage);
			}

		} else
		{
			sessionFactory.getCurrentSession().update(entity);
		}
		invalidateCacheForObject(changeMessage, entity);
		return result;

	}


	private void invalidateCacheForObject(ObjectChangeMessage changeMessage, Object entity)
	{
		cache.invalidate(changeMessage, entity);
	}


	@Transactional(readOnly = false)
	@Override
	public Set<ObjectChangeResult> update(List<ObjectChangeMessage> changeMessages)
	{
		// For debugging:
		// XStream xStream = new XStream();
		// System.out.println(xStream.toXML(changeMessages));
		
		List<ObjectChangeMessage> changeMessagesToProcess = new ArrayList<ObjectChangeMessage>(changeMessages);
		applyPreProcessors(changeMessages);
		
		// Update new items first
		List<ObjectChangeMessage> newObjects = filter(havingValue(on(ObjectChangeMessage.class).getIsNew(), is(true)), changeMessagesToProcess);
		UpdateDependencyResolver dependencyResolver = new UpdateDependencyResolver();
		dependencyResolver.addMessages(newObjects);
		List<ObjectChangeMessage> newMessagesOrderedByDependency = dependencyResolver.getOrderedList();
		Set<ObjectChangeResult> result = doUpdate(newMessagesOrderedByDependency);

		changeMessagesToProcess.removeAll(newObjects);
		result.addAll(doUpdate(changeMessagesToProcess));
		
		applyPostProcessors(changeMessages);
		return result;
	}


	private void applyPreProcessors(List<ObjectChangeMessage> changeMessages) throws ObjectChangeAbortedException
	{
		for (ObjectChangeMessage changeMessage:changeMessages)
		{
			applyPreProcessors(changeMessage);
		}
	}


	private void applyPostProcessors(List<ObjectChangeMessage> changeMessages)
	{
		for (ObjectChangeMessage changeMessage : changeMessages)
		{
			applyPostProcessors(changeMessage);
		}
	}
	


	private Set<ObjectChangeResult> doUpdate(List<ObjectChangeMessage> changeMessages)
	{
		Set<ObjectChangeResult> result = new HashSet<ObjectChangeResult>();
		for (ObjectChangeMessage message : changeMessages)
		{
			result.addAll(update(message));
		}
		
		return result;
	}


	private IChangeUpdater getPropertyChangeUpdater(PropertyChangeMessage propertyChangeMessage, IHibernateProxy entity, IProxyResolver proxyResolver2)
	{
		if (propertyChangeMessage instanceof CollectionChangeMessage)
		{
			return new CollectionChangeUpdater((CollectionChangeMessage) propertyChangeMessage, entity, proxyResolver2, this);
		} else
		{
			return new PropertyChangeUpdater(propertyChangeMessage, entity, proxyResolver2);
		}
	}


	@SuppressWarnings("unchecked")
	private IHibernateProxy getEntity(ObjectChangeMessage changeMessage)
	{
		String className = changeMessage.getOwner().getRemoteClassName();
		Class<? extends IHibernateProxy> entityClass;
		try
		{
			entityClass = (Class<? extends IHibernateProxy>) Class.forName(className);
		} catch (Exception e)
		{
			throw new RuntimeException(e);
		}

		if (changeMessage.getIsNew())
		{
			try
			{
				IHibernateProxy instance = entityClass.newInstance();
				changeMessage.setCreatedEntity(instance);
				return instance;
			} catch (Exception e)
			{
				throw new RuntimeException(e);
			}
		} else
		{
			try
			{
				Serializable primaryKey = (Serializable) changeMessage.getOwner().getProxyId();
				if (primaryKey instanceof String)
				{
					primaryKey = Integer.parseInt((String) primaryKey);
				}
				Object entity = sessionFactory.getCurrentSession().get(entityClass, primaryKey);
				return (IHibernateProxy) entity;
			} catch (TypeMismatchException e)
			{
				e.printStackTrace();
				throw e;
			}
		}
	}


	public void setCache(DPHibernateCache cache)
	{
		this.cache = cache;
	}


	public DPHibernateCache getCache()
	{
		return cache;
	}


	@Override
	public List<ObjectChangeMessage> orderByDependencies(List<ObjectChangeMessage> objectChangeMessages)
	{
		return null;
	}


	public void setSessionFactory(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}


	public SessionFactory getSessionFactory()
	{
		return sessionFactory;
	}


	public void setPreProcessors(List<IChangeMessageInterceptor> preProcessors)
	{
		this.preProcessors = preProcessors;
	}


	public List<IChangeMessageInterceptor> getPreProcessors()
	{
		return preProcessors;
	}


	public void setPostProcessors(List<IChangeMessageInterceptor> postProcessors)
	{
		this.postProcessors = postProcessors;
	}


	public List<IChangeMessageInterceptor> getPostProcessors()
	{
		return postProcessors;
	}

}