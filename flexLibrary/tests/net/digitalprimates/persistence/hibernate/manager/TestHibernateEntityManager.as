package net.digitalprimates.persistence.hibernate.manager {
	import mockolate.mock;
	import mockolate.runner.MockolateRule;
	import mockolate.stub;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.remoting.RemoteObject;
	
	import net.digitalprimates.persistence.entity.IEntity;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.loader.stub.SampleEntity;
	import net.digitalprimates.persistence.hibernate.manager.stub.DemoRemoteObject;
	
	import org.flexunit.asserts.assertEquals;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.asserts.assertNotNull;
	import org.flexunit.asserts.assertNull;
	import org.flexunit.asserts.assertStrictlyEquals;
	import org.flexunit.asserts.assertTrue;

	public class TestHibernateEntityManager {

		[Rule]
		public var mockolate:MockolateRule = new MockolateRule();
		
		//This is a demo remote object as there seems to be an issue mocking dynamic classes
		[Mock]
		public var remoteObject:DemoRemoteObject;

		[Mock]
		public var hibernateEntity:IHibernateManagedEntity;

		[Mock]
		public var entity:IEntity;

		private var manager:HibernateEntityManager;
		
		[Before]
		public function setup():void {
			manager = new HibernateEntityManager( remoteObject );
		}

		[After]
		public function tearDown():void {
			manager = null;
		}

		[Test]
		public function shouldStoreRemoteObject():void {
			assertStrictlyEquals( remoteObject, manager.remoteObject );
		}

		[Test]
		public function shouldSetConvertResultHandler():void {
			//TODO: revise this one I refactory the entityManager
			//convertParametersHandler is a bloody public var of type function so no mocking it 
			var ro:RemoteObject = new RemoteObject();
			var em:HibernateEntityManager = new HibernateEntityManager( ro );
			
			assertNotNull( ro.convertResultHandler );
		}

		[Test]
		public function shouldClearEntities():void {
			manager.manage( hibernateEntity );
			manager.clear();
			assertFalse( manager.contains( hibernateEntity ) );
		}

		[Test]
		public function shouldFindContainedEntity():void {
			assertFalse( manager.contains( hibernateEntity ) );
			manager.manage( hibernateEntity );
			assertTrue( manager.contains( hibernateEntity ) );
		}

		[Ignore("Wait until this is no longer hardcoded to do something useful")]
		[Test]
		public function shouldCallServerLoadMethodFromFind():void {
		}

		[Test("Need revision once find is no long hardcoded")]
		public function shouldReturnTokenFromFind():void {
			var token:AsyncToken = new AsyncToken();
			mock( remoteObject ).method( "getLotsByAuctionId_bidder" ).anyArgs().returns( token ).once();
			
			assertStrictlyEquals( token, manager.find( String, "123" ) );
		}

		[Test]
		public function shouldManageIHibernateEntityFromPersist():void {
			mock( hibernateEntity ).setter( "manager" ).arg( manager ).once();
			manager.persist( hibernateEntity );
		}

		[Test(expected="TypeError")]
		public function shouldFailToManageIEntityFromPersist():void {
			manager.persist( entity );
		}

		[Test]
		public function shouldSetupManagement():void {
			mock( hibernateEntity ).setter( "manager" ).arg( manager ).once();
			manager.manage( hibernateEntity );
			
			assertTrue( manager.contains( hibernateEntity ) );
		}

		[Test]
		public function shouldCleanupManagement():void {
			mock( hibernateEntity ).setter( "manager" ).arg( manager ).once();
			mock( hibernateEntity ).setter( "manager" ).arg( null ).once();

			manager.manage( hibernateEntity );
			manager.unmanage( hibernateEntity );

			assertFalse( manager.contains( hibernateEntity ) );
		}

		[Test]
		public function shouldReturnTokenFromRefresh():void {
			var token:AsyncToken = new AsyncToken();
			stub( remoteObject ).method( "loadDPProxy" ).returns( token );
			
			assertEquals( token, manager.refresh( hibernateEntity ) );
		}

		[Test]
		public function shouldRefreshIHibernateEntity():void {
			stub( hibernateEntity ).getter( "proxyKey" ).returns( "12345" );
			mock( remoteObject ).method( "loadDPProxy" ).args( "12345", hibernateEntity ).once();
			
			manager.refresh( hibernateEntity );
		}

		[Test(expected="TypeError")]
		public function shouldFailToRefreshIEntity():void {
			manager.refresh( entity );
		}

		[Ignore("Not yet implemented")]
		[Test]
		public function propogateEvent():void {
			
		}

		[Ignore("Not yet implemented")]
		[Test]
		public function remove():void {
			
		}

		[Ignore("Not yet implemented")]
		[Test]
		public function getTypeInfoForProxiedClass():void {
			
		}
		
		
	}
}