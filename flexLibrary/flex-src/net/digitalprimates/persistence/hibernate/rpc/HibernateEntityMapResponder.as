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
	import mx.rpc.IResponder;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.introduction.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.bytecode.reflect.IVisibleMember;
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.Field;
	
	public class HibernateEntityMapResponder implements IResponder {
		
		private var manager:HibernateEntityManager;
		
		public function HibernateEntityMapResponder( manager:HibernateEntityManager ) {
			this.manager = manager;
		}
		
		public function result(data:Object):void {
			//I still think I need to walk the tree, perhaps I am wrong..
			var event:ResultEvent = data as ResultEvent;
			
			if ( event.result is ICollectionView ) {
				updateCollection( ( event.result as ICollectionView ), manager );
			} else if ( event.result is IHibernateManagedEntity ) {
				updateEntity( ( event.result as IHibernateManagedEntity ), null, manager );
			}  
		}
		
		private function updateArray( array:Array, manager:HibernateEntityManager ):void {
			for ( var i:int=0; i<array.length; i++ ) {
				if ( array[ i ] is IHibernateManagedEntity ) {
					updateEntity( ( array[ i ] as IHibernateManagedEntity ), null, manager );
				} 				
			}
		}
		
		private function updateMap( object:Object, manager:HibernateEntityManager ):void {
			for ( var key:String in object ) {
				if ( object[ key ] is IHibernateManagedEntity ) {
					updateEntity( ( object[ key ] as IHibernateManagedEntity ), null,  manager );
				} 				
			}
		}
		
		private function updateCollection( collection:ICollectionView, manager:HibernateEntityManager ):void {
			var cursor:IViewCursor = collection.createCursor();
			
			while ( !cursor.afterLast ) {
				if ( cursor.current is IHibernateManagedEntity ) {
					updateEntity( ( cursor.current as IHibernateManagedEntity ), null, manager );
				} 
				
				cursor.moveNext();
			}
		}
		
		private function updateEntity( entity:IHibernateManagedEntity, parent:IEntity, manager:HibernateEntityManager ):void {
			//temporary
			var proxiedClass:Class = HibernateManager.getProxiedClass( entity );
			var type:ByteCodeType = ByteCodeType.forInstance( proxiedClass );
			var field:Field;
			var propValue:*;
			
			manager.manage( entity );
			
			if ( parent ) {
				if ( ( entity is IEventDispatcher ) && ( parent is IEventDispatcher ) ) {
					( entity as IEventDispatcher).addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, ( parent as IEventDispatcher ).dispatchEvent);
				}
			}
			
			if ( entity.proxyInitialized ) {
				//Can be made much more efficient, we should actually use the proxied class so we don't check our own introductins
				//and need to avoid things like prototype
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
						} else if ( field.type is Object ) {
							updateMap( propValue, manager );
						}
						
					}
				}
			}
		}
		
		public function fault(info:Object):void {
		}
	}
}