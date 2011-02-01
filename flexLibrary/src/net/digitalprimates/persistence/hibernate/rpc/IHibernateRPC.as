package net.digitalprimates.persistence.hibernate.rpc {
	import mx.rpc.AsyncToken;
	
	import net.digitalprimates.persistence.entity.IEntity;

	public interface IHibernateRPC {
		function loadProxy( proxyKey:Object, entity:IEntity ):AsyncToken;	
	}
}