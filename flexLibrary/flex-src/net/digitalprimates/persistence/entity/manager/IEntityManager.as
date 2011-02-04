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
package net.digitalprimates.persistence.entity.manager {
	import mx.rpc.AsyncToken;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.introduction.IHibernateManagedEntity;

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
		function persist( entity:IEntity ):AsyncToken;
		
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