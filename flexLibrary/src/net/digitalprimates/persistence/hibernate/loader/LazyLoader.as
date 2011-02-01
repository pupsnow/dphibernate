package net.digitalprimates.persistence.hibernate.loader
{
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.remoting.RemoteObject;
	
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;
	
	import org.as3commons.reflect.Field;
	import org.as3commons.reflect.Type;
	
	public class LazyLoader implements IResponder {
		private var manager:HibernateEntityManager;
		private var obj:*;
		private var parent:*;
		private var property:String;
		private var parentProperty:String;
		public function LazyLoader( manager:HibernateEntityManager, obj:*, property:String ) {
			this.manager = manager;
			this.obj = obj;
			this.property = property;
			this.parent = parent;
			this.parentProperty = parentProperty;
		}
		
		public function load():void {
			var token:AsyncToken = manager.incremenetalLoad( obj );
			token.addResponder( this );
		}
		
		public function result(data:Object):void {
			var type:Type = Type.forInstance( obj );
			var field:Field;
			var resultObj:* = data.result;
			
			//Can be made much more efficient, we should actually use the proxied class so we don't check our own introductins
			//and need to avoid things like prototype
			var properties:Array = type.properties;
			
			for ( var i:int=0; i<properties.length; i++ ) {
				field = properties[ i ] as Field;
				
				//Bad but just don't know how to check what is private or public right now
				if ( ( field.name != 'prototype' ) && ( field.name != 'methodInvocationInterceptor' ) ) {
					obj[ field.name ] = resultObj[ field.name ];
				}
				//eventually handle arrays and generic objects (hashmaps)
			}
		}
		
		public function fault(info:Object):void
		{
		}
	}
}