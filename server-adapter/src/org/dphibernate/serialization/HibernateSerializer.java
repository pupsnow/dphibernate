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

package org.dphibernate.serialization;

import java.beans.BeanInfo;
import java.beans.Introspector;
import java.beans.PropertyDescriptor;
import java.lang.annotation.Annotation;
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


import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.dphibernate.collections.PaginatedCollection;
import org.dphibernate.core.HibernateProxyConstants;
import org.dphibernate.core.IHibernateProxy;
import org.dphibernate.serialization.annotations.AggressivelyProxy;
import org.dphibernate.serialization.annotations.EagerlySerialize;
import org.dphibernate.serialization.annotations.NeverSerialize;
import org.dphibernate.serialization.annotations.NoLazyLoadOnSerialize;
import org.hibernate.Query;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.collection.AbstractPersistentCollection;
import org.hibernate.collection.PersistentCollection;
import org.hibernate.collection.PersistentMap;
import org.hibernate.dialect.Dialect;
import org.hibernate.event.EventSource;
import org.hibernate.impl.SessionFactoryImpl;
import org.hibernate.persister.collection.AbstractCollectionPersister;
import org.hibernate.persister.collection.CollectionPersister;
import org.hibernate.proxy.HibernateProxy;
import org.hibernate.sql.SimpleSelect;
import org.hibernate.transform.ResultTransformer;
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
	private static final Log log = LogFactory.getLog(HibernateSerializer.class);
	private static Dialect dialect;


	public HibernateSerializer(Object source, boolean useAggressiveProxying)
	{
		super(source);
		this.useAggressiveProxying = useAggressiveProxying;
		this.cache = new DPHibernateCache();
	}


	public HibernateSerializer(Object source)
	{
		this(source, false);
	}


	public HibernateSerializer(Object source, boolean useAggressiveProxying, DPHibernateCache cache, SessionFactory sessionFactory)
	{
		this(source, useAggressiveProxying);
		this.cache = cache;
		this.sessionFactory = sessionFactory;
	}
	private DPHibernateCache cache;

	@Resource
	private SessionFactory sessionFactory;

	private int pageSize = -1;

	private boolean useAggressiveProxying;
	private boolean permitAgressiveProxyingOnRoot;


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
		// TODO : This should use a strategy pattern.
		if (isLazyProxy(objectToSerialize) && !eagerlySerialize)
		{
			result = writeHibernateProxy((HibernateProxy) objectToSerialize, cacheKey);
		} else if (shouldAggressivelyProxy(objectToSerialize, eagerlySerialize))
		{
			Object proxyKey = ((IHibernateProxy) objectToSerialize).getProxyKey();
			result = generateDpHibernateProxy(objectToSerialize, proxyKey, cacheKey);
		} else if (objectToSerialize instanceof PersistentMap)
		{
			result = writePersistantMap(objectToSerialize, result, cacheKey);
		} else if (objectToSerialize instanceof AbstractPersistentCollection)
		{
			result = writeAbstractPersistentCollection((AbstractPersistentCollection) objectToSerialize, cacheKey, eagerlySerialize);
		} else if (objectToSerialize.getClass().isArray())
		{
			result = writeArray((Object[]) objectToSerialize, cacheKey);
		} else if (objectToSerialize instanceof Collection)
		{
			result = writeCollection((Collection<?>) objectToSerialize, cacheKey);
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
		if (eagerlySerialize)
			return false;
		if (hasAnnotation(objectToSerialize, AggressivelyProxy.class))
			return true;
		if (!useAggressiveProxying)
			return false;
		return !sourceContainsProperty(objectToSerialize) && canBeAgressivelyProxied(objectToSerialize);
	}


	private boolean hasAnnotation(Object objectToSerialize, Class<? extends Annotation> annotation)
	{
		return Object.class.getAnnotation(annotation) != null;
	}


	private boolean canBeAgressivelyProxied(Object objectToSerialize)
	{
		if (!(objectToSerialize instanceof IHibernateProxy))
			return false;

		if (isRootObject(objectToSerialize))
		{
			return permitAgressiveProxyingOnRoot;
		}

		return true;
	}


	private boolean isRootObject(Object objectToSerialize)
	{
		return objectToSerialize == getSource();
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
			
			// TODO : This chunk of code is being progressively moved to PropertyHelper.java
			// However, we need better test coverage of this method before I'm comfortable just ripping it out
			BeanInfo info = Introspector.getBeanInfo(obj.getClass());
			for (PropertyDescriptor pd : info.getPropertyDescriptors())
			{
				propName = pd.getName();
				Method readMethod = pd.getReadMethod();
				if (readMethod == null)
					continue;
				boolean explicitlyFetch = PropertyHelper.methodHasAnnotation(readMethod, NoLazyLoadOnSerialize.class);
				if (explicitlyFetch)
					continue;
				if (PropertyHelper.propertyNameIsExcluded(propName))
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
					Object serializedValue;
					if (PropertyHelper.methodHasAnnotation(readMethod, AggressivelyProxy.class))
					{
						HibernateSerializer aggressiveSerializer = new HibernateSerializer(val, true, cache, sessionFactory);
						aggressiveSerializer.permitAgressiveProxyingOnRoot = true;
						serializedValue = aggressiveSerializer.serialize();
					} else
					{
						boolean eagerlySerialize = PropertyHelper.methodHasAnnotation(readMethod, EagerlySerialize.class);
						serializedValue = serialize(val, eagerlySerialize);
					}
					asObject.put(propName, serializedValue);
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


	


	private Object writeCollection(Collection<?> collection, Object key)
	{
		List list = new ArrayList();
		boolean isPaginated = false;
		for (Object collectionMemeber : collection)
		{
			Object translatedCollectionMember;
			Object collectionMemeberCacheKey = cache.getCacheKey(collectionMemeber);
			if (getPageSize() != -1 && list.size() > getPageSize())
			{
				translatedCollectionMember = getPagedCollectionProxy(collectionMemeber, collectionMemeberCacheKey);
				isPaginated = true;
			} else
			{
				translatedCollectionMember = serialize(collectionMemeber);
			}
			list.add(translatedCollectionMember);
		}
		if (isPaginated)
		{
//			list = convertToPaginatedList(list);
		}
		return list;
	}


	private List convertToPaginatedList(List list)
	{
		return new PaginatedCollection(list);
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


	private Object writeAbstractPersistentCollection(AbstractPersistentCollection collection, Object key, boolean eagerlySerialize)
	{
		Object result;
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
				items.add(newObj);
			}

			result = items;
		}
		// DEBUGGING .. Remove
		if (collection.getRole().contains("users") && result == null)
		{
			result = writeAbstractPersistentCollection(collection, key, eagerlySerialize);
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

				if (session instanceof Session)
				{
					List pkIds = getPkIds(session, absPersister, collection);

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
	private List getPkIds(Session session, AbstractCollectionPersister persister, PersistentCollection collection) throws ClassNotFoundException
	{
		List results = new ArrayList();
		/*
		 * String tablename = persister.getTableName(); Iterator entries =
		 * collection.entries(persister); while (entries.hasNext()) { Object
		 * entry = entries.next(); if (entry instanceof IHibernateProxy) {
		 * results.add(((IHibernateProxy) entry).getProxyKey()); } else {
		 * log.warn
		 * ("Cannot proxy object that does not implement IHibernateProxy"); } }
		 * return results;
		 */
		String[] keyNames;
		if (persister.isOneToMany() || persister.isManyToMany())
		{
			keyNames = persister.getElementColumnNames();
		} else
		{
			keyNames = persister.getKeyColumnNames();
		}
		// String[] columnNames = absPersister.getElementColumnNames();
		Dialect dialect = getDialect(persister);
		SimpleSelect pkSelect = new SimpleSelect(dialect);
		pkSelect.setTableName(persister.getTableName());
		pkSelect.addColumns(keyNames);
		pkSelect.addCondition(persister.getKeyColumnNames(), "=?");

		String sql = pkSelect.toStatementString();

		try
		{
			// int size = absPersister.getSize(collection.getKey(),
			// eventSession);
			ResultTransformer transformer = ResultTransformerUtil.PASS_THROUGH_RESULT_TRANSFORMER;
			Query q2 = session.createSQLQuery(sql).setParameter(0, collection.getKey()).setResultTransformer(transformer);

			// List hibernateResults = q2.list();
			// return results;

			Type t = persister.getKeyType();

			PreparedStatement stmt = session.connection().prepareStatement(sql);
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


	private Dialect getDialect(AbstractCollectionPersister persister)
	{
		if (HibernateSerializer.dialect == null)
		{
			try
			{
				HibernateSerializer.dialect = Dialect.getDialect();
			} catch (Throwable t)
			{
				SessionFactoryImpl sfi = (SessionFactoryImpl) sessionFactory;
				HibernateSerializer.dialect = sfi.getDialect();
			}
			if (HibernateSerializer.dialect == null)
			{
				throw new RuntimeException("Could not determine dialect");
			}
		}
		return HibernateSerializer.dialect;

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
		if (sourcePropertyValues == null)
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
				if (PropertyHelper.propertyNameIsExcluded(propName))
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


	@Override
	public void configure(SerializerConfiguration configuration)
	{
		this.pageSize = configuration.getPageSize();
	}
}
