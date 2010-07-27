package net.digitalprimates.persistence.hibernate;

import flex.messaging.messages.RemotingMessage;

public interface DPHibernateOperation {
	public void execute(RemotingMessage message);
	public boolean appliesForMessage(RemotingMessage message);
}
