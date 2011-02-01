package net.digitalprimates.persistence.hibernate.introduction {
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;

	public interface IManagedEntity extends IEntity {
		function get manager():IEntityManager;
		function set manager( value:IEntityManager ):void;
		function get proxyKey():Object;
		function set proxyKey( value:Object ):void;
		function get proxyInitialized():Boolean;
		function set proxyInitialized( value:Boolean ):void;
	}
}