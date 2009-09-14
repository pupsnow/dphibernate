package net.digitalprimates.persistence.state;

import java.io.Serializable;


public interface IHibernateProxyDescriptor {
	public String getRemoteClassName();
	public Serializable getProxyId();
	public void setProxyId(Serializable proxyId);
	public String getKey();
}
