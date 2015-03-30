# Pre-Requisites #
  1. BlazeDS Server
  1. A configured J2EE server with BlazeDS, your project, and all required Hibernate jars.


# Downloads #

  * Download the dpHibernateX.X.X.jar
    * Place the downloaded jar into your  `<BlazeDS>WEB-INF\lib`  folder.
  * Download the dpHibernateX.X.X.swc
    * Add this file to your Flex3 Project

# Configuration Changes #

  * Add Hibernate Session Filter to the 

&lt;BlazeDS&gt;

\WEB-INF\web.xml file

> dpHibernate requires having access to an open session while processing the incoming arguments and outgoing results. Which means that we need to have an open session throughout the life of the request. The easiest way to do this is with a customer Servlet Filter wrapped around the BlazeDS MessageBrokerServlet.

> _You can find more information on creating your own Hibernate session filter here: http://www.hibernate.org/43.html. However, for your convenience, there is a Hibernate servlet filter in net.digitalprimates.persistence.hibernate.utils.filters package._

> Sample filter configuration in web.xml:
```
    <filter>
        <filter-name>hibernateSessionFilter</filter-name>
        <filter-class>net.digitalprimates.persistence.hibernate.utils.filters.HibernateSessionServletFilter</filter-class>
    </filter>

    <filter-mapping>
        <filter-name>hibernateSessionFilter</filter-name>
        <url-pattern>/messagebroker/*</url-pattern>
    </filter-mapping>
```


  * Modify your BlazeDS remote-config.xml to add our custom adapter and your 

&lt;destination&gt;

(s)
    * Add the following Adapter:
```
    <adapters>
        <adapter-definition id="hibernate-object" class="net.digitalprimates.persistence.hibernate.HibernateAdapter" default="true">
        	<properties>
        		<hibernate>
	        		<sessionFactory>
	        			<class>net.digitalprimates.persistence.hibernate.utils.HibernateUtil</class>
	        			<getCurrentSessionMethod>getCurrentSession</getCurrentSessionMethod>        			
	        		</sessionFactory>
        		</hibernate>
        	</properties>
         
        </adapter-definition>
    </adapters>
```

> _Note: You will need to define the path to a java file that the adapter can use to get access to the current session that was open in the servlet filter, defined above._

_Note:  Do not depend on "net.digitalprimates.persistence.hibernate.utils.HibernateUtil". in the adapter. If you are using your own session management, such as spring, and not the provided default filter "net.digitalprimates.persistence.hibernate.utils.filters.HibernateSessionServletFilter" (which is only meant to be an example anyways.) to manage your hibernate sessions. These two class settings are meant to go together. So if you write a custom version of one you need a custom version of the other._

  * Create your custom hibernate destination, just like you would to any other Java class.