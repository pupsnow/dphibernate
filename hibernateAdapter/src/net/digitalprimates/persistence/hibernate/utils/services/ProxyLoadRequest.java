package net.digitalprimates.persistence.hibernate.utils.services;

import java.io.Serializable;

import org.apache.commons.lang.builder.CompareToBuilder;

public class ProxyLoadRequest implements Comparable<ProxyLoadRequest>
{

	public ProxyLoadRequest()
	{}
	public ProxyLoadRequest(String className,Serializable proxyID)
	{
		this.className = className;
		this.proxyID = proxyID;
	}
	private String className;
	private Serializable proxyID;
	private String requestKey;
	public void setClassName(String className)
	{
		this.className = className;
	}
	public String getClassName()
	{
		return className;
	}
	public void setProxyID(Serializable proxyID)
	{
		this.proxyID = proxyID;
	}
	public Serializable getProxyID()
	{
		return proxyID;
	}
	public void setRequestKey(String requestKey)
	{
		this.requestKey = requestKey;
	}
	public String getRequestKey()
	{
		return requestKey;
	}
	@Override
	public int compareTo(ProxyLoadRequest o)
	{
		return this.className.compareTo(o.className);
	}
}
