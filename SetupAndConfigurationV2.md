## Client entity classes ##
Client classes are required to either subclass [HibernateBean](http://code.google.com/p/dphibernate/source/browse/branches/2.0/flexLibrary/flex-src/org/dphibernate/core/HibernateBean.as) or implement [IHibernateProxy](http://code.google.com/p/dphibernate/source/browse/branches/2.0/flexLibrary/flex-src/org/dphibernate/core/IHibernateProxy.as).  A sample implementation of IHibernate proxy can be found [here](http://code.google.com/p/dphibernate/source/browse/trunk/samples/lazyLoadingWithSpring/flex/src/com/mangofactory/pepper/model/BaseEntity.as).

Additionally, client classes must be annotated with the `[Managed]` metatag.  Eg:

```
        [Managed]
        [RemoteClass(alias="com.mangofactory.pepper.model.Post")]
        public class Post extends BaseEntity
        {
           ...
        }
```

## Server entity classes ##
Similarly, your server-side Java classes must either subclass [HibernateProxy](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/core/HibernateProxy.java) or implement [IHibernateProxy](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/core/IHibernateProxy.java).

A sample implementation of IHibernateProxy can be found [here](http://code.google.com/p/dphibernate/source/browse/trunk/samples/lazyLoadingWithSpring/java/src/com/mangofactory/pepper/model/BaseEntity.java).

### IHibernateProxy.java implementation ###
If implementing IHibernateProxy yourself, you must make sure that `getProxyKey()` returns your entities primary key.  Note - composite keys are not supported.

## Server side services ##
dpHibernate provides various server side configurations.  Depending on which features you wish to activate, you need to expose different services

| **Feature** | **Required Service Interface** | **Shipped Default** |
|:------------|:-------------------------------|:--------------------|
|Lazy loading|IProxyLoadService|[ProxyLoadService](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/ProxyLoadService.java)|
|Batched lazy loading|[IProxyBatchLoader](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/IProxyBatchLoader.java)|[ProxyBatchLoader](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/ProxyBatchLoader.java)|
|Lazy loading + Batched Loading (_recommended minimum_)|ILazyLoadService + IProxyBatchLoader|[LazyLoadService](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/LazyLoadService.java)|
|Update / Delete entities|[IProxyUpdateService](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/IProxyUpdateService.java)|[ProxyUpdaterService](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/ProxyUpdaterService.java)|
|All the above (_recommended configuration_)|  |[DataAccessService](http://code.google.com/p/dphibernate/source/browse/branches/2.0/server-adapter/src/org/dphibernate/services/DataAccessService.java)|

  * Note - Spring based versions of the default services are also provided, if your configuration uses Spring.  Services are provided both for [Spring 2.5.6](http://code.google.com/p/dphibernate/source/browse/branches/2.0/#2.0%2Fspring-extensions-2.5.6%2Fsrc%2Forg%2Fdphibernate%2Fservices) and [Spring 3.x](http://code.google.com/p/dphibernate/source/browse/branches/2.0/#2.0%2Fspring-extensions-3.0%2Fsrc%2Forg%2Fdphibernate%2Fservices)

A typical server configuration for lazy loading only can be found [here](http://code.google.com/p/dphibernate/source/browse/#svn%2Ftrunk%2Fsamples%2FlazyLoadingWithSpring), or with both lazy loading and entity persistence [here](http://code.google.com/p/lazyoverflow/).

## Server configuration ##
Once your services extend / implement the appropraite interfaces, you need to configure them.

The spring configuration is currently somewhat verbose.  This is an issue currently being investigated.

An example spring configuration is shown here:

```
        <bean id="dpHibernateRemotingAdapter"
                class="org.springframework.flex.core.ManageableComponentFactoryBean">
                <constructor-arg value="org.dphibernate.adapters.RemotingAdapter" />
                <property name="properties">
                        <value>
                                {"dpHibernate" :
                                {
                                "serializerFactory" : "org.dphibernate.serialization.SpringContextSerializerFactory"
                                }
                                }
        </value>
                </property>
        </bean>
        <!--
                Provides a basic service for lazy loading operations through
                dpHibernate. It's also exported as a remoting destination, which makes
                it accessible to flex clients
        -->
        <bean id="dataAccessService" class="org.dphibernate.services.SpringLazyLoadService"
                autowire="constructor">
                <flex:remoting-destination />
        </bean>
        <!--
                The main serializer. Converts outbound POJO's to ASObjects with
                dpHibernate proxies for lazy loading. Required
        -->
        <bean id="dpHibernateSerializer" class="org.dphibernate.serialization.HibernateSerializer"
                scope="prototype">
                <property name="pageSize" value="10" />
        </bean>
        <bean id="dpHibernateDeserializer" class="org.dphibernate.serialization.HibernateDeserializer"
                scope="prototype" />

```

See also [this example](http://code.google.com/p/dphibernate/source/browse/trunk/samples/lazyLoadingWithSpring/WebContent/WEB-INF/flexContext.xml)

This is the minimum configuration.  For a more complete example, see [here](http://code.google.com/p/lazyoverflow/source/browse/trunk/WebContent/WEB-INF/dpHibernateContext.xml), or more detailed ConfigurationOptions.

# Client configration #

Client configuration is minimal.

Any services you wish dpHibernate to provide paging support for should be declared as a `HibernateRemoteObject`, instead of a normal `RemoteObject`.

For example:

```
<fx:Declarations>
       <dphibernate:HibernateRemoteObject id="dataService"
                   destination="dataService"
                   bufferProxyLoadRequests="true"
                   fault="faultHandler(event)"/>
</fx:Declarations>
```
_Note: `bufferProxyLoadRequests` is optional, and is used to define if proxy loads should be buffered to improve performance.  See [this blog post](http://martypitt.wordpress.com/2010/07/07/batch-loading-proxies-in-dphibernate/) for more details._

A `HibernateRemoteObject` can be used like any standard `mx:RemoteObject`, and configured to point to any destination on your server and invoke methods as per normal.  **Note: The destination of a HibernateRemoteObject does not need to be a dpHibernateService**.

## Define DefaultHibernateService ##
Once your application is initialized, you are required to define the `defaultHibernateService`.  This is the service which calls to fetch lazy-loaded entities will be made over.  This destination MUST implement the appropriate interfaces, as defined above.

Set up your service on initialization as follows:

```
public function onApplicationComplete():void
{
	HibernateManaged.defaultHibernateService = this.dataAccessService;
}
```

That's it.  Now, any entities and collections lazy loaded by Hibernate will be lazily fetched / serialized by dpHibernate.