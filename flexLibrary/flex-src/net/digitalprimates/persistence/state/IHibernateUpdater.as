package net.digitalprimates.persistence.state
{
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;

	public interface IHibernateUpdater
	{
		function save( object : IHibernateProxy , responder : IResponder = null ) : AsyncToken;
		function deleteRecord( object : IHibernateProxy , responder:IResponder = null) : AsyncToken;
	}
}