package net.digitalprimates.persistence.hibernate.utils.services;

import java.io.Serializable;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Map.Entry;

import net.digitalprimates.persistence.hibernate.DPHibernateException;

import org.hibernate.Criteria;
import org.hibernate.SessionFactory;
import org.hibernate.classic.Session;
import org.hibernate.criterion.Criterion;
import org.hibernate.criterion.IdentifierEqExpression;
import org.hibernate.criterion.Restrictions;

import com.google.common.collect.ArrayListMultimap;

public class ProxyBatchLoader implements IProxyBatchLoader
{
	
	SessionFactory sessionFactory;

	public ProxyBatchLoader(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}
	@Override
	public List<ProxyLoadResult> loadProxyBatch(ProxyLoadRequest[] requests)
	{
		// Order the requests by class Type
		// For each class type, gather the ID's
		// Load each group of entities
		// Map each loaded entity back to the original request object
		// and generate a matching response.
		Map<String, Collection<Serializable>> requestsByClass = getRequestsByClass(requests);
		Set<Entry<String, Collection<Serializable>>> requestClassEntrySet = requestsByClass.entrySet();
		for (Entry<String, Collection<Serializable>> requestClassEntry : requestClassEntrySet)
		{
			List<Object> loadedEntities = loadEntities(requestClassEntry);
//			List<ProxyLoadResult> loadResults = mapLoadedEntitesToOriginalRequest(loadedEntities,requests);
		}
		return null;
	}
	private List<Object> loadEntities(Entry<String, Collection<Serializable>> requestClassEntry) 
	{
		Class<?> requestClass = getRequestClass(requestClassEntry.getKey());
		Criteria criteria = sessionFactory.getCurrentSession().createCriteria(requestClass);
		criteria.add(Restrictions.in("id", requestClassEntry.getValue()));
		List<Object> results = criteria.list();
		return results;
//		session.get
//		String keyName;
//		IdentifierEqExpression identifierExpression = IdentifierEqExpression();
//		Restrictions.naturalId().
//		criteria.add(Restrictions.in(keyName, requestClassEntry.getValue()));
	}
	private Class<?> getRequestClass(String className)
	{
		try
		{
			Class<?> entryClass = Class.forName(className);
			return entryClass;
		} catch (ClassNotFoundException e)
		{
			throw new DPHibernateException(className + " is not a recognized class");
		}
	}
	Map<String,Collection<Serializable>> getRequestsByClass(ProxyLoadRequest[] requests) {
		ArrayListMultimap<String, Serializable> requestsByClass = ArrayListMultimap.create();
		for (ProxyLoadRequest request : requests)
		{
			requestsByClass.put(request.getClassName(), request.getProxyID());
		}
		return requestsByClass.asMap();
	}
}
