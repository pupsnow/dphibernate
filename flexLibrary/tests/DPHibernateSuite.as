package  {
	import net.digitalprimates.persistence.entity.interceptor.TestEntityInterceptorFactory;
	import net.digitalprimates.persistence.hibernate.interceptor.TestHibernateEntityInterceptor;
	import net.digitalprimates.persistence.hibernate.loader.TestLazyLoader;
	import net.digitalprimates.persistence.hibernate.loader.TestLazyLoaderResult;
	import net.digitalprimates.persistence.hibernate.manager.TestHibernateEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.TestHibernateObjectManagerImpl;
	import net.digitalprimates.persistence.hibernate.rpc.TestHibernateResultHandlerImpl;

	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class DPHibernateSuite {
		public var test1:TestEntityInterceptorFactory;
		public var test2:TestHibernateEntityInterceptor;
		public var test3:TestLazyLoader;
		public var test4:TestLazyLoaderResult;
		public var test5:TestHibernateObjectManagerImpl;
		public var test6:TestHibernateResultHandlerImpl;
		public var test7:TestHibernateEntityManager;
	}
}