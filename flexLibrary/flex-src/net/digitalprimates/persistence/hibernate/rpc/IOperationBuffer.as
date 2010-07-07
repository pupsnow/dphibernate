package net.digitalprimates.persistence.hibernate.rpc
{
	import mx.rpc.AsyncToken;

	public interface IOperationBuffer
	{
		function bufferedSend(...args):AsyncToken;
		function get acceptingNewRequests():Boolean;
	}
}