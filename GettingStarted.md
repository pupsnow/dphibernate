# Introduction #
dpHibernate is designed to quietly work behind the scenes and make everything as seamless as possible. However in order for us to do this we do need to know which objects we need to manage. This is done with the Managed metadata and a simple extends added to every value object/pojo class.

# Setup and Configuration #
Before you start make sure you have followed the setup and configuration instructions defined here: [Setup](SetupAndConfiguration.md)


# Actionscript #

In order for dpHibernate to be able to monitor the state of your objects and trigger the lazy loading as objects are touched. Two things need to be done to every value object in Action Script.

  1. Add the `Managed` meta data flag to each class
  1. Every value object, returned from Hibernate, that needs to be monitored and managed by dpHibernate needs to extend the `HibernateBean` (`net.digitalprimates.persistence.hibernate.HibernateBean`) class
    * Alternativly every value object can implement the `IHibernateBean` interface instead. (`net.digitalprimates.persistence.hibernate.HibernateBean`)

```
package model.beans
{
	import mx.collections.ArrayCollection;
	import net.digitalprimates.persistence.hibernate.HibernateBean;
	
	[RemoteClass(alias="net.digitalprimates.samples.sample1.beans.User")]
	[Managed]
	public class User extends HibernateBean
	{
		public var id:String;
		public var firstName:String;
		public var lastName:String;
		public var addresses:ArrayCollection;
		public var connectInfo:UserConnectInfo;
	}
}
```


# Java #

dpHibernate works by passing either the real object or a proxy back and forth with flex. For this reason the POJO's on the Java side, which will be returned by hibernate, need to be able to live as both a proxy and the full object.

  * Extend the POJO classes with the: `HibernateProxy` (`net.digitalprimates.persistence.hibernate.proxy.HibernateProxy`)
    * Alternatively you can implement the interface: `IHibernateProxy` (`net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy`)