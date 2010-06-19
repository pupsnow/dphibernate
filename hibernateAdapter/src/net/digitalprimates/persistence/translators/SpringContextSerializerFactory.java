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

package net.digitalprimates.persistence.translators;

import javax.annotation.Resource;
import javax.servlet.ServletContext;

import net.digitalprimates.persistence.translators.hibernate.HibernateDeserializer;
import net.digitalprimates.persistence.translators.hibernate.HibernateSerializer;

import org.hibernate.SessionFactory;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;

import flex.messaging.FlexContext;

/**
 * Returns a serializer / deserializer from a Spring context.
 * 
 */
public class SpringContextSerializerFactory implements ISerializerFactory
{
	@Resource
	private SessionFactory sessionFactory;
	
	@Override
	public ISerializer getSerializer(Object source)
	{
		return getSerializer(source,false);
	}
	@Override
	public ISerializer getSerializer(Object source,boolean useAggressiveSerialization)
	{
		ServletContext ctx = FlexContext.getServletContext();
		WebApplicationContext springContext = WebApplicationContextUtils.getRequiredWebApplicationContext(ctx);
		ISerializer serializer = (ISerializer) springContext.getBean("hibernateSerializerBean",new Object[]{source,useAggressiveSerialization});
		if (serializer == null)
		{
			throw new RuntimeException("bean named hibernateSerializerBean not found");
		}
		return serializer;
	}

	@Override
	public IDeserializer getDeserializer()
	{
		return new HibernateDeserializer();
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
}
