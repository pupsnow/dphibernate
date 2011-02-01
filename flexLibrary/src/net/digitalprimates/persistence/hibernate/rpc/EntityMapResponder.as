package net.digitalprimates.persistence.hibernate.rpc {
	import mx.collections.ArrayCollection;
	import mx.collections.ICollectionView;
	import mx.collections.IViewCursor;
	import mx.rpc.IResponder;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.hibernate.introduction.IManagedEntity;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateManager;
	
	import org.as3commons.reflect.Accessor;
	import org.as3commons.reflect.Field;
	import org.as3commons.reflect.Type;
	
	public class EntityMapResponder implements IResponder {

		private var manager:HibernateEntityManager;

		public function EntityMapResponder( manager:HibernateEntityManager ) {
			this.manager = manager;
		}
		
		public function result(data:Object):void {
			//I still think I need to walk the tree, perhaps I am wrong..
			var event:ResultEvent = data as ResultEvent;

			if ( event.result is ICollectionView ) {
				updateCollection( ( event.result as ICollectionView ), manager );
			} else if ( event.result is IManagedEntity ) {
				updateEntity( ( event.result as IManagedEntity ), manager );
			}  
		}

		private function updateArray( array:Array, manager:HibernateEntityManager ):void {
			for ( var i:int=0; i<array.length; i++ ) {
				if ( array[ i ] is IManagedEntity ) {
					updateEntity( ( array[ i ] as IManagedEntity ), manager );
				} 				
			}
		}

		private function updateMap( object:Object, manager:HibernateEntityManager ):void {
			for ( var key:String in object ) {
				if ( object[ key ] is IManagedEntity ) {
					updateEntity( ( object[ key ] as IManagedEntity ), manager );
				} 				
			}
		}
		
		private function updateCollection( collection:ICollectionView, manager:HibernateEntityManager ):void {
			var cursor:IViewCursor = collection.createCursor();
			
			while ( !cursor.afterLast ) {
				if ( cursor.current is IManagedEntity ) {
					updateEntity( ( cursor.current as IManagedEntity ), manager );
				} 
				
				cursor.moveNext();
			}
		}
		
		private function updateEntity( entity:IManagedEntity, manager:HibernateEntityManager ):void {
			var type:Type = Type.forInstance( entity );
			var field:Field;
			var propValue:*;

			manager.manage( entity );
			
			if ( entity.proxyInitialized ) {
				//Can be made much more efficient, we should actually use the proxied class so we don't check our own introductins
				//and need to avoid things like prototype
				var properties:Array = type.properties;

				for ( var i:int=0; i<properties.length; i++ ) {
					field = properties[ i ] as Field;
					
					//Bad but just don't know how to check what is private or public right now
					if ( ( field.name != 'prototype' ) && ( field.name != 'methodInvocationInterceptor' ) ) {
						propValue = field.getValue( entity );
						if ( propValue is IManagedEntity ) {
							updateEntity( propValue, manager );
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