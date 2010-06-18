package net.digitalprimates.persistence.translators;

public interface ISerializerFactory
{

	public abstract ISerializer getSerializer(Object source);


	public abstract ISerializer getSerializer(Object source, boolean useAggressiveSerialization);


	public abstract IDeserializer getDeserializer();

}