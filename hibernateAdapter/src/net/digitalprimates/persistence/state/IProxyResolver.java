package net.digitalprimates.persistence.state;

import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;

public interface IProxyResolver {
	public Object resolve(IHibernateProxyDescriptor proxy);

	public void addInProcessProxy(Object proxyKey, IHibernateProxy entity);
	public void removeInProcessProxy(Object proxyKey, IHibernateProxy entity);
	
}
