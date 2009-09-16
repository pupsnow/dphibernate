package net.digitalprimates.persistence.state;

import java.io.Serializable;

public class ObjectChangeResult {

	private final Object oldId;
	private final Object newId;
	private final String remoteClassName;
	
	public ObjectChangeResult(String className,Object oldId,Object newId)
	{
		this.oldId = oldId;
		this.newId = newId;
		this.remoteClassName = className;
	}
	public ObjectChangeResult(Class<?> entityClass,Object oldId,Object newId)
	{
		this(entityClass.getName(),oldId,newId);
	}
	public ObjectChangeResult(ObjectChangeMessage changeMessage,Object newId)
	{
		this.remoteClassName = changeMessage.getOwner().getRemoteClassName();
		this.oldId = changeMessage.getOwner().getProxyId();
		this.newId = newId;
	}
	public String getRemoteClassName() 
	{
		return remoteClassName;
	}
	
	
	public Object getNewId() {
		return newId;
	}
	public Object getOldId()
	{
		return oldId;
	}

}
