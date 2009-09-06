package net.digitalprimates.persistence.hibernate;

import flex.messaging.messages.RemotingMessage;

public class SaveDPProxyOperation implements DPHibernateOperation {

	private final String saveMethodName;
	public SaveDPProxyOperation(String saveMethodName)
	{
		this.saveMethodName = saveMethodName;
	}
	public boolean appliesForMessage(RemotingMessage message) {
		return "saveDPProxy".equals(message.getOperation());
	}

	public void execute(RemotingMessage remotingMessage) {
		remotingMessage.setOperation(saveMethodName);
	}

}
