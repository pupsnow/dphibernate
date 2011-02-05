package net.digitalprimates.persistence.entity.interceptor.stub {
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptor;
	import org.as3commons.bytecode.interception.impl.InvocationKind;
	
	public class StubInterceptor implements IMethodInvocationInterceptor {
		public var objectManager:*;
		public var targetInstance:Object;
		public var kind:InvocationKind;
		public var member:QName;
		public var arguments:Array;
		public var method:Function;

		public function StubInterceptor( objectManager:* ) {
			this.objectManager = objectManager;
		}
		
		final public function intercept(targetInstance:Object, kind:InvocationKind, member:QName, arguments:Array=null, method:Function=null):* {
			this.targetInstance = targetInstance;
			this.kind = kind;
			this.member = member;
			this.arguments = arguments;
			this.method = method;
			
			return null;
		}
	}
}