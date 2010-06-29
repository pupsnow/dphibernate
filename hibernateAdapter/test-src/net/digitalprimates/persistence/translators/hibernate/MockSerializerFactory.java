package net.digitalprimates.persistence.translators.hibernate;

import org.hibernate.SessionFactory;

import net.digitalprimates.persistence.translators.IDeserializer;
import net.digitalprimates.persistence.translators.ISerializer;
import net.digitalprimates.persistence.translators.ISerializerFactory;

public class MockSerializerFactory implements ISerializerFactory
{

	@Override
	public IDeserializer getDeserializer()
	{
		// TODO Auto-generated method stub
		return null;
	}


	@Override
	public ISerializer getSerializer(Object source)
	{
		// TODO Auto-generated method stub
		return null;
	}


	@Override
	public ISerializer getSerializer(Object source, boolean useAggressiveSerialization)
	{
		// TODO Auto-generated method stub
		return null;
	}


	@Override
	public SessionFactory getSessionFactory()
	{
		// TODO Auto-generated method stub
		return null;
	}

}
