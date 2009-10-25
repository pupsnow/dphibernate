package net.digitalprimates.persistence.state;

import java.security.Principal;

public interface IChangeMessageInterceptor
{
	public boolean appliesToMessage(ObjectChangeMessage message);
	public void processMessage(ObjectChangeMessage message);
	public void processMessage(ObjectChangeMessage message,Principal user);
}
