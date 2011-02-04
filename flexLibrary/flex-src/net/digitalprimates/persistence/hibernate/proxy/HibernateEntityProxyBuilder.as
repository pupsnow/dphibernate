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
package net.digitalprimates.persistence.hibernate.proxy {
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.registerClassAlias;
	import flash.utils.Dictionary;
	
	import net.digitalprimates.persistence.entity.IEntityObjectManager;
	import net.digitalprimates.persistence.entity.interceptor.EntityInterceptorFactory;
	import net.digitalprimates.persistence.hibernate.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.interceptor.HibernateEntityInterceptor;
	import net.digitalprimates.persistence.hibernate.introduction.HibernateIntroduction;
	import net.digitalprimates.persistence.hibernate.manager.HibernateObjectManagerImpl;
	
	import org.as3commons.bytecode.emit.IAbcBuilder;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.proxy.IClassProxyInfo;
	import org.as3commons.bytecode.proxy.IProxyFactory;
	import org.as3commons.bytecode.proxy.ProxyScope;
	import org.as3commons.bytecode.proxy.event.ProxyFactoryBuildEvent;
	import org.as3commons.bytecode.proxy.impl.ProxyFactory;
	import org.as3commons.bytecode.proxy.impl.ProxyInfo;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.reflect.Metadata;
	import org.as3commons.reflect.MetadataArgument;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="verifyError", type="flash.events.IOErrorEvent")]
	public class HibernateEntityProxyBuilder extends EventDispatcher {
		private var loaderInfo:LoaderInfo;
		private var proxyFactory:IProxyFactory;
		private var mapping:Dictionary;

		private function initStructures():void {
			ByteCodeType.fromLoader( loaderInfo );
		}

		private function findEntityNames():Array {
			return ByteCodeType.getClassesWithMetadata(HibernateConstants.HIBERNATE_METADATA);
		}

		private function defineEntity(entityName:String, factory:IProxyFactory, objectManager:IEntityObjectManager):void {
			var type:ByteCodeType;
			var classProxyInfo:IClassProxyInfo;

			type = ByteCodeType.forName( entityName );
			classProxyInfo = factory.defineProxy( type.clazz );
			classProxyInfo.proxyAccessorScopes = ProxyScope.PUBLIC;
			classProxyInfo.proxyMethodScopes = ProxyScope.NONE;
			classProxyInfo.introduce(HibernateIntroduction);
			classProxyInfo.interceptorFactory = new EntityInterceptorFactory( HibernateEntityInterceptor, objectManager );
		}

		private function registerProxyClassReplacements():void {
			var type:ByteCodeType;
			var definitionNames:Array = findEntityNames();
			var proxyClass:Class;
			var alias:String;

			for (var i:int = 0; i < definitionNames.length; i++) {
				type = ByteCodeType.forName( definitionNames[i] );
				trace("Registering " + type.name);

				proxyClass = getEntityClass(type.clazz);
				alias = getRemoteAlias(type);
				
				mapping[ proxyClass ] = type.clazz;

				if (alias && proxyClass) {
					registerClassAlias(alias, proxyClass);
				}
			}
		}

		private function getRemoteAlias( type:ByteCodeType ):String {
			var ar:Array = type.getMetadata( HibernateConstants.REMOTE_CLASS );
			var remoteAlias:String;

			if (ar) {
				for (var j:int = 0; j < ar.length; j++) {
					var metadata:Metadata = ar[j] as Metadata;
					var argument:MetadataArgument = metadata.getArgument( HibernateConstants.ALIAS );
					if (argument) {
						remoteAlias = argument.value;
						break;
					}
				}
			}

			return remoteAlias;
		}

		private function implementInterface(event:ProxyFactoryBuildEvent):void {
			//just here for now for linking
			var builder:IClassBuilder = event.classBuilder;
			builder.implementInterfaces( ["net.digitalprimates.persistence.hibernate.introduction.IHibernateManagedEntity"] );
		}

		public function createEntity(clazz:Class, args:Array = null):* {
			return proxyFactory.createProxy(clazz, args);
		}

		public function getEntityClass(clazz:Class):Class {
			var proxyInfo:ProxyInfo = proxyFactory.getProxyInfoForClass(clazz);
			var proxyClass:Class;

			if (proxyInfo) {
				proxyClass = proxyInfo.proxyClass;
			}

			return proxyClass;
		}
		
		public function getProxiedClass( instance:* ):Class {
			var proxy:Class = instance.constructor;
			
			return mapping[ proxy ];
		}

		public function manageEntities():void {
			var definitionNames:Array;
			var hibernateImpl:IEntityObjectManager;

			initStructures();

			definitionNames = findEntityNames();
			hibernateImpl = new HibernateObjectManagerImpl();

			for (var i:int = 0; i < definitionNames.length; i++) {
				defineEntity(definitionNames[i], proxyFactory, hibernateImpl);
			}

			var abcBuilder:IAbcBuilder = proxyFactory.generateProxyClasses();
			proxyFactory.addEventListener(Event.COMPLETE, handleLoaded);
			proxyFactory.addEventListener(IOErrorEvent.VERIFY_ERROR, handleVerifyError);

			proxyFactory.loadProxyClasses();
		}

		private function handleLoaded(event:Event):void {
			registerProxyClassReplacements();
			dispatchEvent(event.clone());
		}

		private function handleVerifyError(event:IOErrorEvent):void {
			//something went terribly wrong during class generation...
			dispatchEvent(event.clone());
		}

		public function HibernateEntityProxyBuilder(loaderInfo:LoaderInfo) {
			this.loaderInfo = loaderInfo;
			proxyFactory = new ProxyFactory();
			proxyFactory.addEventListener( ProxyFactoryBuildEvent.AFTER_PROXY_BUILD, implementInterface );
			mapping = new Dictionary( true );
		}
	}
}