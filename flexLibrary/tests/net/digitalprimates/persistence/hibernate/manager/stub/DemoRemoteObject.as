package net.digitalprimates.persistence.hibernate.manager.stub {
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.RemoteObject;
	
	import net.digitalprimates.persistence.entity.IEntity;
	
	public class DemoRemoteObject extends RemoteObject {
		public function getLotsByAuctionId_bidder( primaryKey:Object ):AsyncToken {
			return null;
		}

		public function loadDPProxy( primaryKey:Object, entity:IEntity ):AsyncToken {
			return null;
		}

		public function DemoRemoteObject(destination:String=null) {
			super(destination);
		}
	}
}