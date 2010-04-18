package net.digitalprimates.persistence.translators.hibernate;

import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;

class BaseEntity implements IHibernateProxy
{
	private Boolean proxyInitialized = true;
	private Object proxyKey;
	@Override
	public Boolean getProxyInitialized()
	{
		return proxyInitialized;
	}


	@Override
	public Object getProxyKey()
	{
		return proxyKey;
	}


	@Override
	public void setProxyInitialized(Boolean b)
	{
		proxyInitialized = b;
	}


	@Override
	public void setProxyKey(Object obj)
	{
		proxyKey = obj;
	}

}
