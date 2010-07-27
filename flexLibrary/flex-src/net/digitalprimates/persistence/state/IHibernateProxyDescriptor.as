package net.digitalprimates.persistence.state
{
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	
	public interface IHibernateProxyDescriptor
	{
		function get remoteClassName() : String;
		function get proxyId() : Object;
		function get source() : IHibernateProxy;
	}
}