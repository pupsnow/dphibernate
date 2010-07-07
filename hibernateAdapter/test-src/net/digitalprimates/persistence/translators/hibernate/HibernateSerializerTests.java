package net.digitalprimates.persistence.translators.hibernate;

import static org.junit.Assert.*;

import net.digitalprimates.dphibernate.model.Author;

import org.junit.Test;

public class HibernateSerializerTests
{

	@Test
	public void testIsPropertyOnSource()
	{
		Author author = TestDataProvider.getAuthor();
		HibernateSerializer serializer = new HibernateSerializer(author); 
		assertFalse(serializer.sourceContainsProperty(author.getAge()));
		assertTrue(serializer.sourceContainsProperty(author.getBooks()));
		assertTrue(serializer.sourceContainsProperty(author.getName()));
		assertTrue(serializer.sourceContainsProperty(author.getPublisher()));
		
		assertFalse(serializer.sourceContainsProperty(author.getBook(0).getTitle()));
		assertFalse(serializer.sourceContainsProperty(TestDataProvider.getAuthor()));
	}
}
