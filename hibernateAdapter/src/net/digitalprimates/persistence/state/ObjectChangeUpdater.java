package net.digitalprimates.persistence.state;

import static ch.lambdaj.Lambda.filter;
import static ch.lambdaj.Lambda.on;
import static ch.lambdaj.function.matcher.HasArgumentWithValue.having;
import static org.hamcrest.Matchers.is;

import java.io.Serializable;
import java.security.Principal;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;
import net.digitalprimates.persistence.translators.hibernate.DPHibernateCache;

import org.hibernate.SessionFactory;
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

	@Resource
	private SessionFactory sessionFactory;

	@Resource
	private IProxyResolver proxyResolver;

	@Resource
	private DPHibernateCache cache;

	private List<String> processedKeys = new ArrayList<String>();

	// When creating a chain of entities, we only commit the very top level
	// and let hibernate do the rest
	private IHibernateProxy topLevelEntity;

	private Map<IHibernateProxy, ObjectChangeMessage> entitiesAwaitingCommit = new HashMap<IHibernateProxy, ObjectChangeMessage>();

	private List<IChangeMessageInterceptor> postProcessors;

	private List<IChangeMessageInterceptor> preProcessors;


	@SuppressWarnings("unchecked")
	@Transactional(readOnly = false)
	public List<ObjectChangeResult> update(ObjectChangeMessage changeMessage)
	{
		try
		{
			applyPreProcessors(changeMessage);
		} catch (ObjectChangeAbortedException e)
		{
			// TODO : Handle this - the change was not permitted
			throw new RuntimeException(e);
		}
		List<ObjectChangeResult> result = processUpdate(changeMessage);
		applyPostProcessors(changeMessage);
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
				if (authentication != null)
				{
					interceptor.processMessage(changeMessage, (Principal) authentication.getPrincipal());
				} else
				{
					interceptor.processMessage(changeMessage);
				}
			}
		}
	}


	private void applyPreProcessors(ObjectChangeMessage changeMessage) throws ObjectChangeAbortedException
	{
		applyInterceptors(changeMessage, getPreProcessors());
	}


	private List<ObjectChangeResult> processUpdate(ObjectChangeMessage changeMessage)
	{
		List<ObjectChangeResult> result = new ArrayList<ObjectChangeResult>();
		if (changeMessage.getResult() != null)
			return result; // We've already processed this message.
		if (processedKeys.contains(changeMessage.getOwner().getKey()))
		{
			return result;
		}
		processedKeys.add(changeMessage.getOwner().getKey());
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
				for (IHibernateProxy entityAwaitingCommit : entitiesAwaitingCommit.keySet())
				{
					if (entityAwaitingCommit.getProxyKey() != null)
					{
						ObjectChangeMessage dependantChangeMessage = entitiesAwaitingCommit.get(entityAwaitingCommit);
						ObjectChangeResult dependentMessageResult = new ObjectChangeResult(dependantChangeMessage, entityAwaitingCommit.getProxyKey());
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
	public List<ObjectChangeResult> update(List<ObjectChangeMessage> changeMessages)
	{
		// For debugging:
		// XStream xStream = new XStream();
		// System.out.println(xStream.toXML(changeMessages));

		// Update new items first
		List<ObjectChangeMessage> newObjects = filter(having(on(ObjectChangeMessage.class).getIsNew(), is(true)), changeMessages);
		UpdateDependencyResolver dependencyResolver = new UpdateDependencyResolver();
		dependencyResolver.addMessages(newObjects);
		List<ObjectChangeMessage> newMessagesOrderedByDependency = dependencyResolver.getOrderedList();
		List<ObjectChangeResult> result = doUpdate(newMessagesOrderedByDependency);

		changeMessages.removeAll(newObjects);
		result.addAll(doUpdate(changeMessages));
		return result;
	}


	private List<ObjectChangeResult> doUpdate(List<ObjectChangeMessage> changeMessages)
	{
		List<ObjectChangeResult> result = new ArrayList<ObjectChangeResult>();
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
