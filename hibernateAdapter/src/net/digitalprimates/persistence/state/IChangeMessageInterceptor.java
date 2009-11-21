package net.digitalprimates.persistence.state;

import java.security.Principal;

public interface IChangeMessageInterceptor
{
	public boolean appliesToMessage(ObjectChangeMessage message);
	public void processMessage(ObjectChangeMessage message,IProxyResolver proxyResolver);
	public void processMessage(ObjectChangeMessage message,IProxyResolver proxyResolver, Principal user);
}
