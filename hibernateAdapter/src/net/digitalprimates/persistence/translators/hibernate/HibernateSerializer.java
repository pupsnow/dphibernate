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
import java.beans.IntrospectionException;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.reflect.InvocationTargetException;
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
import net.digitalprimates.persistence.translators.AbstractSerializer;

import org.hibernate.Query;
import org.hibernate.SessionFactory;
import org.hibernate.collection.AbstractPersistentCollection;
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
public class HibernateSerializer extends AbstractSerializer
{
	public HibernateSerializer(Object source,boolean useAggressiveProxying)
	{
		super(source);
		this.useAggressiveProxying = useAggressiveProxying;
	}
	public HibernateSerializer(Object source)
	{
		this(source,false);
	}

	// private HashMap cache = new HashMap();
	// private ArrayList alreadyTouched = new ArrayList();
	@Resource
	private DPHibernateCache cache;

	@Resource
	private SessionFactory sessionFactory;

	private int pageSize = -1;
	private int serializedHibernateProxyCount = 0;
	
	private boolean useAggressiveProxying;
	

	public void setSessionFactory(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}


	public SessionFactory getSessionFactory()
	{
		return sessionFactory;
	}


	@Transactional
	@Override
	/**
	 * Serializes the source object.
	 * This is the public entry point into serialization
	 */
	public Object serialize()
	{
		return serialize(getSource());
	}


	/**
	 * Private serialization for members of getSource(). Called recursively
	 * during serialization
	 */
	private Object serialize(Object source)
	{
		return serialize(source, false);
	}


	/**
	 * Private serialization for members of getSource(). Called recursively
	 * during serialization
	 */

	private Object serialize(Object objectToSerialize, boolean eagerlySerialize)
	{
		if (objectToSerialize == null)
		{
			return null;
		}

		Object result = null;

		Object key = cache.getCacheKey(objectToSerialize);

		if (cache.contains(key))
		{
			return cache.get(key);
		}
		result = writeBean(objectToSerialize, key, eagerlySerialize);

		return result;
	}


	private boolean isLazyProxy(Object obj)
	{
		return obj instanceof HibernateProxy && (((HibernateProxy) obj).getHibernateLazyInitializer().isUninitialized());
	}


	private Object writeBean(Object objectToSerialize, Object cacheKey, boolean eagerlySerialize)
	{
		Object result = null;

		if (isLazyProxy(objectToSerialize) && !eagerlySerialize)
		{
			result = writeHibernateProxy((HibernateProxy) objectToSerialize, cacheKey);
		} else if (shouldAggressivelyProxy(objectToSerialize, eagerlySerialize)) {
			Object proxyKey = ((IHibernateProxy)objectToSerialize).getProxyKey();
			result = generateDpHibernateProxy(objectToSerialize,proxyKey,cacheKey);
		}else if (objectToSerialize instanceof PersistentMap)
		{
			result = writePersistantMap(objectToSerialize, result, cacheKey);
		} else if (objectToSerialize instanceof AbstractPersistentCollection)
		{
			result = writeAbstractPersistentCollection(objectToSerialize, cacheKey, eagerlySerialize);
		} else if (objectToSerialize.getClass().isArray())
		{
			result = writeArray((Object[]) objectToSerialize, cacheKey);
		} else if (objectToSerialize instanceof Collection)
		{
			result = writeCollection(objectToSerialize, cacheKey);
		} else if (objectToSerialize instanceof Map)
		{
			result = writeMap(objectToSerialize, cacheKey);
		} else if (objectToSerialize instanceof IHibernateProxy)
		{
			result = writeBean(objectToSerialize, cacheKey);
		} else if (objectToSerialize instanceof Object && (!TypeHelper.isSimple(objectToSerialize)) && !(objectToSerialize instanceof ASObject))
		{
			result = writeBean(objectToSerialize, cacheKey);
		} else
		{
			cache.store(cacheKey, objectToSerialize);
			result = objectToSerialize;
		}
		return result;
	}


	private boolean shouldAggressivelyProxy(Object objectToSerialize, boolean eagerlySerialize)
	{
		if (eagerlySerialize) return false;
		if (!useAggressiveProxying) return false;
		return !sourceContainsProperty(objectToSerialize) && canBeProxied(objectToSerialize); 
	}


	private boolean canBeProxied(Object objectToSerialize)
	{
		return objectToSerialize instanceof IHibernateProxy && objectToSerialize != getSource();
	}


	private ASObject writeBean(Object obj, Object cacheKey)
	{
		String propName;
		ASObject asObject = new ASObject();
		try
		{
			cache.store(cacheKey, asObject);

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
				if (propertyNameIsExcluded(propName))
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
					Object newVal = serialize(val, eagerlySerialize);
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
		} catch (Exception ex)
		{
			ex.printStackTrace();
		}
		return asObject;
	}


	private Object writeCollection(Object obj, Object key)
	{
		Object result;
		ArrayList list = new ArrayList();
		// cache.put(key, list);

		Iterator itr = ((Collection) obj).iterator();
		while (itr.hasNext())
		{
			Object collectionMemeber = itr.next();
			Object translatedCollectionMember;
			Object collectionMemeberCacheKey = cache.getCacheKey(collectionMemeber);
			if (getPageSize() != -1 && list.size() > getPageSize())
			{
				translatedCollectionMember = getPagedCollectionProxy(collectionMemeber, collectionMemeberCacheKey);
			} else
			{
				translatedCollectionMember = serialize(collectionMemeber);
			}
			list.add(translatedCollectionMember);
		}
		result = list;
		return result;
	}


	private Object getPagedCollectionProxy(Object collectionMemeber, Object cacheKey)
	{
		if (isLazyProxy(collectionMemeber))
		{
			return writeHibernateProxy((HibernateProxy) collectionMemeber, cacheKey);
		} else if (collectionMemeber instanceof IHibernateProxy)
		{
			return generateDpHibernateProxy(collectionMemeber, ((IHibernateProxy) collectionMemeber).getProxyKey(), cacheKey);
		} else
		{ // Default... we can't provide a proxy for this item, so translate it.
			return serialize(collectionMemeber);
		}

	}


	private Object writeArray(Object[] obj, Object key)
	{
		Object result;
		ArrayList list = new ArrayList();
		for (Object member : obj)
		{
			result = serialize(member);
			list.add(result);
		}
		return list.toArray();
	}


	private ASObject writeMap(Object obj, Object key)
	{
		if (obj instanceof ASObject)
		{
			return (ASObject) obj;
		}

		ASObject asObj = new ASObject();
		asObj.setType(getClassName(obj));

		cache.store(key, asObj);

		Set keys = ((Map) obj).keySet();
		Iterator keysItr = keys.iterator();
		while (keysItr.hasNext())
		{
			Object thisKey = keysItr.next();
			Object o = ((Map) obj).get(thisKey);
			asObj.put(thisKey, serialize(o));
		}
		return asObj;
	}


	private Object writeAbstractPersistentCollection(Object obj, Object key, boolean eagerlySerialize)
	{
		Object result;
		AbstractPersistentCollection collection = (AbstractPersistentCollection) obj;
		if (!collection.wasInitialized() && !eagerlySerialize)
		{
			// go load our Collection of dpHibernateProxy objects
			List proxies = getCollectionProxies(collection);

			proxies = (List) serialize(proxies);
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
				Object newObj = serialize(next);
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


	private ASObject writeHibernateProxy(HibernateProxy obj, Object key)
	{
		Object primaryKey = obj.getHibernateLazyInitializer().getIdentifier();
		return generateDpHibernateProxy(obj, primaryKey, key);
	}


	private ASObject generateDpHibernateProxy(Object obj, Object objectIdentifier, Object cacheKey)
	{
		ASObject as = new ASObject();
		as.setType(getClassName(obj));
		as.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
		as.put(HibernateProxyConstants.PKEY, objectIdentifier);
		as.put(HibernateProxyConstants.PROXYINITIALIZED, false);// !hibProxy.getHibernateLazyInitializer().isUninitialized());

		cache.store(cacheKey, as);
		return as;
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


	boolean sourceContainsProperty(Object member)
	{
		for (Object propertyValue : getSourcePropertyValues())
		{
			if (propertyValue == member)
				return true;
		}
		return false;
	}
	private List<Object> sourcePropertyValues;
	private List<Object> getSourcePropertyValues()
	{
		if (sourcePropertyValues==null)
		{
			sourcePropertyValues = getPropertyValues(getSource());
		}
		return sourcePropertyValues;
	}
	private List<Object> getPropertyValues(Object member)
	{
		List<Object> result = new ArrayList<Object>();
		BeanInfo info;
		try
		{
			info = Introspector.getBeanInfo(member.getClass());

			for (PropertyDescriptor pd : info.getPropertyDescriptors())
			{
				String propName = pd.getName();
				Method readMethod = pd.getReadMethod();
				if (readMethod == null)
					continue;
				if (propertyNameIsExcluded(propName))
				{
					continue;
				}
				Object val = readMethod.invoke(member, null);
				if (val != null)
					result.add(val);
			}
		} catch (Exception e)
		{
			throw new RuntimeException(e);
		}
		return result;
	}


	private boolean propertyNameIsExcluded(String propName)
	{
		return propName.equals("handler") || propName.equals("class") || propName.equals("hibernateLazyInitializer");
	}


	public void setCache(DPHibernateCache cache)
	{
		this.cache = cache;
	}


	public DPHibernateCache getCache()
	{
		return cache;
	}


	public void setPageSize(int pageSize)
	{
		this.pageSize = pageSize;
	}


	public int getPageSize()
	{
		return pageSize;
	}


	public void setUseAggressiveProxying(boolean useAggressiveProxying)
	{
		this.useAggressiveProxying = useAggressiveProxying;
	}


	public boolean isUsingAggressiveProxying()
	{
		return useAggressiveProxying;
	}
}
