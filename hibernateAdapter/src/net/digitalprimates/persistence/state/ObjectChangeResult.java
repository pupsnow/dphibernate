package net.digitalprimates.persistence.state;

import java.io.Serializable;

public class ObjectChangeResult {

	private final Serializable oldId;
	private final Serializable newId;
	private final String remoteClassName;
	
	public ObjectChangeResult(String className,Serializable oldId,Serializable newId)
	{
		this.oldId = oldId;
		this.newId = newId;
		this.remoteClassName = className;
	}
	public ObjectChangeResult(Class<?> entityClass,Serializable oldId,Serializable newId)
	{
		this(entityClass.getName(),oldId,newId);
	}
	public ObjectChangeResult(ObjectChangeMessage changeMessage,Serializable newId)
	{
		this.remoteClassName = changeMessage.getOwner().getRemoteClassName();
		this.oldId = changeMessage.getOwner().getProxyId();
		this.newId = newId;
	}
	public String getRemoteClassName() 
	{
		return remoteClassName;
	}
	
	
	public Serializable getNewId() {
		return newId;
	}
	public Serializable getOldId()
	{
		return oldId;
	}

}
