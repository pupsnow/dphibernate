package net.digitalprimates.persistence.entity.manager {
	import mx.rpc.AsyncToken;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.introduction.IManagedEntity;

	public interface IEntityManager {
		/**
		 * Clear the persistence context, causing all managed entities to become detached. 
		 * 
		 */			
		function clear():void;
		
		/**
		 * 
		 * Check if the instance belongs to the current persistence context.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */		
		function contains( entity:IEntity ):Boolean;
		
		/**
		 * 
		 * Find by primary key.
		 * 
		 * @param entityClass
		 * @param primaryKey
		 * @return 
		 * 
		 */		
		function find( entityClass:Class, primaryKey:Object ):AsyncToken;
		
		/**
		 * Make an entity instance managed and persistent.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */		
		function persist( entity:IManagedEntity ):AsyncToken;
		
		/**
		 * Refresh the state of the instance from the database, overwriting changes made to the entity, if any.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */
		function refresh( entity:IEntity ):AsyncToken;
		
		/**
		 * 
		 * Remove the entity instance.
		 * 
		 * @param entity
		 * @return 
		 * 
		 */
		function remove( entity:IEntity ):AsyncToken;
	}
}