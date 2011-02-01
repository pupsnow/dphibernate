package net.digitalprimates.persistence.entity.interceptor {
	
	import net.digitalprimates.persistence.hibernate.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.IHibernateObjectManager;
	
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptor;
	import org.as3commons.bytecode.interception.impl.InvocationKind;
	
	public class EntityInterceptor implements IMethodInvocationInterceptor {
		private var objectManager:IHibernateObjectManager;

		public function EntityInterceptor( objectManager:IHibernateObjectManager ) {
			this.objectManager = objectManager;
		}
		
		final public function intercept(targetInstance:Object, kind:org.as3commons.bytecode.interception.impl.InvocationKind, member:QName, arguments:Array=null, method:Function=null):* {
			switch (kind) {
				case InvocationKind.CONSTRUCTOR:
					break;
				case InvocationKind.METHOD:
					return method.apply(targetInstance, arguments);
					break;
				case InvocationKind.GETTER:
					if ( ( targetInstance.proxyInitialized ) || 
						 ( targetInstance.comStatus & HibernateConstants.PENDING ) || 
						 ( targetInstance.comStatus & HibernateConstants.SERIALIZING ) ) {
						return arguments[0];						
					} else {						
						objectManager.getProperty( targetInstance, member.localName );
						return null;
					}
					
					break;
				case InvocationKind.SETTER:
					//targetInstance[ member.localName ] = arguments[0];
					return arguments[0];
					break;
				default:
					break;
			}

		}
	}
}