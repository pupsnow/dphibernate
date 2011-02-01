package net.digitalprimates.persistence.hibernate.manager {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.core.mx_internal;
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.introduction.IManagedEntity;
	import net.digitalprimates.persistence.hibernate.rpc.EntityMapResponder;
	import net.digitalprimates.persistence.entity.manager.IEntityManager;

	public class HibernateEntityManager extends EventDispatcher implements IEntityManager {
		
		private var ro:RemoteObject;
		private var entities:Dictionary; 
		private var _destination:String;
		
		public var serializing:Boolean = false;
		
		
		/**
		 * Destination used for the RemoteObject
		 *  
		 * @return 
		 * 
		 */
		public function get destination():String {
			return _destination;
		}

		public function set destination(value:String):void {
			if ( _destination == value ) {
				return;
			}

			_destination = value;
			
			if (!ro ) {
				ro = new RemoteObject( value );
			} else {
				ro.destination = value;
			}
		}

		/**
		 * Returns the internal RemoteObject instance used for communication 
		 * @return 
		 * 
		 */		
		public function get remoteObject():RemoteObject {
			return ro;
		}
		
		/**
		 * Clear the persistence context, causing all managed entities to become detached. 
		 * 
		 */		
		public function clear():void {
			entities = new Dictionary( true );
		}
		
		/**
		 * 
		 * Check if the instance belongs to the current persistence context.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */		
		public function contains( entity:IEntity ):Boolean {
			var val:IManagedEntity = entities[ entity ]; 
			return ( val != null );
		}

		/**
		 * 
		 * Find by primary key.
		 * 
		 * @param entityClass
		 * @param primaryKey
		 * @return 
		 * 
		 */		
		public function find( entityClass:Class, primaryKey:Object ):AsyncToken {
			
			//Hardcoded for the moment
			var token:AsyncToken = ro.getLotsByAuctionId_bidder( primaryKey );
			token.addResponder( new EntityMapResponder( this ) );
			
			return token;
		}

		/**
		 * Make an entity instance managed and persistent.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */		
		public function persist( entity:IManagedEntity ):AsyncToken {
			//maybe this should happen on the result
			manage( entity );
			return null;
		}

		public function manage( entity:IManagedEntity ):void {
			entities[ entity ] = true;
			entity.manager = this;
		}
		
		/**
		 * Refresh the state of the instance from the database, overwriting changes made to the entity, if any.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */
		public function refresh( entity:IEntity ):AsyncToken {
			return incremenetalLoad( entity as IManagedEntity );
		}
		
		/**
		 * 
		 * Remove the entity instance.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */
		public function remove( entity:IEntity ):AsyncToken {
			return null;
		}
		
		public function incremenetalLoad( entity:IManagedEntity ):AsyncToken {
			return ro.loadDPProxy( entity.proxyKey, entity );
		}
		
		public function HibernateEntityManager( destination:String=null ) {
			if ( destination ) {
				ro = new RemoteObject( destination );				
			}
			
			entities = new Dictionary( true );
		}
	}
}