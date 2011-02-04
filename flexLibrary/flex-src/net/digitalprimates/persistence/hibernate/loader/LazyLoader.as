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
	import flash.events.IEventDispatcher;
	
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import net.digitalprimates.persistence.hibernate.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.introduction.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.IVisibleMember;
	import org.as3commons.reflect.Field;
	
	public class LazyLoader implements IResponder {
		private var manager:HibernateEntityManager;
		private var entity:IHibernateManagedEntity;
		private var property:String;
		
		public function load():void {
			var token:AsyncToken = manager.incremenetalLoad( entity );
			token.addResponder( this );
		}
		
		public function result(data:Object):void {
			//temporary
			var proxiedClass:Class = HibernateManager.getProxiedClass( entity );
			var type:ByteCodeType = ByteCodeType.forInstance( proxiedClass );
			var field:Field;
			var resultObj:* = data.result;
			
			//We are no longer pending
			entity.comStatus &= (~HibernateConstants.PENDING);
			
			//Can be made much more efficient, we should actually use the proxied class so we don't check our own introductins
			//and need to avoid things like prototype
			var properties:Array = type.properties;
			
			for ( var i:int=0; i<properties.length; i++ ) {
				field = properties[ i ] as Field;

				if ( ( field is IVisibleMember ) && ( ( field as IVisibleMember ).visibility == NamespaceKind.PACKAGE_NAMESPACE ) ) {
					copyField( resultObj, entity, field.name );
				} 
			}

			if ( entity is IEventDispatcher ) {
				( entity as IEventDispatcher ).dispatchEvent( PropertyChangeEvent.createUpdateEvent( entity, null, null, null ) );
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
			destination[ propertyName ] = source[ propertyName ];

			if ( destination[ propertyName ] is IHibernateManagedEntity ) {
				setupEntity( destination[ propertyName ] as IHibernateManagedEntity, destination );
			}					
			
		}
		
		private function setupEntity( entity:IHibernateManagedEntity, parent:IHibernateManagedEntity ):void {
			//Duplicated code.... need to refactor EntityMapResponder and this
			manager.manage( entity );
			
			if ( ( entity is IEventDispatcher ) && ( parent is IEventDispatcher ) ) {
				( entity as IEventDispatcher).addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, ( parent as IEventDispatcher ).dispatchEvent);
			}
		}
		
		public function fault(info:Object):void {
			//We are no longer pending
			entity.comStatus &= (~HibernateConstants.PENDING);

			//probably need to throw an error or something
			manager.dispatchEvent( info.clone() );
		}

		public function LazyLoader( manager:HibernateEntityManager, entity:IHibernateManagedEntity, property:String ) {
			this.manager = manager;
			this.entity = entity;
			this.property = property;
		}
	}
}