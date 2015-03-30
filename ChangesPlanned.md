# Introduction #

2.0 is due for release shortly.  It involves a number of breaking changes, and changes to how dpHibernate is configured.

We will be seeking community feedback on these changes before a final release, so content listed here is subject to change.

If you have concerns about some of these changes, please email the mailing list:
dphibernate@googlegroups.com

## RC1 Available ##
dpHibernate 2.0-RC1 is now available.

http://code.google.com/p/dphibernate/downloads/detail?name=2.0-RC1.zip

# Details #
## General ##
All classes have been moved from net.digitalprimates.**into a new namespace: org.dphibernate.**

This is a breaking change.  You need to update any references throughout the code to the new  namespace.
## Configuration ##
**Renamed**: net.digitalprimates.persistence.hibernate.HibernateAdapter becomes org.dphibernate.adapters.RemotingAdapter

### DefaultHibernateService ###
You must now initalize a defaultHibernateService to an `IHibernateRPC` instance upon initlaization of the application.

Previously, dpHibernate used reflection at runtime to associate all incoming entities with the service they were received from.  This approach has been replaced by the `defaultHibernateService` as the preferred approach for mapping entities with a service.

The plan is to re-introduce support for reflection based mapping at runtime before the 2.0 release.  However, it is not currently supported.

Example:
```
<dphibernate:HibernateRemoteObject id="dataAccessService" destination="dataAccessService" channelSet="{channelSet}" bufferProxyLoadRequests="true" />

public function onApplicationInitalize():void
{
	// Setup a default service.
	// This is used by beans to perform dpHibernate operations (Save / Load, etc)
	// where a service has not yet been assigned to the bean.
	// Note - services are generally assigned to beans when they are
	// sent to the client from a service call.
	HibernateManaged.defaultHibernateService = this.dataAccessService;

}
```


The strategy for resolving the HibernateRPC used is now configurable, should you wish to implement your own.  You can define this by setting `HibernateManaged.hibernateRPCProvider` to an instance of `IHibernateROProvider`.

Currently only `DefaultHibernateRPCProvider` is shipped (which uses the `HibernateManaged.defaultHibernateService` property.

Before 2.0, we plan to include:
  * `BeanResolvedHibernateRPCProvider` which uses the old approach of mapping incoming beans to the service they arrived on.
  * `AnnotationHibernateRPCProvider` which allows you to specify a destination using annotations on your model.

The main configuration block has changed.
  * You now must decalre a SerializerFactory.  This is the only mandatory field.
    * If running in Spring, use `org.dphibernate.serialization.SpringContextSerializerFactory`
    * If running outside of Spring, use `org.dphibernate.serialization.SimpleSerializationFactory`
    * Alternatively, write your own.  It must implement `org.dphibernate.serialization.ISerializerFactory`
  * The `sessionFactory` element has been dropped.  SessionFactories are now provided by the SerializerFactory.  In the case of Spring, the sessionFactory is now injected by the container, rather than being explicitly fetched
  * `loadMethod` and `saveMethod` are now optional.  If ommitted, the values default to loadBean and saveBean respectively.
  * Added the `loadBatchMethod` property, which specifies the method name used for batch loaded calls.  If ommitted, it defaults to `loadProxyBatch`
  * Added the `pageSize` property, which configures pagination on the adapter.  If  **ommitted, defaults to -1 - disabled.**

## Misc ##
  * The default implementation of IHibernateProxy is now HibernateBean.as / HibernateBean.java.  Previously there were various approaches present in the codebase with mixed names.  Old approaches have been deleted.