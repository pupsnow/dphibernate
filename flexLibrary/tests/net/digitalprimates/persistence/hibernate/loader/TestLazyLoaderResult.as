package net.digitalprimates.persistence.hibernate.loader {
	import flash.events.Event;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	
	import mockolate.ingredients.MockingCouverture;
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.stub;
	
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.loader.stub.SampleDispatchingEntity;
	import net.digitalprimates.persistence.hibernate.loader.stub.SampleEntity;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeAccessor;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.hasProperty;

	public class TestLazyLoaderResult {
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock]
		public var manager:IHibernateEntityManager;

		[Mock]
		public var entity:SampleEntity;

		[Mock]
		public var entity2:SampleDispatchingEntity;
		
		[Mock]
		public var token:AsyncToken;
		
		[Mock]
		public var type:ByteCodeType;		
		
		[Mock]
		public var field:ByteCodeAccessor;
		
		private const propertyName:String = "testABC";
		private const propertyValue:String = "ABC123";
		
		[Test]
		public function shouldClearPendingStatusOnResult():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			stub( entity ).getter( "comStatus" ).returns( HibernateConstants.PENDING | HibernateConstants.SERIALIZING );
			mock( entity ).setter( "comStatus" ).arg( HibernateConstants.SERIALIZING ).once();
			
			loader.result( resultEvent );
		}

		[Test]
		public function shouldUnManageResultObjectOnResult():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			mock( manager ).method( "unmanage" ).args( entity2 ).once();
			
			loader.result( resultEvent );			
		}

		[Test]
		public function shouldCopyPublicPropertiesToEntity():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			stub( field ).getter( "name" ).returns( propertyName );
			stub( entity2 ).getter( propertyName ).returns( propertyValue );
			stub( type ).getter( "properties" ).returns( [ field ] );

			mock( entity ).setter( propertyName ).arg( propertyValue ).once();
			
			loader.result( resultEvent );
		}
		
		[Test]
		public function shouldNotAttemptToCopyNonVisiblePropertiesToEntity():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PROTECTED_NAMESPACE );
			stub( field ).getter( "name" ).returns( propertyName );
			stub( entity2 ).getter( propertyName ).returns( propertyValue );
			stub( type ).getter( "properties" ).returns( [ field ] );
			
			mock( entity ).setter( propertyName ).never();
			
			loader.result( resultEvent );
		}		

		[Test]
		public function shouldCopyProxyInitiailizedToEntity():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			stub( entity2 ).getter( "proxyInitialized" ).returns( true );
			mock( entity ).setter( "proxyInitialized" ).arg( true ).once();
			
			loader.result( resultEvent );				
		}

		[Test]
		public function shouldNotCopyProxyKeyToEntity():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			stub( entity2 ).getter( "proxyKey" ).returns( "ABCDEFG" );
			mock( entity ).setter( "proxyKey" ).never();
			
			loader.result( resultEvent );				
		}

		[Test]
		public function shouldNotCopyComStatusToEntity():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			stub( entity2 ).getter( "comStatus" ).returns( HibernateConstants.SERIALIZING );
			mock( entity ).setter( "comStatus" ).never();
			
			loader.result( resultEvent );
		}

		[Test]
		public function shouldDispatchPropertyChangeIfEntityIsDispatcher():void {
			var loader:LazyLoader = new LazyLoader( manager, entity2, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			mock( entity2 ).method( "dispatchEvent" ).args( hasProperty( "type", equalTo( PropertyChangeEvent.PROPERTY_CHANGE ) ) ).once();
			loader.result( resultEvent );	
		}

		[Test]
		public function shouldNotDispatchPropertyChangeIfEntityNotDispatcher():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, type );
			var resultEvent:ResultEvent = new ResultEvent( ResultEvent.RESULT, false, true, entity2, token );
			
			stub( type ).getter( "properties" ).returns( [] );
			mock( entity ).method( "dispatchEvent" ).args( hasProperty( "type", equalTo( PropertyChangeEvent.PROPERTY_CHANGE ) ) ).never();
			loader.result( resultEvent );
		}
	}
}