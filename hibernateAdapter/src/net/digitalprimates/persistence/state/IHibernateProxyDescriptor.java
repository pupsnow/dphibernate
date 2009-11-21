package net.digitalprimates.persistence.state;

import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;



public interface IHibernateProxyDescriptor {
	public String getRemoteClassName();
	public Object getProxyId();
	public void setProxyId(Object object);
	public String getKey();
	public boolean matches(IHibernateProxy entity);
}
