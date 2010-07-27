package net.digitalprimates.persistence.translators.hibernate;

import static org.junit.Assert.assertEquals;

import java.util.Arrays;
import java.util.List;

import net.digitalprimates.persistence.hibernate.HibernateAdapter;
import net.digitalprimates.persistence.hibernate.LoadDPProxyOperation;
import net.digitalprimates.persistence.hibernate.SaveDPProxyOperation;

import org.junit.Before;
import org.junit.Test;

import flex.messaging.config.ConfigMap;

public class HibernateAdapterTests
{

	HibernateAdapter adapter;
	@Before
	public void setup()
	{
		adapter = new HibernateAdapter();
	}
	@Test
	public void testConfigLoadSaveMethodNamesOnAdapterOnly()
	{
		// Setup config
		ConfigMap adapterConfig = new ConfigMap();
		ConfigMap dpHibnerateAdapterConfigMap = getConfigMap(
				setting("serializerFactory", MockSerializerFactory.class.getCanonicalName()),
				setting("loadMethod", "myLoadMethod"),
				setting("saveMethod", "mySaveMethod"));
		adapterConfig.addProperty("dpHibernate", dpHibnerateAdapterConfigMap);
		adapter.initialize("adapter", adapterConfig);
		
		// Assert config
		assertEquals("myLoadMethod",adapter.getOperation(LoadDPProxyOperation.class).getLoadMethodName());
		assertEquals("mySaveMethod",adapter.getOperation(SaveDPProxyOperation.class).getSaveMethodName());
	}
	
	@Test
	public void testConfigLoadSaveMethodNamesOnAdapterAndDestination()
	{
		// Setup config
		ConfigMap adapterConfig = new ConfigMap();
		ConfigMap dpHibnerateAdapterConfigMap = getConfigMap(
				setting("serializerFactory", MockSerializerFactory.class.getCanonicalName()),
				setting("loadMethod", "myLoadMethod"),
				setting("saveMethod", "mySaveMethod"));
		adapterConfig.addProperty("dpHibernate", dpHibnerateAdapterConfigMap);
		// Note that initialize is called up to 3 times, in order: Service settings, Adapter settings, Destination settings
		adapter.initialize("adapter", adapterConfig);

		ConfigMap destinationConfig = new ConfigMap();
		dpHibnerateAdapterConfigMap = getConfigMap(
				setting("loadMethod", "myDestinationLoadMethod"));
		destinationConfig.addProperty("dpHibernate", dpHibnerateAdapterConfigMap);
		// Note that initialize is called up to 3 times, in order: Service settings, Adapter settings, Destination settings
		adapter.initialize("adapter", destinationConfig);
		
		
		// Assert config
		assertEquals("myDestinationLoadMethod",adapter.getOperation(LoadDPProxyOperation.class).getLoadMethodName());
		assertEquals("mySaveMethod",adapter.getOperation(SaveDPProxyOperation.class).getSaveMethodName());
	}
	ConfigMap getConfigMap(KeyValuePair... settings)
	{
		ConfigMap configMap = new ConfigMap();
		for (KeyValuePair keyValuePair:settings)
		{
			configMap.addProperty(keyValuePair.key, keyValuePair.value);
		}
		return configMap;
	}
	private KeyValuePair setting(String key,String value)
	{
		return new KeyValuePair(key, value);
	}
}
class KeyValuePair
{
	String key;
	String value;
	public KeyValuePair(String key,String value)
	{
		this.key = key;
		this.value = value;
	}
}
