package net.digitalprimates.persistence.entity.interceptor {
	import mockolate.runner.MockolateRule;
	
	import net.digitalprimates.persistence.entity.IEntityObjectManager;
	import net.digitalprimates.persistence.entity.interceptor.stub.StubInterceptor;
	
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptor;
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptorFactory;
	import org.flexunit.asserts.assertStrictlyEquals;
	import org.hamcrest.assertThat;
	import org.hamcrest.core.isA;

	public class TestEntityInterceptorFactory {
		
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock]
		public var objectManager:IEntityObjectManager;
		
		[Test]
		public function shouldCreateProvidedInterceptorClass():void {
			var factory:IMethodInvocationInterceptorFactory = new EntityInterceptorFactory( StubInterceptor,  objectManager );
			var interceptor:IMethodInvocationInterceptor = factory.newInstance();
			assertThat( interceptor, isA( IMethodInvocationInterceptor ) );
			assertThat( interceptor, isA( StubInterceptor ) );
		}

		[Test]
		public function shouldPassObjectManagerToInterceptor():void {
			var factory:IMethodInvocationInterceptorFactory = new EntityInterceptorFactory( StubInterceptor,  objectManager );
			var interceptor:StubInterceptor = factory.newInstance();
			assertStrictlyEquals( objectManager, interceptor.objectManager ); 
		}
	}
}