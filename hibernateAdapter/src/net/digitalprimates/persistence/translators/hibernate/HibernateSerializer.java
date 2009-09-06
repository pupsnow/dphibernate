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
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import javax.annotation.Resource;

import net.digitalprimates.persistence.annotations.NoLazyLoadOnSerialize;
import net.digitalprimates.persistence.hibernate.proxy.HibernateProxyConstants;
import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;
import net.digitalprimates.persistence.translators.ISerializer;

import org.hibernate.CacheMode;
import org.hibernate.Hibernate;
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
import org.w3c.dom.Document;


import flex.messaging.io.amf.ASObject;

/**
 * convert outgoing java hibernate objects into the correct flash objects
 * 
 * @author mike nimer
 */
@SuppressWarnings("unchecked")
@Transactional(readOnly = true)
public class HibernateSerializer implements ISerializer {
	private HashMap cache = new HashMap();
	// private ArrayList alreadyTouched = new ArrayList();

	@Resource
	private SessionFactory sessionFactory;

	public void setSessionFactory(SessionFactory sessionFactory) {
		this.sessionFactory = sessionFactory;
	}

	public SessionFactory getSessionFactory() {
		return sessionFactory;
	}

	public Object translate(String sessionFactoryClazz,
			String getSessionMethod, Object obj) {
		// this.sessionManager = new SessionManager(sessionFactoryClazz,
		// getSessionMethod);

		return translate(obj);
	}

	private Object translate(Object obj) {
		if (obj == null) {
			return null;
		}

		Object result = null;

		Object key = getCacheKey(obj);

		if (cache.containsKey(key)) {
			return cache.get(key);
		}
		// System.out.println("{Serializer}");
		Boolean isLazyProxy = obj instanceof HibernateProxy
				&& (((HibernateProxy) obj).getHibernateLazyInitializer()
						.isUninitialized());
		if (isLazyProxy) {
			result = writeHibernateProxy(obj, key);
		} else if (obj instanceof PersistentMap) {
			result = writePersistantMap(obj, result, key);
		} else if (obj instanceof AbstractPersistentCollection) {
			if (obj.getClass().getAnnotation(NoLazyLoadOnSerialize.class) != null) {
				System.out.println("Not fetching - Explicit fetch");
				result = null;
			} else {
				result = writeAbstractPersistentCollection(obj, key);
			}
		} else if (obj.getClass().isArray()) {
			result = writeArray((Object[]) obj, key);
		} else if (obj instanceof Collection) {
			result = writeCollection(obj, key);
		} else if (obj instanceof Map) {
			result = writeMap(obj, key);
		} else if (obj instanceof IHibernateProxy) {
			result = writeBean(obj, result, key);
		} else if (obj instanceof Object && (!isSimple(obj))
				&& !(obj instanceof ASObject)) {
			result = writeBean(obj, result, key);
		} else {
			cache.put(key, obj);
			result = obj;
		}

		return result;
	}

	private boolean isSimple(Object obj) {
		return ((obj == null) 
				|| (obj instanceof String)
				|| (obj instanceof Character) 
				|| (obj instanceof Boolean)
				|| (obj instanceof Number) 
				|| (obj instanceof Date)
				|| (obj instanceof Calendar) 
				|| (obj instanceof Document))
				|| (obj instanceof Enum);
	}

	private Object writeBean(Object obj, Object result, Object key) {
		String propName;

		try {
			ASObject asObject = new ASObject();// new ExternalASObject();
			cache.put(key, asObject);

			if (obj instanceof HibernateProxy) {
				asObject.setType(getClassName(obj));
			} else {
				asObject.setType(getClassName(obj));
			}

			asObject.put(HibernateProxyConstants.UID, UUID.randomUUID()
					.toString());
			asObject.put(HibernateProxyConstants.PROXYINITIALIZED, true);

			BeanInfo info = Introspector.getBeanInfo(obj.getClass());
			for (PropertyDescriptor pd : info.getPropertyDescriptors()) {
				propName = pd.getName();
				boolean isExplicitFetch = (pd.getReadMethod() != null && pd
						.getReadMethod().getAnnotation(
								net.digitalprimates.persistence.annotations.NoLazyLoadOnSerialize.class) != null);
				// System.out.println("propName=" +propName);
				if (!"handler".equals(propName) && !"class".equals(propName)
						&& pd.getReadMethod() != null && !isExplicitFetch
						&& !"annotations".equals(propName)
						&& !"hibernateLazyInitializer".equals(propName)) {
					try {
						Object val = pd.getReadMethod().invoke(obj, null);
						if (val == null) {
							asObject.put(propName, val);
						} else {
							Object newVal = translate(val);
							asObject.put(propName, newVal);
						}
					} catch (Exception ex) {
						ex.printStackTrace();
					}
				}
			}
			result = asObject;
		} catch (Exception ex) {
			ex.printStackTrace();
		}
		return result;
	}

	private Object writeCollection(Object obj, Object key) {
		Object result;
		ArrayList list = new ArrayList();
		// cache.put(key, list);

		Iterator itr = ((Collection) obj).iterator();
		while (itr.hasNext()) {
			Object o = itr.next();
			list.add(translate(o));
		}
		result = list;
		return result;
	}

	private Object writeArray(Object[] obj, Object key) {
		Object result;
		ArrayList list = new ArrayList();
		for (Object member : obj) {
			result = translate(member);
			list.add(result);
		}
		return list.toArray();
	}

	private Object writeMap(Object obj, Object key) {
		if (obj instanceof ASObject) {
			return obj;
		}

		Object result;
		ASObject asObj = new ASObject();
		asObj.setType(getClassName(obj));

		cache.put(key, asObj);

		Set keys = ((Map) obj).keySet();
		Iterator keysItr = keys.iterator();
		while (keysItr.hasNext()) {
			Object thisKey = keysItr.next();
			Object o = ((Map) obj).get(thisKey);
			asObj.put(thisKey, translate(o));
		}
		result = asObj;
		return result;
	}

	private Object writeAbstractPersistentCollection(Object obj, Object key) {
		Object result;
		AbstractPersistentCollection collection = (AbstractPersistentCollection) obj;
		if (!collection.wasInitialized()) {
			// go load our Collection of dpHibernateProxy objects
			List proxies = getCollectionProxies(collection);

			proxies = (List) translate(proxies);
			result = proxies;

			cache.put(key, proxies);
			// return proxies;
		} else {
			Object c = collection.getValue();
			List items = new ArrayList();
			cache.put(key, items);

			Iterator itr = collection.entries(null);
			while (itr.hasNext()) {
				Object next = itr.next();
				Object newObj = translate(next);
				obj = newObj;
				items.add(newObj);
			}

			result = items;
		}
		return result;
	}

	private Object writePersistantMap(Object obj, Object result, Object key) {
		if (((PersistentMap) obj).wasInitialized()) {
			HashMap map = new HashMap();
			// Set entries = ((PersistentMap)obj).entrySet();
			Set keys = ((PersistentMap) obj).keySet();

			Iterator keyItr = keys.iterator();
			while (keyItr.hasNext()) {
				Object mapKey = keyItr.next();
				map.put(mapKey, ((PersistentMap) obj).get(mapKey));
			}

			cache.put(key, map);
			result = map;
		} else {
			// todo
			throw new RuntimeException("Lazy loaded maps not implimented yet.");
		}
		return result;
	}

	private Object writeHibernateProxy(Object obj, Object key) {
		Object result;
		HibernateProxy hibProxy = (HibernateProxy) obj;

		ASObject as = new ASObject();
		as.setType(getClassName(obj));
		as.put(HibernateProxyConstants.UID, UUID.randomUUID().toString());
		as.put(HibernateProxyConstants.PKEY, hibProxy
				.getHibernateLazyInitializer().getIdentifier());
		as.put(HibernateProxyConstants.PROXYINITIALIZED, false);// !hibProxy.getHibernateLazyInitializer().isUninitialized());

		cache.put(key, as);
		result = as;
		return result;
	}

	private Object getCacheKey(Object obj) {
		if (obj instanceof HibernateProxy) {
			return ((HibernateProxy) obj).getHibernateLazyInitializer()
					.getPersistentClass().getName().toString()
					+ "_"
					+ ((HibernateProxy) obj).getHibernateLazyInitializer()
							.getIdentifier().toString();
		} else if (obj instanceof AbstractPersistentCollection
				&& !((AbstractPersistentCollection) obj).wasInitialized()) {
			return ((AbstractPersistentCollection) obj).getRole() + "_"
					+ ((AbstractPersistentCollection) obj).getKey().hashCode();
		} 
		return obj;
	}

	private String getClassName(Object obj) {
		if (obj instanceof ASObject) {
			return ((ASObject) obj).getType();
		} else if (obj instanceof HibernateProxy) {
			return ((HibernateProxy) obj).getHibernateLazyInitializer()
					.getPersistentClass().getName().toString();
		} else {
			return obj.getClass().getName();
		}
	}

	private List getCollectionProxies(PersistentCollection collection) {
		try {
			EventSource session = (EventSource) getSessionFactory()
					.getCurrentSession();

			// CollectionMetadata metadata =
			// eventSession.getFactory().getCollectionMetadata(collection.getRole());
			CollectionPersister persister = session.getFactory()
					.getCollectionPersister(collection.getRole());

			if (persister instanceof AbstractCollectionPersister) {
				AbstractCollectionPersister absPersister = (AbstractCollectionPersister) persister;
				String className = absPersister.getElementType().getName();

				if (session instanceof SessionImpl) {
					List pkIds = getPkIds(session, persister, collection);

					// create a new HibernateProxy for each id.
					List proxies = new ArrayList();
					Iterator pkItr = pkIds.iterator();
					while (pkItr.hasNext()) {
						Object key = pkItr.next();

						// create flex object to represent the
						// PersistanceProxy
						ASObject as = new ASObject();// new
						// ExternalASObject();
						as.setType(className);
						as.put(HibernateProxyConstants.UID, UUID.randomUUID()
								.toString());
						as.put(HibernateProxyConstants.PKEY, key);
						as.put(HibernateProxyConstants.PROXYINITIALIZED, false);
						proxies.add(as);
					}
					return proxies;
				}
			}

		} catch (Exception ex) {
			ex.printStackTrace();
		} catch (Throwable ex) {
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
	private List getPkIds(SessionImplementor session,
			CollectionPersister persister, PersistentCollection collection)
			throws ClassNotFoundException {
		AbstractCollectionPersister absPersister = (AbstractCollectionPersister) persister;
		String[] keyNames;

		if (absPersister.isOneToMany() || absPersister.isManyToMany()) {
			keyNames = absPersister.getElementColumnNames();
		} else {
			keyNames = absPersister.getKeyColumnNames();
		}
		// String[] columnNames = absPersister.getElementColumnNames();

		SimpleSelect pkSelect = new SimpleSelect(((SessionImpl) session)
				.getFactory().getDialect());
		pkSelect.setTableName(absPersister.getTableName());
		pkSelect.addColumns(keyNames);
		pkSelect.addCondition(absPersister.getKeyColumnNames(), "=?");

		String sql = pkSelect.toStatementString();
		List results = new ArrayList();

		try {
			// int size = absPersister.getSize(collection.getKey(),
			// eventSession);
			Query q2 = ((SessionImpl) session).createSQLQuery(sql)
					.setParameter(0, collection.getKey()).setResultTransformer(
							new PassThroughResultTransformer());

//			List hibernateResults = q2.list();
			// return results;

			Type t = persister.getKeyType();

			PreparedStatement stmt = ((SessionImpl) session).connection()
					.prepareStatement(sql);
			if (t instanceof StringType) {
				stmt.setString(1, collection.getKey().toString());
			} else {
				stmt.setObject(1, new Integer(collection.getKey().toString())
						.intValue());
			}

			ResultSet keyResults = stmt.executeQuery();

			while (keyResults.next()) {
				results.add(keyResults.getObject(1));
			}
			stmt.close();

		} catch (Exception ex) {
			ex.printStackTrace();
		}

		return results;
	}

}
