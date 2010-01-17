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

package net.digitalprimates.persistence.hibernate;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import net.digitalprimates.persistence.translators.ISerializer;
import net.digitalprimates.persistence.translators.SerializationFactory;

import flex.messaging.Destination;
import flex.messaging.config.ConfigMap;
import flex.messaging.messages.Message;
import flex.messaging.messages.RemotingMessage;
import flex.messaging.services.remoting.adapters.JavaAdapter;

@SuppressWarnings("unchecked")
public class HibernateAdapter extends JavaAdapter
{
	// private String scope = "request";
	protected Destination destination;

	private String default_loadMethod = "loadBean";
	private String default_saveMethod = "saveBean";
	private String loadMethodName;
	private String saveMethodName;
	private ArrayList<DPHibernateOperation> operations;


	/**
	 * Initialize the adapter properties from the flex services-config.xml file
	 */
	public void initialize(String id, ConfigMap properties)
	{
		super.initialize(id, properties);
		if (properties == null || properties.size() == 0)
			return;

		ConfigMap adapterProps = properties.getPropertyAsMap("adapterConfig", new ConfigMap());
		ConfigMap destProps = properties.getPropertyAsMap("hibernate", new ConfigMap());

		operations = new ArrayList<DPHibernateOperation>();
		loadMethodName = getLoadMethodName(destProps, adapterProps);
		setSaveMethodName(getSaveMethodName(destProps, adapterProps));
		operations.add(new LoadDPProxyOperation(loadMethodName));
		operations.add(new SaveDPProxyOperation(getSaveMethodName()));
	}
	

	private String getSaveMethodName(ConfigMap destProps, ConfigMap adapterHibernateProps)
	{
		return getConfigProperty(destProps, adapterHibernateProps, "saveMethod", default_saveMethod);
	}


	private String getLoadMethodName(ConfigMap destProps, ConfigMap adapterHibernateProps)
	{
		return getConfigProperty(destProps, adapterHibernateProps, "loadMethod", default_loadMethod);
	}


	private String getConfigProperty(ConfigMap destProps, ConfigMap adapterHibernateProps, String propertyName, String defaultValue)
	{
		String result;
		result = destProps.getPropertyAsString(propertyName, null);
		if (result != null)
			return result;

		result = adapterHibernateProps.getPropertyAsString(propertyName, null);
		return (result != null) ? result : defaultValue;
	}


	public Object superInvoke(Message message)
	{
		return super.invoke(message);
	}


	/**
	 * Invoke the Object.method() called through FlashRemoting
	 */
	public Object invoke(Message message)
	{
		Object results = null;

		if (message instanceof RemotingMessage)
		{
			// RemotingDestinationControl remotingDestination =
			// (RemotingDestinationControl)this.getControl().getParentControl();//destination;
			RemotingMessage remotingMessage = (RemotingMessage) message;

			for (DPHibernateOperation operation : operations)
			{
				if (operation.appliesForMessage(remotingMessage))
				{
					operation.execute(remotingMessage);
				}
			}

			/*
			 * // Add support for the source="" attribute of the RemoteObject
			 * tag. This give developer the option // of using a single
			 * destination for all java calls, and defining the java class in
			 * their mxml // note: This can be turned off at the desination
			 * level by defined a <source/> other then "*" try { FactoryInstance
			 * factoryInstance = remotingDestination.getFactoryInstance();
			 * String className = factoryInstance.getSource(); // check for *
			 * wildcard in destination, and if exists use source defined in mxml
			 * if( "*".equals(className) ) { sourceClass =
			 * remotingMessage.getSource();
			 * factoryInstance.setSource(sourceClass); } }catch( Throwable ex ){
			 * ex.printStackTrace();}
			 */
			System.out.println("{operation})****************" + remotingMessage.getOperation());
			// Deserialize the incoming object data
			List inArgs = remotingMessage.getParameters();
			if (inArgs != null && inArgs.size() > 0)
			{
				try
				{
					long s1 = new Date().getTime();
					Object o = SerializationFactory.getDeserializer(SerializationFactory.HIBERNATESERIALIZER).translate(this, (RemotingMessage) remotingMessage.clone(), loadMethodName, null, null, inArgs);
					remotingMessage.setParameters((List) o);
					long e1 = new Date().getTime();
					System.out.println("{deserialize} " + (e1 - s1));
					// remotingMessage.setBody(body);
				} catch (Exception ex)
				{
					ex.printStackTrace();
					// throw error back to flex
					// todo: replace with custom exception
					RuntimeException re = new RuntimeException(ex.getMessage());
					re.setStackTrace(ex.getStackTrace());
					throw re;
				}
			}

			long s2 = new Date().getTime();
			// invoke the user class.method()
			results = super.invoke(remotingMessage);
			long e2 = new Date().getTime();
			System.out.println("{invoke} " + (e2 - s2));

			// serialize the result out
			try
			{
				long s3 = new Date().getTime();
				ISerializer serializer = SerializationFactory.getSerializer(SerializationFactory.HIBERNATESERIALIZER);
				results = serializer.translate(null,null, results);
				long e3 = new Date().getTime();
				System.out.println("{serialize} " + (e3 - s3));
			} catch (Exception ex)
			{
				ex.printStackTrace();
				// throw error back to flex
				// todo: replace with custom exception
				RuntimeException re = new RuntimeException(ex.getMessage());
				re.setStackTrace(ex.getStackTrace());
				throw re;
			}
		}

		return results;
	}


	public void setLoadMethodName(String loadMethodName)
	{
		this.loadMethodName = loadMethodName;
	}


	public String getLoadMethodName()
	{
		return loadMethodName;
	}


	public void setSaveMethodName(String saveMethodName)
	{
		this.saveMethodName = saveMethodName;
	}


	public String getSaveMethodName()
	{
		return saveMethodName;
	}

}
