package net.digitalprimates.persistence.entity.proxy {
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.registerClassAlias;
	
	import net.digitalprimates.persistence.hibernate.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.HibernateObjectManagerImpl;
	import net.digitalprimates.persistence.hibernate.IHibernateObjectManager;
	import net.digitalprimates.persistence.hibernate.interceptor.HibernateInterceptorFactory;
	import net.digitalprimates.persistence.hibernate.introduction.HibernateIntroduction;
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.introduction.IManagedEntity;
	
	import org.as3commons.bytecode.emit.IAbcBuilder;
	import org.as3commons.bytecode.emit.IClassBuilder;
	import org.as3commons.bytecode.proxy.IClassProxyInfo;
	import org.as3commons.bytecode.proxy.IProxyFactory;
	import org.as3commons.bytecode.proxy.event.ProxyFactoryBuildEvent;
	import org.as3commons.bytecode.proxy.impl.ProxyFactory;
	import org.as3commons.bytecode.proxy.impl.ProxyInfo;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.as3commons.reflect.Metadata;
	import org.as3commons.reflect.MetadataArgument;
	import org.as3commons.reflect.Type;

	[Event(name="complete", type="flash.events.Event")]
	[Event(name="verifyError", type="flash.events.IOErrorEvent")]
	public class EntityProxyBuilder extends EventDispatcher {
		private var loaderInfo:LoaderInfo;
		private var proxyFactory:IProxyFactory;

		private function initStructures():void {
			ByteCodeType.fromLoader(loaderInfo);
		}

		private function findEntityNames():Array {
			return ByteCodeType.getClassesWithMetadata(HibernateConstants.HIBERNATE_METADATA);
		}

		private function defineEntity(entityName:String, factory:IProxyFactory, objectManager:IHibernateObjectManager):void {
			var type:Type;
			var classProxyInfo:IClassProxyInfo;

			type = Type.forName(entityName);
			classProxyInfo = factory.defineProxy(type.clazz);
			classProxyInfo.introduce(HibernateIntroduction);
			classProxyInfo.interceptorFactory = new HibernateInterceptorFactory(objectManager);
		}

		private function registerProxyClassReplacements():void {
			var type:Type;
			var definitionNames:Array = findEntityNames();
			var proxyClass:Class;
			var alias:String;

			for (var i:int = 0; i < definitionNames.length; i++) {
				type = Type.forName(definitionNames[i]);
				trace("Registering " + type.name);

				proxyClass = getEntityClass(type.clazz);
				alias = getRemoteAlias(type);

				if (alias && proxyClass) {
					registerClassAlias(alias, proxyClass);
				}
			}
		}

		private function getRemoteAlias(type:Type):String {
			var ar:Array = type.getMetadata(HibernateConstants.REMOTE_CLASS);
			var remoteAlias:String;

			if (ar) {
				for (var j:int = 0; j < ar.length; j++) {
					var metadata:Metadata = ar[j] as Metadata;
					var argument:MetadataArgument = metadata.getArgument(HibernateConstants.ALIAS);
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
			var entity:IManagedEntity;
			var builder:IClassBuilder = event.classBuilder;
			builder.implementInterfaces( ["net.digitalprimates.persistence.hibernate.introduction.IManagedEntity"] );
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

		public function manageEntities():void {
			var definitionNames:Array;
			var hibernateImpl:IHibernateObjectManager;

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

		public function EntityProxyBuilder(loaderInfo:LoaderInfo) {
			this.loaderInfo = loaderInfo;
			proxyFactory = new ProxyFactory();
			proxyFactory.addEventListener( ProxyFactoryBuildEvent.AFTER_PROXY_BUILD, implementInterface );
		}
	}
}