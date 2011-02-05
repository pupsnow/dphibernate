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
package net.digitalprimates.persistence.hibernate.rpc {
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.core.IPropertyChangeNotifier;
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AbstractOperation;
	import mx.rpc.IResponder;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.manager.HibernateManager;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.IVisibleMember;
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.Field;
	
	public class HibernateResultHandlerImpl implements IHibernateResultHandler {
		private var manager:IHibernateEntityManager;
		
		public function HibernateResultHandlerImpl( manager:IHibernateEntityManager ) {
			this.manager = manager;
		}
		
		public function resultConversionFunction(result:*, operation:AbstractOperation ):* {
			if ( result is IHibernateManagedEntity ) {
				updateEntity( result, null, manager );
			} else if ( result is ICollectionView ) {
				updateCollection( result, manager );
			} else if ( result is Array ) {
				updateArray( result, manager );
			} 			

			return result;
		}
		
		private function updateArray( array:Array, manager:IHibernateEntityManager ):void {
			for ( var i:int=0; i<array.length; i++ ) {
				if ( array[ i ] is IHibernateManagedEntity ) {
					updateEntity( ( array[ i ] as IHibernateManagedEntity ), null, manager );
				} 				
			}
		}
		
		private function updateMap( object:Object, manager:IHibernateEntityManager ):void {
			for ( var key:String in object ) {
				if ( object[ key ] is IHibernateManagedEntity ) {
					updateEntity( ( object[ key ] as IHibernateManagedEntity ), null,  manager );
				} 				
			}
		}
		
		private function updateCollection( collection:ICollectionView, manager:IHibernateEntityManager ):void {
			var cursor:IViewCursor = collection.createCursor();
			
			while ( !cursor.afterLast ) {
				if ( cursor.current is IHibernateManagedEntity ) {
					updateEntity( ( cursor.current as IHibernateManagedEntity ), null, manager );
				} 
				
				cursor.moveNext();
			}
		}
		
		private function updateEntity( entity:IHibernateManagedEntity, parent:IEntity, manager:IHibernateEntityManager ):void {
			//Don't love this, but not sure how else to handle yet
			var type:ByteCodeType = manager.getTypeInfoForProxiedClass( entity );
			var field:Field;
			var propValue:*;
			
			manager.manage( entity );
			
			if ( parent ) {
				if ( ( entity is IEventDispatcher ) && ( parent is IEventDispatcher ) ) {
					( entity as IEventDispatcher).addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, ( parent as IEventDispatcher ).dispatchEvent);
				}
			}
			
			if ( entity.proxyInitialized ) {
				var properties:Array = type.properties;
				
				for ( var i:int=0; i<properties.length; i++ ) {
					field = properties[ i ] as Field;
					
					if ( ( field is IVisibleMember ) && ( ( field as IVisibleMember ).visibility == NamespaceKind.PACKAGE_NAMESPACE ) ) {
						propValue = field.getValue( entity );
						
						if ( propValue is IHibernateManagedEntity ) {
							updateEntity( propValue, entity, manager );
						} else if ( propValue is ICollectionView ) {
							updateCollection( propValue, manager );
						} else if ( propValue is Array ) {
							updateArray( propValue, manager );
						} 
							/*
							Need to figure out a better way as every property falls through to here and there is no need for that
							Doesn't hurt, just slower than it needs to be
						
							else if ( field.type is Object ) {
							updateMap( propValue, manager );
						}*/
					}
				}
			}
		}
		
	}
}