package net.digitalprimates.persistence.hibernate.manager {
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.stub;
	
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoader;
	import net.digitalprimates.persistence.hibernate.loader.ILazyLoaderFactory;
	import net.digitalprimates.persistence.hibernate.loader.LazyLoadEvent;
	import net.digitalprimates.persistence.hibernate.loader.stub.SampleDispatchingEntity;
	
	import org.hamcrest.core.allOf;
	import org.hamcrest.core.isA;
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.hasProperty;

	public class TestHibernateObjectManagerImpl {
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock]
		public var manager:IHibernateEntityManager;	

		[Mock]
		public var entity:SampleDispatchingEntity;

		[Mock]
		public var lazyLoaderFactory:ILazyLoaderFactory;

		[Mock]
		public var lazyLoader:ILazyLoader;
		
		private const propertyName:String = "testABC";

		[Test]
		public function shouldChangeComStatus():void {
			var objManager:HibernateObjectManagerImpl = new HibernateObjectManagerImpl( lazyLoaderFactory );
			
			stub( lazyLoaderFactory ).method( "newInstance" ).returns( lazyLoader );
			stub( entity ).getter( "comStatus" ).returns( 0 );
			
			mock( entity ).setter( "comStatus" ).arg( HibernateConstants.SERIALIZING ).once();
			mock( entity ).setter( "comStatus" ).arg( 0 ).once();
			
			objManager.getProperty( entity, propertyName );
		}
		
		[Test]
		public function shouldPassCorrectArgsToLazyLoader():void {
			var objManager:HibernateObjectManagerImpl = new HibernateObjectManagerImpl( lazyLoaderFactory );
			
			stub( entity ).getter( "manager" ).returns( manager );
			mock( lazyLoaderFactory ).method( "newInstance" ).args( manager, entity, propertyName ).returns( lazyLoader ).once();
			
			objManager.getProperty( entity, propertyName );
		}
		
		[Test]
		public function shouldInvokeLoadMethodOfLazyLoader():void {
			var objManager:HibernateObjectManagerImpl = new HibernateObjectManagerImpl( lazyLoaderFactory );
			
			stub( lazyLoaderFactory ).method( "newInstance" ).returns( lazyLoader );
			mock( lazyLoader ).method( "load" ).once();
			
			objManager.getProperty( entity, propertyName );
		}		
		
		[Test]
		public function shouldDispatchLazyLoadEvent():void {
			var objManager:HibernateObjectManagerImpl = new HibernateObjectManagerImpl( lazyLoaderFactory );
			
			stub( lazyLoaderFactory ).method( "newInstance" ).returns( lazyLoader );
			mock( entity ).method( "dispatchEvent" ).args( allOf( isA( LazyLoadEvent ), hasProperty( "type", equalTo( LazyLoadEvent.PENDING ) ) ) ).once();
 
			objManager.getProperty( entity, propertyName );
		}			
	}
}