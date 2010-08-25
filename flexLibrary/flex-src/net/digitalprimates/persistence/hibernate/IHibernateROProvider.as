package net.digitalprimates.persistence.hibernate
{
	/**
	 * Defines a provider that maps entities to a HibernateRemoteObject
	 * which can be used to populate proxies.*/
	public interface IHibernateROProvider
	{
		function getRemoteObject(bean:IHibernateProxy):IHibernateRPC;
	}
}