package net.digitalprimates.persistence.hibernate.loader {
	import flash.events.Event;
	
	import mockolate.ingredients.MockingCouverture;
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.stub;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.constants.HibernateConstants;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	import org.hamcrest.object.equalTo;
	import org.hamcrest.object.hasProperty;

	public class TestLazyLoader {
		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		[Mock]
		public var manager:IHibernateEntityManager;

		[Mock]
		public var entity:IHibernateManagedEntity;

		[Mock]
		public var token:AsyncToken;
		
		private const propertyName:String = "testABC";
		
		[Test]
		public function shouldSetEntityStatusToPending():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			
			stub( manager ).method( "incremenetalLoad" ).args( entity ).returns( token );
			stub( entity ).getter( "comStatus" ).returns( 0 );
			mock( entity ).setter( "comStatus" ).arg( HibernateConstants.PENDING ).once(); 
			
			loader.load();
		}

		[Test]
		public function shouldCallIncremenetalLoad():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			
			mock( manager ).method( "incremenetalLoad" ).args( entity ).returns( token ).once();
			
			loader.load();
		}

		[Test]
		public function shouldAddResponderToToken():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			
			stub( manager ).method( "incremenetalLoad" ).args( entity ).returns( token );
			mock( token ).method( "addResponder" ).args( loader ).once();
			
			loader.load();
		}

		[Test]
		public function shouldClearPendingStatusOnFault():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			
			stub( entity ).getter( "comStatus" ).returns( HibernateConstants.PENDING );
			mock( entity ).setter( "comStatus" ).arg( 0 ).once();
			
			loader.fault( new Event( "test" ) );
		}

		[Test]
		public function shouldClearPendingStatusAndPreserveOnFault():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			
			stub( entity ).getter( "comStatus" ).returns( HibernateConstants.PENDING | HibernateConstants.SERIALIZING );
			mock( entity ).setter( "comStatus" ).arg( HibernateConstants.SERIALIZING ).once();
			
			loader.fault( new Event( "test" ) );
		}
		
		[Test]
		public function shouldDispatchFaultOnManagerOnFault():void {
			var loader:LazyLoader = new LazyLoader( manager, entity, propertyName, null );
			var event:Event = new Event( "testMe123" );
			
			mock( manager ).method( "dispatchEvent" ).args( hasProperty( "type", equalTo( event.type ) ) ).once();
			
			loader.fault( event );			
		}
	}
}