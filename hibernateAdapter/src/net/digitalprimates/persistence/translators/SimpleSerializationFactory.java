package net.digitalprimates.persistence.translators;

import org.hibernate.SessionFactory;

import net.digitalprimates.persistence.hibernate.utils.HibernateUtil;
import net.digitalprimates.persistence.translators.hibernate.DPHibernateCache;
import net.digitalprimates.persistence.translators.hibernate.HibernateDeserializer;
import net.digitalprimates.persistence.translators.hibernate.HibernateSerializer;

public class SimpleSerializationFactory implements ISerializerFactory
{

	@Override
	public IDeserializer getDeserializer()
	{
		return new HibernateDeserializer();
	}


	@Override
	public ISerializer getSerializer(Object source)
	{
		return getSerializer(source, false);
	}


	@Override
	public ISerializer getSerializer(Object source, boolean useAggressiveSerialization)
	{
		DPHibernateCache cache = new DPHibernateCache();
		SessionFactory sessionFactory = getSessionFactory();
		HibernateSerializer hibernateSerializer = new HibernateSerializer(source,useAggressiveSerialization,cache,sessionFactory);
		return hibernateSerializer;
	}
	
	protected SessionFactory getSessionFactory()
	{
		return HibernateUtil.getSessionFactory();
	}

}
