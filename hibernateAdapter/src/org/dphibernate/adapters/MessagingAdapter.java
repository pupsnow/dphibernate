package org.dphibernate.adapters;

import org.dphibernate.serialization.ISerializer;
import org.dphibernate.serialization.ISerializerFactory;
import org.dphibernate.serialization.SpringContextSerializerFactory;

import flex.messaging.messages.Message;
import flex.messaging.services.messaging.adapters.ActionScriptAdapter;

public class MessagingAdapter extends ActionScriptAdapter
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
