/**
	Copyright (c) 2008. Digital Primates IT Consulting Group
	http://www.digitalprimates.net
	All rights reserved.
	
	This library is free software; you can redistribute it and/or modify it under the 
	terms of the GNU Lesser General Public License as published by the Free Software 
	Foundation; either version 2.1 of the License.

	This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
	See the GNU Lesser General Public License for more details.

	
	@author: Mike Nimer
	@ignore
 **/

package net.digitalprimates.persistence.translators.hibernate;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.Method;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import javax.annotation.Resource;

import net.digitalprimates.persistence.annotations.EagerlySerialize;
import net.digitalprimates.persistence.annotations.NeverSerialize;
import net.digitalprimates.persistence.annotations.NoLazyLoadOnSerialize;
import net.digitalprimates.persistence.hibernate.proxy.HibernateProxyConstants;
import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;
import net.digitalprimates.persistence.translators.ISerializer;

import org.hibernate.Query;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.collection.AbstractPersistentCollection;
import org.hibernate.collection.PersistentBag;
import org.hibernate.collection.PersistentCollection;
import org.hibernate.collection.PersistentMap;
import org.hibernate.engine.SessionImplementor;
import org.hibernate.event.EventSource;
import org.hibernate.impl.SessionImpl;
import org.hibernate.persister.collection.AbstractCollectionPersister;
import org.hibernate.persister.collection.CollectionPersister;
import org.hibernate.proxy.HibernateProxy;
import org.hibernate.sql.SimpleSelect;
import org.hibernate.transform.PassThroughResultTransformer;
import org.hibernate.type.StringType;
import org.hibernate.type.Type;
import org.springframework.transaction.annotation.Transactional;

import flex.messaging.io.amf.ASObject;

/**
 * convert outgoing java hibernate objects into the correct flash objects
 * 
 * @author mike nimer
 */
@SuppressWarnings("unchecked")
@Transactional(readOnly = true)
public class HibernateSerializer implements ISerializer
{
	// private HashMap cache = new HashMap();
	// private ArrayList alreadyTouched = new ArrayList();
	@Resource
	private DPHibernateCache cache;

	@Resource
	private SessionFactory sessionFactory;


	public void setSessionFactory(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}


	public SessionFactory getSessionFactory()
	{
		return sessionFactory;
	}

	@Transactional
	public Object translate(String sessionFactoryClazz, String getSessionMethod, Object obj)
	{
		// this.sessionManager = new SessionManager(sessionFactoryClazz,
		// getSessionMethod);
		Session session = getSessionFactory().getCurrentSession();
		/*
		boolean objectInSession = session.contains(obj);
		/*
		if (!objectInSession)
		{
			throw new RuntimeException("Object for translation not in session.  Ensure either OpenSessionInViewFilter or OpenSessionInViewInterceptor is configured");
		}
		*/
		return translate(obj);
	}


	private Object translate(Object obj)
	{
		return translate(obj, false);
	}


	private Object translate(Object obj, boolean eagerlySerialize)
	{
		if (obj == null)
		{
			return null;
		}

		Object result = null;

		Object key = cache.getCacheKey(obj);

		if (cache.contains(key))
		{
			return cache.get(key);
		}
		result = writeBean(obj, key, eagerlySerialize);

		return result;
	}


	private Object writeBean(Object source, Object key, boolean eagerlySerialize)
	{
		Object result = null;
		boolean isLazyProxy = source instanceof HibernateProxy && (((HibernateProxy) source).getHibernateLazyInitializer().isUninitialized());

		if (isLazyProxy && !eagerlySerialize)
		{
			result = writeHibernateProxy(source, key);
		} else if (source instanceof PersistentMap)
		{
			result = writePersistantMap(source, result, key);
		} else if (source instanceof AbstractPersistentCollection)
		{
			result = writeAbstractPersistentCollection(source, key, eagerlySerialize);
		} else if (source.getClass().isArray())
		{
			result = writeArray((Object[]) source, key);
		} else if (source instanceof Collection)
		{
			result = writeCollection(source, key);
		} else if (source instanceof Map)
		{
			result = writeMap(source, key);
		} else if (source instanceof IHibernateProxy)
		{
			result = writeBean(source, result, key);
		} else if (source instanceof Object && (!TypeHelper.isSimple(source)) && !(source instanceof ASObject))
		{
			result = writeBean(source, result, key);
		} else
		{
			cache.store(key, source);
			result = source;
		}
		return result;
	}


	private Object writeBean(Object obj, Object result, Object key)
	{
		String propName;

		try
		{
			ASObject asObject = new ASObject();
			cache.store(key, asObject);

			asObject.setType(getClassName(obj));
			asObject.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
			asObject.put(HibernateProxyConstants.PROXYINITIALIZED, true);

			BeanInfo info = Introspector.getBeanInfo(obj.getClass());
			for (PropertyDescriptor pd : info.getPropertyDescriptors())
			{
				propName = pd.getName();
				Method readMethod = pd.getReadMethod();
				if (readMethod == null)
					continue;
				boolean isExplicitFetch = (readMethod.getAnnotation(NoLazyLoadOnSerialize.class) != null);
				if (isExplicitFetch)
					continue;
				if (propName.equals("handler") || propName.equals("class") || propName.equals("hibernateLazyInitializer"))
				{
					continue;
				}
				try
				{
					Object val = readMethod.invoke(obj, null);
					boolean neverSerialize = (readMethod.getAnnotation(NeverSerialize.class) != null);
					if (neverSerialize)
					{
						continue;
					}
					boolean eagerlySerialize = (readMethod.getAnnotation(EagerlySerialize.class) != null);
					Object newVal = translate(val,eagerlySerialize);
					asObject.put(propName, newVal);
				} catch (Exception ex)
				{
					ex.printStackTrace();
				}
			}
			if (obj instanceof IHibernateProxy)
			{
				Object primaryKey = ((IHibernateProxy) obj).getProxyKey();
				asObject.put(HibernateProxyConstants.PKEY, primaryKey);
			}
			result = asObject;
		} catch (Exception ex)
		{
			ex.printStackTrace();
		}
		return result;
	}


	private Object writeCollection(Object obj, Object key)
	{
		Object result;
		ArrayList list = new ArrayList();
		// cache.put(key, list);

		Iterator itr = ((Collection) obj).iterator();
		while (itr.hasNext())
		{
			Object o = itr.next();
			list.add(translate(o));
		}
		result = list;
		return result;
	}


	private Object writeArray(Object[] obj, Object key)
	{
		Object result;
		ArrayList list = new ArrayList();
		for (Object member : obj)
		{
			result = translate(member);
			list.add(result);
		}
		return list.toArray();
	}


	private Object writeMap(Object obj, Object key)
	{
		if (obj instanceof ASObject)
		{
			return obj;
		}

		Object result;
		ASObject asObj = new ASObject();
		asObj.setType(getClassName(obj));

		cache.store(key, asObj);

		Set keys = ((Map) obj).keySet();
		Iterator keysItr = keys.iterator();
		while (keysItr.hasNext())
		{
			Object thisKey = keysItr.next();
			Object o = ((Map) obj).get(thisKey);
			asObj.put(thisKey, translate(o));
		}
		result = asObj;
		return result;
	}


	private Object writeAbstractPersistentCollection(Object obj, Object key, boolean eagerlySerialize)
	{
		Object result;
		AbstractPersistentCollection collection = (AbstractPersistentCollection) obj;
		if (!collection.wasInitialized() && !eagerlySerialize)
		{
			// go load our Collection of dpHibernateProxy objects
			List proxies = getCollectionProxies(collection);

			proxies = (List) translate(proxies);
			result = proxies;

			cache.store(key, proxies);
			// return proxies;
		} else
		{
			if (!collection.wasInitialized())
			{
				collection.forceInitialization();
			}
			Object c = collection.getValue();
			List items = new ArrayList();
			cache.store(key, items);

			Iterator itr = collection.entries(null);
			while (itr.hasNext())
			{
				Object next = itr.next();
				Object newObj = translate(next);
				obj = newObj;
				items.add(newObj);
			}

			result = items;
		}
		return result;
	}


	private Object writePersistantMap(Object obj, Object result, Object key)
	{
		if (((PersistentMap) obj).wasInitialized())
		{
			HashMap map = new HashMap();
			// Set entries = ((PersistentMap)obj).entrySet();
			Set keys = ((PersistentMap) obj).keySet();

			Iterator keyItr = keys.iterator();
			while (keyItr.hasNext())
			{
				Object mapKey = keyItr.next();
				map.put(mapKey, ((PersistentMap) obj).get(mapKey));
			}

			cache.store(key, map);
			result = map;
		} else
		{
			// todo
			throw new RuntimeException("Lazy loaded maps not implimented yet.");
		}
		return result;
	}


	private Object writeHibernateProxy(Object obj, Object key)
	{
		Object result;
		HibernateProxy hibProxy = (HibernateProxy) obj;

		ASObject as = new ASObject();
		as.setType(getClassName(obj));
		as.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
		as.put(HibernateProxyConstants.PKEY, hibProxy.getHibernateLazyInitializer().getIdentifier());
		as.put(HibernateProxyConstants.PROXYINITIALIZED, false);// !hibProxy.getHibernateLazyInitializer().isUninitialized());

		cache.store(key, as);
		result = as;
		return result;
	}


	private String getClassName(Object obj)
	{
		if (obj instanceof ASObject)
		{
			return ((ASObject) obj).getType();
		} else if (obj instanceof HibernateProxy)
		{
			return ((HibernateProxy) obj).getHibernateLazyInitializer().getPersistentClass().getName().toString();
		} else
		{
			return obj.getClass().getName();
		}
	}


	private List getCollectionProxies(PersistentCollection collection)
	{
		try
		{
			EventSource session = (EventSource) getSessionFactory().getCurrentSession();

			// CollectionMetadata metadata =
			// eventSession.getFactory().getCollectionMetadata(collection.getRole());
			CollectionPersister persister = session.getFactory().getCollectionPersister(collection.getRole());

			if (persister instanceof AbstractCollectionPersister)
			{
				AbstractCollectionPersister absPersister = (AbstractCollectionPersister) persister;
				String className = absPersister.getElementType().getName();

				if (session instanceof SessionImpl)
				{
					List pkIds = getPkIds(session, persister, collection);

					// create a new HibernateProxy for each id.
					List proxies = new ArrayList();
					Iterator pkItr = pkIds.iterator();
					while (pkItr.hasNext())
					{
						Object key = pkItr.next();

						// create flex object to represent the
						// PersistanceProxy
						ASObject as = new ASObject();// new
						// ExternalASObject();
						as.setType(className);
						as.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
						as.put(HibernateProxyConstants.PKEY, key);
						as.put(HibernateProxyConstants.PROXYINITIALIZED, false);
						proxies.add(as);
					}
					return proxies;
				}
			}

		} catch (Exception ex)
		{
			ex.printStackTrace();
		} catch (Throwable ex)
		{
			ex.printStackTrace();
		}
		return null;
	}


	/**
	 * Query the database and get a result set of IDS that belong to a specific
	 * collection
	 * 
	 * @return
	 */
	private List getPkIds(SessionImplementor session, CollectionPersister persister, PersistentCollection collection) throws ClassNotFoundException
	{
		AbstractCollectionPersister absPersister = (AbstractCollectionPersister) persister;
		String[] keyNames;

		if (absPersister.isOneToMany() || absPersister.isManyToMany())
		{
			keyNames = absPersister.getElementColumnNames();
		} else
		{
			keyNames = absPersister.getKeyColumnNames();
		}
		// String[] columnNames = absPersister.getElementColumnNames();

		SimpleSelect pkSelect = new SimpleSelect(((SessionImpl) session).getFactory().getDialect());
		pkSelect.setTableName(absPersister.getTableName());
		pkSelect.addColumns(keyNames);
		pkSelect.addCondition(absPersister.getKeyColumnNames(), "=?");

		String sql = pkSelect.toStatementString();
		List results = new ArrayList();

		try
		{
			// int size = absPersister.getSize(collection.getKey(),
			// eventSession);
			Query q2 = ((SessionImpl) session).createSQLQuery(sql).setParameter(0, collection.getKey()).setResultTransformer(new PassThroughResultTransformer());

			// List hibernateResults = q2.list();
			// return results;

			Type t = persister.getKeyType();

			PreparedStatement stmt = ((SessionImpl) session).connection().prepareStatement(sql);
			if (t instanceof StringType)
			{
				stmt.setString(1, collection.getKey().toString());
			} else
			{
				stmt.setObject(1, new Integer(collection.getKey().toString()).intValue());
			}

			ResultSet keyResults = stmt.executeQuery();

			while (keyResults.next())
			{
				results.add(keyResults.getObject(1));
			}
			stmt.close();

		} catch (Exception ex)
		{
			ex.printStackTrace();
		}

		return results;
	}


	public void setCache(DPHibernateCache cache)
	{
		this.cache = cache;
	}


	public DPHibernateCache getCache()
	{
		return cache;
	}

}
