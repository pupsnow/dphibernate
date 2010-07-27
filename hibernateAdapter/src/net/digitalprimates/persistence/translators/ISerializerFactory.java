package net.digitalprimates.persistence.translators;

import org.hibernate.SessionFactory;

public interface ISerializerFactory
{

	public ISerializer getSerializer(Object source);
	public ISerializer getSerializer(Object source, boolean useAggressiveSerialization);
	public IDeserializer getDeserializer();
	
	public SessionFactory getSessionFactory();
	public void setDefaultConfiguration(SerializerConfiguration configuration);
}