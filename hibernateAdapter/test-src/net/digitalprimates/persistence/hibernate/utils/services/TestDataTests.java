package net.digitalprimates.persistence.hibernate.utils.services;

import static org.junit.Assert.*;

import org.hibernate.collection.AbstractPersistentCollection;
import org.junit.Test;

import net.digitalprimates.dphibernate.model.Publisher;
import net.digitalprimates.dphibernate.test.util.DbTestCase;

/**
 * Tests which simply validate that the DbTestCase is setting things 
 * up correctly, and that the entities are mapping correctly
 * @author Marty Pitt
 *
 */
public class TestDataTests extends DbTestCase
{

	@Test
	public void publisherContainsLists()
	{
		Publisher publisher = get(Publisher.class,1);
		assertNotNull(publisher.getAuthors());
		assertTrue(publisher.getAuthors() instanceof AbstractPersistentCollection);
		AbstractPersistentCollection authors = (AbstractPersistentCollection) publisher.getAuthors();
		assertFalse(authors.wasInitialized());
	}
}
