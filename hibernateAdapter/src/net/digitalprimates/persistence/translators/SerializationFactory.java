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

import javax.servlet.ServletContext;

import net.digitalprimates.persistence.translators.hibernate.HibernateDeserializer;

import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;

import flex.messaging.FlexContext;

/**
 * Factory to return the right serializer/deserializer for the requests. 
 * @author mike nimer
 */
public class SerializationFactory 
{
	public final static String HIBERNATESERIALIZER = "HIBERNATE";
	
	public static ISerializer getSerializer(String type)
	{
		if( HIBERNATESERIALIZER.equals(type) )
		{
			ServletContext ctx = FlexContext.getServletContext();
			WebApplicationContext springContext = WebApplicationContextUtils.getRequiredWebApplicationContext(ctx);
			ISerializer serializer = (ISerializer) springContext.getBean("hibernateSerializerBean");
			if (serializer == null)
			{
				throw new RuntimeException("bean named hibernateSerializerBean not found");
			}
			return serializer;
		}

		throw new RuntimeException("unsupport serialization type: " +type);
	}
	
	
	public static IDeserializer getDeserializer(String type)
	{
		if( HIBERNATESERIALIZER.equals(type) )
		{
			return new HibernateDeserializer();
		}
		
		throw new RuntimeException("unsupport deSerialization type: " +type);
	}
	
}
