package net.digitalprimates.persistence.collections
{
	
	import flash.utils.Dictionary;
	
	import mx.collections.ArrayList;
	import mx.collections.errors.ItemPendingError;
	import mx.logging.ILogger;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import net.digitalprimates.persistence.hibernate.HibernateManaged;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	import net.digitalprimates.util.LogUtil;
	
	public class ManagedArrayList extends ArrayList
	{
		private var pendingItems : Dictionary = new Dictionary(); // Of AsyncToken,PendingItem
		private var log : ILogger = LogUtil.getLogger(this);
		public function ManagedArrayList(source:Array=null)
		{
			super(source);
		}
		override public function getItemAt(index:int, prefetch:int=0) : Object
		{
			var result : Object = super.getItemAt(index,prefetch);
			if (result is IHibernateProxy && IHibernateProxy(result).proxyInitialized == false)
			{
				handleRemoteItem(IHibernateProxy(result),index,prefetch);
			}
			return result;
		}
		private function handleRemoteItem(proxy:IHibernateProxy,index:int,prefetch:int):void
		{
			var remoteObject : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( proxy );
			if (remoteObject == null)
			{
				// TODO : Can I recover from this?
				throw new Error("No HibernateRPC object associated with IHibernateProxy.  Ensure that HibernateManaged.defaultRemoteObject is set!");
			}
			// TODO : Handle prefetch
			var token : AsyncToken = remoteObject.loadProxy(proxy.proxyKey,proxy);
			token.addResponder(new Responder(onPendingItemLoaded,onFault));
			var itemPendingError : ItemPendingError = new ItemPendingError("Item is pending");
			var pendingItem:PendingItem = new PendingItem(itemPendingError,index);
			pendingItems[token] = pendingItem;
//			throw itemPendingError;
		}
		
		private function onPendingItemLoaded(data:Object):void
		{
			var resultEvent:ResultEvent = ResultEvent(data);
			var token:AsyncToken = resultEvent.token;
			var pendingItem : PendingItem = pendingItems[token];
			if (!pendingItem)
			{
				log.error("Received result for loaded pending item, but no PendingItem record was waiting!");
				return;
			}
			var result:Object = resultEvent.result;
			this.setItemAt(result,pendingItem.index);
			for each ( var responder : IResponder in pendingItem.error.responders )
			{
				responder.result(data);
			}
			delete pendingItems[token]
		}
		private function onFault(info:Object):void
		{
			log.error("Fault when trying to load paged collection data",ObjectUtil.toString(info));
			var fault : FaultEvent = info as FaultEvent;
			if (!fault) return;
			var token:AsyncToken = fault.token;
			var pendingItem : PendingItem = pendingItems[token];
			for each ( var responder : IResponder in pendingItem.error.responders )
			{
				responder.fault( info );
			}
			delete pendingItems[token]
									
		}

	}
}
import mx.collections.errors.ItemPendingError;

class PendingItem {
	public var error : ItemPendingError;
	public var index : int;
	public function PendingItem(error:ItemPendingError,index:int)
	{
		this.error = error;
		this.index = index;
	}
}