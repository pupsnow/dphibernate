package net.digitalprimates.persistence.hibernate.rpc {
	import mockolate.ingredients.MockingCouverture;
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.stub;
	
	import mx.collections.ArrayCollection;
	import mx.events.PropertyChangeEvent;
	
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoader;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoaderFactory;
	import net.digitalprimates.persistence.hibernate.loader.stub.SampleDispatchingEntity;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	import org.as3commons.bytecode.abc.enum.NamespaceKind;
	import org.as3commons.bytecode.reflect.ByteCodeAccessor;
	import org.as3commons.bytecode.reflect.ByteCodeType;
	import org.flexunit.asserts.assertEquals;
	import org.hamcrest.core.isA;
	
	public class TestHibernateResultHandlerImpl {
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock]
		public var manager:IHibernateEntityManager;	
		
		[Mock]
		public var entity1:SampleDispatchingEntity;

		[Mock]
		public var entity2:SampleDispatchingEntity;
		
		[Mock]
		public var type:ByteCodeType;
		
		[Mock]
		public var field:ByteCodeAccessor;
		
		private const propertyName:String = "testABC";
		private const propertyValue:String = "ABC123";		
		
		var c:MockingCouverture;
		
		[Test]
		public function shouldReturnResult():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			var result:* = handler.resultConversionFunction( "Hello", null );
			
			assertEquals( "Hello", result );
		}
		
		[Test]
		public function shouldRegisterEntityWithManager():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( entity1 ).getter( "proxyInitialized" ).returns( false );
			mock( manager ).method( "manage" ).args( entity1 ).once();
			
			handler.resultConversionFunction( entity1, null );
		}
		
		[Test]
		public function shouldSkipNonVisibleField():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).returns( type );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PROTECTED_NAMESPACE );
			stub( type ).getter( "properties" ).returns( [ field ] );
			
			mock( field ).method( "getValue" ).never();
			
			handler.resultConversionFunction( entity1, null );
		}		
		
		[Test]
		public function shouldGetValueFromVisibleField():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).returns( type );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			stub( type ).getter( "properties" ).returns( [ field ] );
			
			mock( field ).method( "getValue" ).returns( "Hello" ).once();
			
			handler.resultConversionFunction( entity1, null );
		}

		[Test]
		public function shouldManageNestedEntity():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity2 ).returns( null );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );

			stub( type ).getter( "properties" ).returns( [ field ] );
			stub( field ).method( "getValue" ).returns( entity2 );
			
			mock( manager ).method( "manage" ).args( entity2 ).once();

			handler.resultConversionFunction( entity1, null );
		}

		[Test]
		public function shouldAddEventListenerToEntityWithParent():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity2 ).returns( null );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			
			stub( type ).getter( "properties" ).returns( [ field ] );
			stub( field ).method( "getValue" ).returns( entity2 );
			
			
			mock( entity2 ).method( "addEventListener" ).args( PropertyChangeEvent.PROPERTY_CHANGE, isA( Function )  ).once();
			
			handler.resultConversionFunction( entity1, null );
		}
		
		[Test]
		public function shouldManageEntityInNestedArray():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity2 ).returns( null );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			
			stub( type ).getter( "properties" ).returns( [ field ] );
			
			stub( field ).method( "getValue" ).returns( [ entity2 ] );
			
			mock( manager ).method( "manage" ).args( entity2 ).once();
			
			handler.resultConversionFunction( entity1, null );
		}		

		[Test]
		public function shouldManageEntityInNestedICollectionView():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity2 ).returns( null );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			stub( field ).method( "getValue" ).returns( new ArrayCollection( [ entity2 ] ) );
			stub( type ).getter( "properties" ).returns( [ field ] );
			
			mock( manager ).method( "manage" ).args( entity2 ).once();
			
			handler.resultConversionFunction( entity1, null );
		}		
		
		[Test]
		public function shouldManageEntityInArray():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );

			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			
			stub( type ).getter( "properties" ).returns( [ field ] );
			stub( field ).method( "getValue" ).returns( [ entity2 ] );
			
			mock( manager ).method( "manage" ).args( entity2 ).once();
			
			handler.resultConversionFunction( entity1, null );
		}
		
		[Test]
		public function shouldManageEntityInICollectionView():void {
			var handler:HibernateResultHandlerImpl = new HibernateResultHandlerImpl( manager );
			
			stub( manager ).method( "getTypeInfoForProxiedClass" ).args( entity1 ).returns( type );
			stub( entity1 ).getter( "proxyInitialized" ).returns( true );
			stub( entity2 ).getter( "proxyInitialized" ).returns( false );
			
			stub( field ).getter( "visibility" ).returns( NamespaceKind.PACKAGE_NAMESPACE );
			
			stub( type ).getter( "properties" ).returns( [ field ] );
			stub( field ).method( "getValue" ).returns( new ArrayCollection( [ entity2 ] ) );
			
			mock( manager ).method( "manage" ).args( entity2 ).once();
			
			handler.resultConversionFunction( entity1, null );
		}		
		
	}
}