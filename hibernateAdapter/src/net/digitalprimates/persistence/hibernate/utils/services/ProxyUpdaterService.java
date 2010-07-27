package net.digitalprimates.persistence.hibernate.utils.services;

import java.util.List;
import java.util.Set;

import net.digitalprimates.persistence.state.DbProxyResolver;
import net.digitalprimates.persistence.state.IObjectChangeUpdater;
import net.digitalprimates.persistence.state.IProxyResolver;
import net.digitalprimates.persistence.state.ObjectChangeMessage;
import net.digitalprimates.persistence.state.ObjectChangeResult;
import net.digitalprimates.persistence.state.ObjectChangeUpdater;

import org.hibernate.SessionFactory;
import org.springframework.transaction.annotation.Transactional;

public class ProxyUpdaterService implements IProxyUpdateService
{
	private final SessionFactory sessionFactory;

	public ProxyUpdaterService(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}
	
	@Transactional(readOnly=false)
	@Override
	public Set<ObjectChangeResult> saveBean(List<ObjectChangeMessage> objectChangeMessage)
	{
		// A new changeUpdater is created for each incoming request.
		// This is by design, to keep changeUpdaters single-use.
		IObjectChangeUpdater changeUpdater = buildObjectChangeUpdater();
		return changeUpdater.update(objectChangeMessage);
	}
	@Transactional(readOnly=false)
	@Override
	public Set<ObjectChangeResult> saveBean(ObjectChangeMessage objectChangeMessage)
	{
		// A new changeUpdater is created for each incoming request.
		// This is by design, to keep changeUpdaters single-use.
		IObjectChangeUpdater changeUpdater = buildObjectChangeUpdater();
		return changeUpdater.update(objectChangeMessage);
	}
	
	IObjectChangeUpdater buildObjectChangeUpdater()
	{
		IProxyResolver proxyResolver = buildProxyResolver();
		return new ObjectChangeUpdater(sessionFactory, proxyResolver);
	}
	IProxyResolver buildProxyResolver()
	{
		return new DbProxyResolver(sessionFactory);
	}
}
