package net.digitalprimates.persistence.hibernate.utils.services;

import java.io.Serializable;

import org.hibernate.SessionFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class ProxyLoadService implements IProxyLoadService
{
	
	private Logger log = LoggerFactory.getLogger(ProxyLoadService.class);
	private final SessionFactory sessionFactory;
	
	public ProxyLoadService(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}

	
	@SuppressWarnings("unchecked")
	@Override
	public Object loadBean(Class daoClass, Serializable id)
	{
		if (id==null)
		{
			throw new RuntimeException("Supplied ID is null");
		}
		log.info("loadByClass : " + daoClass.getCanonicalName() + "::" + id.toString());
		if (id instanceof String)
		{
			@SuppressWarnings("unused")// For debugging...
			String originalId = (String) id;
			id = Integer.parseInt((String) id);
		}
		Object result = sessionFactory.getCurrentSession().get(daoClass, id);
		return result;
	}
}
