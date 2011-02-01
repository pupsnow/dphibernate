package net.digitalprimates.persistence.hibernate.manager {
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import net.digitalprimates.persistence.entity.proxy.EntityProxyBuilder;

	public class HibernateManager {
		private static var entityProxyBuilder:EntityProxyBuilder;
		private static var initialized:Boolean = false;

		public static function initialize( loaderInfo:LoaderInfo, success:Function=null, failure:Function=null ):void {

			//Until we clean this up, just guard against it being called twice
			if ( initialized ) {
				return;
			}

			entityProxyBuilder = new EntityProxyBuilder( loaderInfo );
			
			if ( success != null ) {
				entityProxyBuilder.addEventListener( Event.COMPLETE, success );
			}

			if ( failure != null ) {
				entityProxyBuilder.addEventListener( IOErrorEvent.VERIFY_ERROR, failure );
			}

			entityProxyBuilder.manageEntities();
			initialized = true;
		}
		
		public static function createEntity( clazz:Class, args:Array = null ):* {
			if ( !entityProxyBuilder ) {
				return null;
			}

			return entityProxyBuilder.createEntity( clazz, args );
		}
		
		public static function getEntityClass( clazz:Class ):Class {
			if ( !entityProxyBuilder ) {
				return null;
			}

			return entityProxyBuilder.getEntityClass( clazz );	
		}	
	}
}