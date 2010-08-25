package net.digitalprimates.persistence.hibernate
{
	import net.digitalprimates.persistence.hibernate.HibernateManaged;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	import net.digitalprimates.persistence.hibernate.IHibernateROProvider;

	public class DefaultHibernateRPCProvider implements IHibernateROProvider
	{

		public function getRemoteObject(bean:IHibernateProxy):IHibernateRPC
		{
			return HibernateManaged.defaultHibernateService;
		}
	}
}