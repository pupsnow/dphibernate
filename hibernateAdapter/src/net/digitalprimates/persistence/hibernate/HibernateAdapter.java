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

import net.digitalprimates.persistence.hibernate.utils.HibernateUtil;
import net.digitalprimates.persistence.translators.ISerializer;
import net.digitalprimates.persistence.translators.ISerializerFactory;
import net.digitalprimates.persistence.translators.SimpleSerializationFactory;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import flex.messaging.Destination;
import flex.messaging.config.ConfigMap;
import flex.messaging.messages.Message;
import flex.messaging.messages.RemotingMessage;
import flex.messaging.services.remoting.adapters.JavaAdapter;

@SuppressWarnings("unchecked")
public class HibernateAdapter extends JavaAdapter
{
	private static final Log log = LogFactory.getLog(HibernateAdapter.class);
	
	protected Destination destination;

	private static final String DEFAULT_LOAD_METHOD_NAME = "loadBean";
	private static final String DEFAULT_SAVE_METHOD_NAME = "saveBean";
	private static final String DEFAULT_SERIALZIER_FACTORY_CLASSNAME = SimpleSerializationFactory.class.getCanonicalName();
	private String loadMethodName;
	private String saveMethodName;
	private ArrayList<DPHibernateOperation> operations;
	private ISerializerFactory serializerFactory;

	public HibernateAdapter()
	{
		super();
	}

	/**
	 * Initialize the adapter properties from the flex services-config.xml file
	 */
	public void initialize(String id, ConfigMap properties)
	{
		super.initialize(id, properties);
		if (properties == null || properties.size() == 0)
			return;

		ConfigMap dpHibernateProps = properties.getPropertyAsMap("dpHibernate", new ConfigMap());
		initalizeSerializerFactory(dpHibernateProps);
		initalizeOperations();
		loadMethodName = dpHibernateProps.getPropertyAsString("loadMethod", getDefaultLoadMethodName());
		saveMethodName = dpHibernateProps.getPropertyAsString("saveMethod", getDefaultSaveMethodName());
		operations.add(new LoadDPProxyOperation(loadMethodName));
		operations.add(new SaveDPProxyOperation(getSaveMethodName()));
		
		logConfiguration();
	}
	

	private void initalizeOperations()
	{
		if (operations == null)
		{
			operations = new ArrayList<DPHibernateOperation>();
		}
	}

	private String getDefaultSaveMethodName()
	{
		return (saveMethodName != null) ? saveMethodName : DEFAULT_SAVE_METHOD_NAME; 
	}

	private String getDefaultLoadMethodName()
	{
		return (loadMethodName != null) ? loadMethodName : DEFAULT_LOAD_METHOD_NAME;
	}

	private void logConfiguration()
	{
		log.debug("dpHibernate loadMethodName: " + loadMethodName);
		log.debug("dpHibernate saveMethodName: " + saveMethodName);
		log.debug("dpHibernate serializerFactory: " + serializerFactory.getClass().getCanonicalName());
	}

	private void initalizeSerializerFactory(ConfigMap adapterProps)
	{
		String serializationFactoryClassName = adapterProps.getPropertyAsString("serializerFactory", null);
		if (serializerFactory != null && serializationFactoryClassName == null)
		{
			// The configuration did not specify an overriding SerializerFactory, and
			// we already have one configured, so exit now.
			return;
		}
		if (serializationFactoryClassName == null)
		{
			serializationFactoryClassName = DEFAULT_SERIALZIER_FACTORY_CLASSNAME;
		}
		Class<ISerializerFactory> serializationFactoryClass;
		try
		{
			serializationFactoryClass = (Class<ISerializerFactory>) Class.forName(serializationFactoryClassName);
			serializerFactory = serializationFactoryClass.newInstance();
			HibernateUtil.setSerializerFactory(serializerFactory);
		} catch (Exception e)
		{
			e.printStackTrace();
			throw new RuntimeException(e);
		}
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
					Object o = serializerFactory.getDeserializer().translate(this, (RemotingMessage) remotingMessage.clone(), loadMethodName, null, null, inArgs);
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
				ISerializer serializer = serializerFactory.getSerializer(results);
				
				results = serializer.serialize();
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
