package net.digitalprimates.persistence.hibernate;

import net.digitalprimates.persistence.translators.ISerializer;
import net.digitalprimates.persistence.translators.ISerializerFactory;
import net.digitalprimates.persistence.translators.SpringContextSerializerFactory;
import flex.messaging.messages.Message;
import flex.messaging.services.messaging.adapters.ActionScriptAdapter;

public class HibernateActionscriptAdapter extends ActionScriptAdapter
{

	@Override
	/**
     * Handle a data message intended for this adapter.
     */
    public Object invoke(Message message)
    {
		// TODO : Currently, only supports spring instances.
		ISerializerFactory factory = new SpringContextSerializerFactory();
        ISerializer serializer = factory.getSerializer(message.getBody(),true);
        
        Object translatedBody = serializer.serialize();
        message.setBody(translatedBody);
        return super.invoke(message);
    }
}
