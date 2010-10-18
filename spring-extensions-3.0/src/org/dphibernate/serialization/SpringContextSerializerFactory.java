/**
	Copyright (c) 2008. Digital Primates IT Consulting Group
	http://www.digitalprimates.net
	All rights reserved.
	
	This library is free software; you can redistribute it and/or modify it under the 
	terms of the GNU Lesser General Public License as published by the Free Software 
	Foundation; either version 2.1 of the License.

	This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; 
	without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
	See the GNU Lesser General Public License for more details.

	
	@author: Mike Nimer
	@ignore
 **/

package org.dphibernate.serialization;

import javax.annotation.Resource;
import javax.servlet.ServletContext;
import javax.servlet.http.HttpServletRequest;

import org.hibernate.SessionFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;
import org.springframework.web.servlet.support.RequestContextUtils;

import flex.messaging.FlexContext;

/**
 * Returns a serializer / deserializer from a Spring context.
 * 
 */
public class SpringContextSerializerFactory implements ISerializerFactory
{
	@Resource
	private SessionFactory sessionFactory;
	
	private SerializerConfiguration defaultConfiguration;

	@Override
	public ISerializer getSerializer(Object source)
	{
		return getSerializer(source,false);
	}
	@Override
	public ISerializer getSerializer(Object source,boolean useAggressiveSerialization)
	{
		ApplicationContext context = getSpringContextForFlexContext();
		String serializerBeanName = getSerializerBeanName(context);
		ISerializer serializer = (ISerializer) context.getBean(serializerBeanName,new Object[]{source,useAggressiveSerialization});
		serializer.configure(defaultConfiguration);
		return serializer;
	}
	private ApplicationContext getSpringContextForFlexContext() {
		HttpServletRequest request = FlexContext.getHttpRequest();
		// Try to find the context for the correct DipsatcherServlet.
		WebApplicationContext context = RequestContextUtils.getWebApplicationContext(request);
		
		if (context == null)
		{
			// Get the root instead.
			ServletContext servletContext = FlexContext.getServletContext();
			context= WebApplicationContextUtils.getRequiredWebApplicationContext(servletContext);
		}
		return context;
	}
	String getSerializerBeanName(ApplicationContext context)
	{
		String[] beanNames = context.getBeanNamesForType(ISerializer.class);
		if (beanNames.length == 0)
		{
			throw new RuntimeException("No Serializer is configured in the Spring context.  Ensure exactly one one ISerializer instance is declared");
		}
		if (beanNames.length > 1)
		{
			throw new RuntimeException("More than one Serializer is configured in the Spring context.  Ensure exactly one one ISerializer instance is declared");
		}
		return beanNames[0];
	}

	@Override
	public IDeserializer getDeserializer()
	{
		ApplicationContext context = getSpringContextForFlexContext();
		String deserializerBeanName = getDeserializerBeanName(context);
		IDeserializer deserializer = (IDeserializer) context.getBean(deserializerBeanName);
		if (deserializer == null)
		{
			deserializer = new HibernateDeserializer();
		}
		return deserializer;
	}
	String getDeserializerBeanName(ApplicationContext context)
	{
		String[] beanNames = context.getBeanNamesForType(IDeserializer.class);
		if (beanNames.length == 0)
		{
			throw new RuntimeException("No Deserializer is configured in the Spring context.  Ensure exactly one one IDeserializer instance is declared");
		}
		if (beanNames.length > 1)
		{
			throw new RuntimeException("More than one deserializer is configured in the Spring context.  Ensure exactly one one IDeserializer instance is declared");
		}
		return beanNames[0];
	}
	public void setSessionFactory(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}
	@Override
	public SessionFactory getSessionFactory()
	{
		return sessionFactory;
	}
	@Override
	public void setDefaultConfiguration(SerializerConfiguration configuration)
	{
		this.defaultConfiguration = configuration;
	}
}
