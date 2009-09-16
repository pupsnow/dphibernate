package net.digitalprimates.persistence.state;



public interface IHibernateProxyDescriptor {
	public String getRemoteClassName();
	public Object getProxyId();
	public void setProxyId(Object object);
	public String getKey();
}
