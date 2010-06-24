package net.digitalprimates.persistence.hibernate.rpc
{
	import mx.rpc.AsyncToken;
	import mx.utils.UIDUtil;

	public class ProxyLoadRequest
	{
		private var _internalAsyncToken:AsyncToken;
		private var _className:String;
		private var _proxyID:Object;
		private var _requestKey:String;
		
		public function ProxyLoadRequest(proxyID:Object, remoteClassName:String, internalAsyncToken:AsyncToken)
		{
			this._className=remoteClassName;
			this._proxyID=proxyID;
			this._internalAsyncToken=internalAsyncToken;
			this._requestKey = UIDUtil.createUID();
		}

		[Transient]
		public function get internalAsyncToken():AsyncToken
		{
			return _internalAsyncToken;
		}

		public function get className():String
		{
			return _className;
		}

		public function get proxyID():*
		{
			return _proxyID;
		}
		public function get requestKey():String
		{
			return _requestKey;
		}

	}
}