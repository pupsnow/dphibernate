package net.digitalprimates.persistence.hibernate.utils.services;

import static org.junit.Assert.*;

import java.io.Serializable;
import java.util.Collection;
import java.util.Map;

import org.junit.Test;

public class ProxyBatchLoaderTests
{

	@Test
	public void testConvertingRequestsToMapByClass()
	{
		ProxyBatchLoader loader = new ProxyBatchLoader(null);
		ProxyLoadRequest[] requests = {new ProxyLoadRequest("classA", 1),new ProxyLoadRequest("classA", 2),new ProxyLoadRequest("classB", 1)}; 
		Map<String, Collection<Serializable>> requestsByClass = loader.getRequestsByClass(requests);
		assertEquals(2,requestsByClass.keySet().size());
		assertEquals(2,requestsByClass.get("classA").size());
		assertEquals(1,requestsByClass.get("classB").size());
	}
}
