package net.digitalprimates.persistence.translators.hibernate;

import static org.junit.Assert.*;

import java.util.List;

import net.digitalprimates.dphibernate.model.Author;

import org.junit.Before;
import org.junit.Test;

import flex.messaging.io.amf.ASObject;

/**
 * The 'normal' situation is that we'd be serializing
 * an object from Hibernate, so generally properties on the object
 * which are entities, and collections, would be hibernate proxies, waiting
 * to be lazy-loaded from the db.
 * 
 * In some cases however, we have a fully populated object graph.  We want to
 * ensure that in these cases, we're serializing with the same efficiency as
 * if there were hibernate proxies present.
 */
public class HibernateSerializerTestsOnObjectsThatDontHaveHibernateProxies
{

	HibernateSerializer serializer;
	@Before
	public void setup()
	{
		
	}

	@Test
	public void whenSerializingCollectionsAreProxied()
	{
		HibernateSerializer serializer = getSerializerForAuthor();
		ASObject result = (ASObject) serializer.serialize();
		assertASObjectIsNotProxy(result);
		List<ASObject> books = getCollection(result, "books"); 
		assertNotNull(books);
		assertIsCollectionOfProxies(books);
	}
	@Test
	public void whenSerializingChildPropertiesAreProxied()
	{
		HibernateSerializer serializer = getSerializerForAuthor();
		ASObject result = (ASObject) serializer.serialize();
		assertASObjectIsNotProxy(result);
		ASObject publisher = getProperty(result, "publisher");
		assertASObjectIsProxy(publisher);
	}
	private List<ASObject> getCollection(ASObject source, String property)
	{
		return (List<ASObject>) source.get(property);
	}
	private ASObject getProperty(ASObject source,String property)
	{
		return (ASObject) source.get(property);
	}
	private void assertIsCollectionOfProxies(List<ASObject> objects)
	{
		for (ASObject asObject : objects)
		{
			assertASObjectIsProxy(asObject);
		}
	}

	private void assertASObjectIsNotProxy(ASObject result)
	{
		Object proxyInit = result.get("proxyInitialized");
		assertNotNull(proxyInit);
		assertTrue((Boolean)proxyInit);
	}
	private void assertASObjectIsProxy(ASObject result)
	{
		Object proxyInit = result.get("proxyInitialized");
		// In some cases, the proxyInitialized value isn't set on the ASOjbect, as it arrives as false by default on the client
		if (proxyInit == null) return;
		assertFalse((Boolean)proxyInit);
	}
	private void assertIsObjectFor(ASObject object,Class<?> objectType)
	{
		assertEquals(objectType.getName(),object.getType());
	}
	private HibernateSerializer getSerializerForAuthor()
	{
		Author author = TestDataProvider.getAuthor();
		serializer = new HibernateSerializer(author);
		serializer.setCache(new DPHibernateCache());
		return serializer;
	}
}
