package net.digitalprimates.persistence.hibernate;

import net.digitalprimates.persistence.translators.ISerializer;
import net.digitalprimates.persistence.translators.SerializationFactory;
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
        ISerializer serializer = SerializationFactory.getSerializer(SerializationFactory.HIBERNATESERIALIZER);
        Object translatedBody = serializer.translate(null, null, message.getBody());
        message.setBody(translatedBody);
        return super.invoke(message);
    }
}
