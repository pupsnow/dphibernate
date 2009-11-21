package net.digitalprimates.persistence.state
{
	import flexunit.framework.Assert;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.state.testObjects.Author;
	import net.digitalprimates.persistence.state.testObjects.Book;

	public class HibernateUpdaterTests
	{
		public function HibernateUpdaterTests()
		{
		}
		private var mockService:MockHibernateRPC;
		private var changeMessageGenerator:ChangeMessageGenerator;
		[Before]
		public function setUp():void
		{
			StateRepository.reset();
			mockService=new MockHibernateRPC();
			changeMessageGenerator = new ChangeMessageGenerator();
		}

		[Test]
		public function hasChangesFalseAfterUpdate():void
		{
			var author:Author=StateRepositoryTests.getTestAuthor(mockService);
			var returnToken:AsyncToken=new AsyncToken(null);
			mockService.expects("saveProxy").withAnyArgs().willReturn(returnToken);

			StateRepository.store(author);
			author.name="Sondehim";
			Assert.assertTrue(changeMessageGenerator.hasChanges(author));
			var token:AsyncToken=author.save(); // Should be same as returnToken

			HibernateUpdater.saveCompleted(ResultEvent.createEvent(null, token));
			Assert.assertFalse(changeMessageGenerator.hasChanges(author));
		}

		[Test]
		public function givenUpdatingNewObjectCompletedThatNewIdIsSetOnObject():void
		{
			var author:Author=StateRepositoryTests.getTestAuthor(mockService);
			StateRepository.store(author);
			var book:Book=StateRepositoryTests.getBook(4, "Getting Real", author);
			author.books.addItem(book);
			
			var bookChanges : ObjectChangeMessage =  changeMessageGenerator.getChangesForEntityOnly( book );
			Assert.assertTrue( bookChanges.isNew );
			Assert.assertTrue( bookChanges.hasChanges );
			
			var returnToken:AsyncToken=new AsyncToken(null);
			mockService.expects("saveProxy").withAnyArgs().willReturn(returnToken);
			
			author.save();
			
			// Update result returned from server:
			var updateResult : ObjectChangeResult = ObjectChangeResult.create( Book , 4 , 2 );
			
			HibernateUpdater.saveCompleted( ResultEvent.createEvent( new ArrayCollection([ updateResult ]) , returnToken ) );
			
			bookChanges = changeMessageGenerator.getChangesForEntityOnly( book );
			Assert.assertFalse( bookChanges.isNew );
			Assert.assertFalse( bookChanges.hasChanges );
			
			Assert.assertEquals( 2 , book.proxyKey );
		}

		[Test]
		public function givenChangesMadeToAnObjectWhileUpdateInProgressThatChangesAreAppliedAfterUpdateCompletes():void
		{
			var author:Author=StateRepositoryTests.getTestAuthor(mockService);
			StateRepository.store(author);
			author.name = "Schwartz";
			author.publisher.name = "Manning";
				
			var returnToken:AsyncToken=new AsyncToken(null);
			mockService.expects("saveProxy").withAnyArgs().willReturn(returnToken);
			
			author.save();
			
//			Assert.assertTrue( StateRepository.hasPendingSave( author ) );
//			Assert.assertTrue( StateRepository.hasPendingSave( author.publisher ) );
			// Save is in progress.  Any changes should be queued
			author.age = 23;
			author.name = "Sondheim";
			
			HibernateUpdater.saveCompleted(ResultEvent.createEvent(null, returnToken));
			
			var authorChanges : ObjectChangeMessage = changeMessageGenerator.getChangesForEntityOnly( author );
			Assert.assertTrue( authorChanges.hasChanges );
			Assert.assertTrue( authorChanges.hasChangedProperty( "age" ) );
			Assert.assertTrue( authorChanges.hasChangedProperty( "name" ) );
		}
		
		[Test]
		public function afterSuccessfulCreationSubsequentUpdatesSentWithCorrectKey() : void
		{
			var author:Author=StateRepositoryTests.getTestAuthor(mockService);
			StateRepository.store(author);
			var oldId : int = 4;
			var newId : int = 100;
			var book:Book=StateRepositoryTests.getBook(oldId, "Getting Real", author);
			author.books.addItem(book);
			
			var returnToken:AsyncToken=new AsyncToken(null);
			mockService.expects("saveProxy").withAnyArgs().willReturn(returnToken);
			
			author.save();
			
			// Update result returned from server:
			var updateResult : ObjectChangeResult = ObjectChangeResult.create( Book , oldId , newId );
			
			HibernateUpdater.saveCompleted( ResultEvent.createEvent( new ArrayCollection([ updateResult ]) , returnToken ) );
			
			book.title = "Getting a little bit more real";
			
			var bookChanges : ObjectChangeMessage = changeMessageGenerator.getChangesForEntityOnly( book );
			Assert.assertNotNull( bookChanges );
			Assert.assertEquals( newId , bookChanges.owner.proxyId );
		}
		
		
	}
}