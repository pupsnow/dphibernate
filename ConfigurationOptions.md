# Custom load / save methods #
You can customize the load / save methods called on the java services, by setting custom `loadMethod` and `saveMethod` properties on the  remoting adapter with as follows:


```
	<bean id="dpHibernateRemotingAdapter"
		class="org.springframework.flex.core.ManageableComponentFactoryBean">
		<constructor-arg
			value="org.dphibernate.adapters.RemotingAdapter" />
		<property name="properties">
			<value>
				{"dpHibernate" :
					{
						"serializerFactory" : "org.dphibernate.serialization.SpringContextSerializerFactory",
						"loadMethod" : "myLoadMethod"
						"saveMethod" : "mySaveMethod"
					}
				}
        </value>
		</property>
	</bean>

```

# Pagination #
Collections are not paginated by default.  You can enable this by defining the page size in one of two places.

Either on the RemotingAdapter, as follows:

```
			<value>
				{"dpHibernate" :
					{
						"serializerFactory" : "org.dphibernate.serialization.SpringContextSerializerFactory",
						"pageSize" : "10"
					}
				}
        </value>
```

or on the serializer:

```
	<bean id="dpHibernateSerializer"
		class="org.dphibernate.serialization.HibernateSerializer" scope="prototype">
			<property name="pageSize" value="5"/>
	</bean>
```

Note : It is possible to define a SerialzerFactory which returns multiple serializers.  Therefore, the order of precedence is as follows:
**Settings defined on a serializer take precedence** Settings defined on the remotingAdapter are applied to all serializers that don't define a custom setting
