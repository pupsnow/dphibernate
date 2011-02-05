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
package net.digitalprimates.persistence.hibernate.loader {
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.manager.HibernateManager;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.IVisibleMember;
	import org.as3commons.reflect.Field;
	
	public class LazyLoader implements ILazyLoader, IResponder {
		private var manager:IHibernateEntityManager;
		private var entity:IHibernateManagedEntity;
		private var property:String;
		private var type:ByteCodeType;
		
		public function load():void {
			//Set this to pending
			entity.comStatus |= HibernateConstants.PENDING;
			
			var token:AsyncToken = manager.incremenetalLoad( entity );
			token.addResponder( this );
		}
		
		public function result(data:Object):void {
			var field:Field;
			var resultObj:IHibernateManagedEntity = data.result as IHibernateManagedEntity;
			
			//We are no longer pending
			entity.comStatus &= (~HibernateConstants.PENDING);
			
			/* The top level entity we just received was added to the EntityManager by the HibernateResultHandlerImpl
				however, since we got to this code, we can now understand that we are actually lazyloading...
			
				This means the top level entity is not important to us.. in fact, we are going to toss it and just steal
				its properties.. therefore, we need to unmanage it */
			manager.unmanage( resultObj );
			
			var properties:Array = type.properties;
			
			for ( var i:int=0; i<properties.length; i++ ) {
				field = properties[ i ] as Field;

				if ( ( field is IVisibleMember ) && ( ( field as IVisibleMember ).visibility == NamespaceKind.PACKAGE_NAMESPACE ) ) {
					copyField( resultObj, entity, field.name );
				} 
			}
			
			copyHibernateFields( resultObj, entity );

			if ( entity is IEventDispatcher ) {
				( entity as IEventDispatcher ).dispatchEvent( PropertyChangeEvent.createUpdateEvent( entity, property, null, entity[ property ] ) );
			} 
		}
		
		/**
		 * Refactor me 
		 * @param source
		 * @param destination
		 * @param propertyName
		 * 
		 */		
		private function copyField( source:*, destination:*, propertyName:String ):void {
			trace( source[ propertyName ] );
			destination[ propertyName ] = source[ propertyName ];
		}

		private function copyHibernateFields( source:IHibernateManagedEntity, destination:IHibernateManagedEntity ):void {
			destination.comStatus = source.comStatus;
			destination.proxyKey = source.proxyKey;
			destination.proxyInitialized = source.proxyInitialized;
		}
		
		public function fault(info:Object):void {
			
			var status:uint = entity.comStatus;
			status &= (~HibernateConstants.PENDING);
			
			//We are no longer pending
			entity.comStatus = status;

			//probably need to throw an error or something
			manager.dispatchEvent( info as Event );
		}

		public function LazyLoader( manager:IHibernateEntityManager, entity:IHibernateManagedEntity, property:String, type:ByteCodeType ) {
			this.manager = manager;
			this.entity = entity;
			this.property = property;
			this.type = type;
		}
	}
}