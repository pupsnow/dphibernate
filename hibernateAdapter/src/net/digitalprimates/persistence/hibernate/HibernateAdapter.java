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

	/*
	 * static {
	 * PropertyProxyRegistry.getRegistry().register(HibernateProxy.class, new
	 * HibernateLazyPropertyProxy());
	 * PropertyProxyRegistry.getRegistry().register(AbstractPersistentCollection.class,
	 * new HibernateLazyCollectionProxy()); }
	 */

	private String property_hibernateSessionFactoryClass = "";// "net.digitalprimates.persistence.hibernate.tools.HibernateFactory";
	private String property_getCurrentSessionMethod = "";// "getCurrentSession";
	private String property_loadMethod = "";// "load";
	private String property_saveMethod = "";
	private ArrayList<DPHibernateOperation> operations;


	/**
	 * Initialize the adapter properties from the flex services-config.xml file
	 */
	public void initialize(String id, ConfigMap properties)
	{
		super.initialize(id, properties);
		if (properties == null || properties.size() == 0)
			return;

		// properties.getProperty("hibernateFactory");
		ConfigMap adapterProps = properties.getPropertyAsMap("hibernate", new ConfigMap());
		ConfigMap adapterHibernateProps = adapterProps.getPropertyAsMap("sessionFactory", new ConfigMap());
		property_hibernateSessionFactoryClass = adapterHibernateProps.getPropertyAsString("class", property_hibernateSessionFactoryClass);
		property_getCurrentSessionMethod = adapterHibernateProps.getPropertyAsString("getCurrentSessionMethod", property_getCurrentSessionMethod);

		ConfigMap destProps = properties.getPropertyAsMap("hibernate", new ConfigMap());
		property_loadMethod = destProps.getPropertyAsString("loadMethod", property_loadMethod);
		property_saveMethod = destProps.getPropertyAsString("saveMethod", property_saveMethod);
		operations = new ArrayList<DPHibernateOperation>();
		operations.add(new LoadDPProxyOperation(getLoadMethodName()));
		operations.add(new SaveDPProxyOperation(getSaveMethodName()));
	}


	private String getSaveMethodName() {
		return property_saveMethod;
	}


	/**
	 * Store the adapter properties in the local properties object
	 * 
	 * @param destination
	 * @param adapterSettings
	 * @param destinationSettings
	 * 
	 * public void setSettings(Destination destination, AdapterSettings
	 * adapterSettings, DestinationSettings destinationSettings) {
	 * //super.setSettings(destination, adapterSettings, destinationSettings);
	 *  // Second, initialize adapter level properties PropertiesSettings
	 * properties = adapterSettings; properties(properties);
	 *  // Third, initialize destination level properties properties =
	 * destinationSettings; properties(properties); }
	 * 
	 * 
	 * 
	 * protected void properties(PropertiesSettings propertiesSettings) {
	 * super.properties(propertiesSettings); }
	 */

	private String getLoadMethodName()
	{
		return property_loadMethod;
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

			for (DPHibernateOperation operation : operations )
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
			 * String className = factoryInstance.getSource();
			 *  // check for * wildcard in destination, and if exists use source
			 * defined in mxml if( "*".equals(className) ) { sourceClass =
			 * remotingMessage.getSource();
			 * factoryInstance.setSource(sourceClass); } }catch( Throwable ex ){
			 * ex.printStackTrace();}
			 */
			System.out.println("{operation})****************" +remotingMessage.getOperation());
			// Deserialize the incoming object data
			List inArgs = remotingMessage.getParameters();
			if (inArgs != null && inArgs.size() > 0)
			{
				try
				{
					long s1 = new Date().getTime();
						Object o = SerializationFactory.getDeserializer(SerializationFactory.HIBERNATESERIALIZER).translate(this, (RemotingMessage) remotingMessage.clone(), getLoadMethodName(), property_hibernateSessionFactoryClass, property_getCurrentSessionMethod, inArgs);
						remotingMessage.setParameters((List) o);
					long e1 = new Date().getTime();
					System.out.println("{deserialize} " +(e1-s1));
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
			System.out.println("{invoke} " +(e2-s2));

			// serialize the result out
			try
			{
				long s3 = new Date().getTime();
					results = SerializationFactory.getSerializer(SerializationFactory.HIBERNATESERIALIZER).translate(property_hibernateSessionFactoryClass, property_getCurrentSessionMethod, results);
				long e3 = new Date().getTime();
				System.out.println("{serialize} " +(e3-s3));
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

}
