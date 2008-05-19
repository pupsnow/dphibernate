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
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.UUID;

import net.digitalprimates.persistence.hibernate.proxy.HibernateProxyConstants;
import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;
import net.digitalprimates.persistence.translators.ISerializer;

import org.hibernate.Query;
import org.hibernate.collection.AbstractPersistentCollection;
import org.hibernate.collection.PersistentCollection;
import org.hibernate.collection.PersistentMap;
import org.hibernate.engine.SessionImplementor;
import org.hibernate.event.EventSource;
import org.hibernate.impl.SessionImpl;
import org.hibernate.persister.collection.AbstractCollectionPersister;
import org.hibernate.persister.collection.CollectionPersister;
import org.hibernate.persister.collection.OneToManyPersister;
import org.hibernate.proxy.HibernateProxy;
import org.hibernate.sql.SimpleSelect;
import org.w3c.dom.Document;

import flex.messaging.io.amf.ASObject;

/**
 * convert outgoing java hibernate objects into the correct flash objects
 * 
 * @author mike nimer
 */
@SuppressWarnings("unchecked")
public class HibernateSerializer implements ISerializer
{
	private HashMap cache = new HashMap();
	// private ArrayList alreadyTouched = new ArrayList();
	private SessionManager sessionManager;


	public Object translate(String sessionFactoryClazz, String getSessionMethod, Object obj)
	{
		this.sessionManager = new SessionManager(sessionFactoryClazz, getSessionMethod);

		return translate(obj);
	}


	private Object translate(Object obj)
	{
		if( obj == null ){ return null;}
		
		Object result = null;
		
		Object key = getCacheKey(obj);

		if (cache.containsKey(key))
		{
			return cache.get(key);
		}
		
		// System.out.println("{Serializer}");
		Boolean isLazyProxy = obj instanceof HibernateProxy && (((HibernateProxy) obj).getHibernateLazyInitializer().isUninitialized());
		if (isLazyProxy)
		{
			result = writeHibernateProxy(obj, key);
		} 
		else if (obj instanceof PersistentMap)
		{
			result = writePersistantMap(obj, result, key);
		} 
		else if (obj instanceof AbstractPersistentCollection)
		{
			result = writeAbstractPersistentCollection(obj, key);
		} 
		else if (obj instanceof Collection)
		{
			result = writeCollection(obj, key);
		} 
		else if( obj instanceof IHibernateProxy )
		{
			result = writeBean(obj, result, key);
		}
		else if (obj instanceof Object 
				&& (!isSimple(obj)) 
				&& !(obj instanceof ASObject))
		{
			result = writeBean(obj, result, key);
		} 
		else
		{
			cache.put(key, obj);
			result = obj;
		}

		return result;
	}


	private boolean isSimple(Object obj)
	{
		return ((obj == null) 
				|| (obj instanceof String) 
				|| (obj instanceof Character) 
				|| (obj instanceof Boolean) 
				|| (obj instanceof Number) 
				|| (obj instanceof Date) 
				|| (obj instanceof Calendar)
				|| (obj instanceof Document));
		
	}


	private Object writeBean(Object obj, Object result, Object key)
	{
		String propName;
		
		try
		{
			ASObject asObject = new ASObject();// new ExternalASObject();
			cache.put(key, asObject);

			if (obj instanceof HibernateProxy)
			{
				asObject.setType(getClassName(obj));
			} else
			{
				asObject.setType(getClassName(obj));
			}

			asObject.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
			asObject.put(HibernateProxyConstants.PROXYINITIALIZED, true);

			BeanInfo info = Introspector.getBeanInfo(obj.getClass());
			for (PropertyDescriptor pd : info.getPropertyDescriptors())
			{
				propName = pd.getName(); 
				//System.out.println("propName=" +propName);
				if (!"class".equals(propName) && !"annotations".equals(propName) && !"hibernateLazyInitializer".equals(propName))
				{
					Object val = pd.getReadMethod().invoke(obj, null);
					Object newVal = translate(val);
					asObject.put(propName, newVal);
				}
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
		cache.put(key, list);

		Iterator itr = ((Collection) obj).iterator();
		while (itr.hasNext())
		{
			Object o = itr.next();
			list.add(translate(o));
		}
		result = list;
		return result;
	}


	private Object writeAbstractPersistentCollection(Object obj, Object key)
	{
		Object result;
		AbstractPersistentCollection collection = (AbstractPersistentCollection) obj;
		if (!collection.wasInitialized())
		{
			// go load our Collection of dpHibernateProxy objects
			List proxies = getCollectionProxies(collection);

			proxies = (List) translate(proxies);
			cache.put(key, proxies);

			result = proxies;
			// return proxies;
		} else
		{
			Object c = collection.getValue();
			List items = new ArrayList();
			cache.put(key, items);

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

			cache.put(key, map);
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

		cache.put(key, as);
		result = as;
		return result;
	}


	private Object getCacheKey(Object obj)
	{
		if (obj instanceof HibernateProxy)
		{
			return ((HibernateProxy) obj).getHibernateLazyInitializer().getPersistentClass().getName().toString() + "_" + ((HibernateProxy) obj).getHibernateLazyInitializer().getIdentifier().toString();
		} else if (  obj instanceof AbstractPersistentCollection && !((AbstractPersistentCollection)obj).wasInitialized()  )
		{
			return ((AbstractPersistentCollection) obj).getRole() + "_" + ((AbstractPersistentCollection) obj).getKey().hashCode();
		}
		return obj;
	}


	private String getClassName(Object obj)
	{
		if (obj instanceof HibernateProxy)
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
			EventSource session = (EventSource) sessionManager.getCurrentSession();
			
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
		
		if( absPersister instanceof OneToManyPersister )
		{
			keyNames = absPersister.getElementColumnNames();
		}else{
			keyNames = absPersister.getKeyColumnNames();			
		}
		//String[] columnNames = absPersister.getElementColumnNames();

		SimpleSelect pkSelect = new SimpleSelect(((SessionImpl) session).getFactory().getDialect());
		pkSelect.setTableName(absPersister.getTableName());
		pkSelect.addColumns(keyNames);
		pkSelect.addCondition(absPersister.getKeyColumnNames(), "=?");

		String sql = pkSelect.toStatementString();

		// int size = absPersister.getSize(collection.getKey(), eventSession);
		Query q2 = ((SessionImpl) session).createSQLQuery(sql).setParameter(0, collection.getKey());
		List results = q2.list();
		return results;
	}

}
