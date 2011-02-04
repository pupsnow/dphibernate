/**
 * Copyright (c) 2011 Digital Primates
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author     Michael Labriola 
 * @version    
 **/
package net.digitalprimates.persistence.hibernate.manager {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.RemoteObject;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.introduction.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.rpc.HibernateEntityMapResponder;

	public class HibernateEntityManager extends EventDispatcher implements IEntityManager {
		
		private var _remoteObject:RemoteObject;
		private var entities:Dictionary; 
		private var _destination:String;
		

		/**
		 * Returns the internal RemoteObject instance used for communication 
		 * @return 
		 * 
		 */		
		public function get remoteObject():RemoteObject {
			return _remoteObject;
		}
		
		/**
		 * Clear the persistence context, causing all managed entities to become detached. 
		 * 
		 */		
		public function clear():void {
			for ( var entity:* in entities ) {
				entity.manager = null;				
			}
			
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
			var val:IHibernateManagedEntity = entities[ entity ]; 
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
			var token:AsyncToken = _remoteObject.getLotsByAuctionId_bidder( primaryKey );
			token.addResponder( new HibernateEntityMapResponder( this ) );
			
			return token;
		}

		/**
		 * Make an entity instance managed and persistent.
		 * 
		 * Thinking about making this one return the ManagedEntity, even if you give it a generic class.
		 * @param entity
		 * @return 
		 * 
		 */		
		public function persist( entity:IEntity ):AsyncToken {
			var managedEntity:IHibernateManagedEntity = verifyEntity( entity );

			//maybe this should happen on the result
			manage( managedEntity );
			return null;
		}

		public function manage( entity:IEntity ):void {
			var managedEntity:IHibernateManagedEntity = verifyEntity( entity );
			entities[ managedEntity ] = true;
			managedEntity.manager = this;
		}

		/**
		 * Refresh the state of the instance from the database, overwriting changes made to the entity, if any.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */
		public function refresh( entity:IEntity ):AsyncToken {
			var managedEntity:IHibernateManagedEntity = verifyEntity( entity ); 
			return incremenetalLoad( managedEntity );
		}
		
		/**
		 * Not sure if we will keep this. want to keep the interface generic for other entity managers in the future.. JPA, etc. 
		 * @param entity
		 * @return 
		 * 
		 */		
		private function verifyEntity( entity:IEntity ):IHibernateManagedEntity {
			if ( !(  entity is IHibernateManagedEntity ) ) {
				//make me better
				throw new Error("Hibernate Entity Manager works with IHibernateManagedEntity");
			}			
			
			return entity as IHibernateManagedEntity;
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
		
		public function incremenetalLoad( entity:IHibernateManagedEntity ):AsyncToken {
			return _remoteObject.loadDPProxy( entity.proxyKey, entity );
		}
		
		public function HibernateEntityManager( remoteObject:RemoteObject ) {
			this._remoteObject = remoteObject;
			
			entities = new Dictionary( true );
		}
	}
}