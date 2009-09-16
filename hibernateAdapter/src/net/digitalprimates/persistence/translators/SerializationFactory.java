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

import net.digitalprimates.persistence.translators.hibernate.HibernateDeserializer;
import net.digitalprimates.persistence.translators.hibernate.HibernateSerializer;

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
			return new HibernateSerializer();
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
