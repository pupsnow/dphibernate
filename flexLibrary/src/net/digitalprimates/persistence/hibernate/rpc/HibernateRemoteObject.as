package net.digitalprimates.persistence.hibernate.rpc {
	import flash.utils.flash_proxy;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import net.digitalprimates.persistence.entity.IEntity;

	use namespace flash_proxy;

	dynamic public class HibernateRemoteObject extends RemoteObject implements IHibernateRPC {

		public function loadProxy( proxyKey:Object, entity:IEntity ):AsyncToken {
			return this.loadDPProxy( proxyKey, entity );
		}
		
		override flash_proxy function callProperty(name:*, ... args:Array):*
		{
			var token:AsyncToken;
			
//			HibernateManaged.disableServerCalls( this );
			token = getOperation( name ).send.apply(null, args);
			
//			HibernateManaged.addHibernateResponder( this, token );
//			HibernateManaged.enableServerCalls( this );
			
			return token;
		}

		public function HibernateRemoteObject()
		{
		}
	}
}