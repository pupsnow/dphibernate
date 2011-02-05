package net.digitalprimates.persistence.hibernate.interceptor {
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.verify;
	
	import net.digitalprimates.persistence.entity.IEntityObjectManager;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	
	import org.as3commons.bytecode.interception.impl.InvocationKind;
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertNull;

	public class TestHibernateEntityInterceptor {
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock(type="strict")]
		public var objectManager:IEntityObjectManager;

		[Mock(type="strict")]
		public var targetEntity:IHibernateManagedEntity;

		[Test]
		public function shouldReturnArgWhenWithSimpleSet():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			var value:* = interceptor.intercept( targetEntity, InvocationKind.METHOD, name, [456] );
			
			assertNull( value );
		}
		
		[Test]
		public function shouldReturnNullWithMethodInvocation():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			var value:* = interceptor.intercept( targetEntity, InvocationKind.SETTER, name, [456] );
			
			assertEquals( 456, value );
		}		

		[Test]
		public function shouldReturnArgWhenWithNoTargetEntity():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			var value:* = interceptor.intercept( null, InvocationKind.GETTER, name, [456] );
			
			assertEquals( 456, value );
		}

		[Test]
		public function shouldReturnArgWhenProxyInitialized():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			mock( targetEntity ).getter( "proxyInitialized" ).returns( true );
			var value:* = interceptor.intercept( targetEntity, InvocationKind.GETTER, name, [456] );
			
			assertEquals( 456, value );
		}

		[Test]
		public function shouldReturnArgWhenPending():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			mock( targetEntity ).getter( "proxyInitialized" ).returns( false );
			mock( targetEntity ).getter( "comStatus" ).returns( HibernateConstants.PENDING );
			
			var value:* = interceptor.intercept( targetEntity, InvocationKind.GETTER, name, [456] );
			
			assertEquals( 456, value );
		}

		[Test]
		public function shouldReturnArgWhenSerializing():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			mock( targetEntity ).getter( "proxyInitialized" ).returns( false );
			mock( targetEntity ).getter( "comStatus" ).returns( HibernateConstants.SERIALIZING );
			
			var value:* = interceptor.intercept( targetEntity, InvocationKind.GETTER, name, [456] );
			
			assertEquals( 456, value );
		}

		[Test]
		public function shouldReturnNullWhenUninitialized():void {
			var interceptor:HibernateEntityInterceptor = new HibernateEntityInterceptor( objectManager );
			var name:QName = new QName( null, "testProp" );
			
			mock( targetEntity ).getter( "proxyInitialized" ).returns( false );
			mock( targetEntity ).getter( "comStatus" ).returns( 0 );
			
			mock( objectManager ).method( "getProperty" ).args( targetEntity, name.localName ).once();
			
			var value:* = interceptor.intercept( targetEntity, InvocationKind.GETTER, name, [456] );
			
			assertNull( value );
		}
		
	}
}