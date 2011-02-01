package net.digitalprimates.persistence.hibernate.interceptor
{
	import net.digitalprimates.persistence.hibernate.IHibernateObjectManager;
	
	import org.as3commons.bytecode.interception.IMethodInvocationInterceptorFactory;
	import net.digitalprimates.persistence.entity.interceptor.EntityInterceptor;
	
	public class HibernateInterceptorFactory implements IMethodInvocationInterceptorFactory
	{
		private var objectManager:IHibernateObjectManager;
		public function HibernateInterceptorFactory( objectManager:IHibernateObjectManager ) {
			this.objectManager = objectManager;
		}
		
		public function newInstance():*
		{
			var theInterceptor:EntityInterceptor = new EntityInterceptor( objectManager );
			return theInterceptor;
		}
	}
}