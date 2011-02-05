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
	import flash.events.IEventDispatcher;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.entity.IEntityObjectManager;
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoader;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoaderFactory;
	import net.digitalprimates.persistence.hibernate.loader.LazyLoadEvent;

	public class HibernateObjectManagerImpl implements IEntityObjectManager {
		private var factory:ILazyLoaderFactory;

		public function HibernateObjectManagerImpl( lazyLoaderFactory:ILazyLoaderFactory ) {
			this.factory = lazyLoaderFactory;
		}
		
		public function getProperty( obj:IEntity, property:String ):* {
			var entity:IHibernateManagedEntity = obj as IHibernateManagedEntity;
			var entityManager:IEntityManager = entity.manager as IEntityManager;

			entity.comStatus |= HibernateConstants.SERIALIZING;

			var lazyLoader:ILazyLoader = factory.newInstance( entity.manager, entity, property );
			lazyLoader.load();

			entity.comStatus &= (~HibernateConstants.SERIALIZING);

			if ( obj is IEventDispatcher ) {
				IEventDispatcher( obj ).dispatchEvent( new LazyLoadEvent( LazyLoadEvent.PENDING, true, true ) );
			}

			return null;
		}
		
		public function setProperty(obj:IEntity, property:String, oldValue:*, newValue:*):void {
			//Perhaps we need to throw an error if we are asked to set a property that is not yet loaded... might make things easier to debug?
			//Marty, thoughts?
		}
	}
}