package net.digitalprimates.persistence.hibernate
{
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;

	public interface IUpdatableHibernateProxy extends IHibernateProxy
	{
		function save(responder:IResponder=null) : AsyncToken;
		function deleteRecord(responder:IResponder=null) : AsyncToken;
	}
}