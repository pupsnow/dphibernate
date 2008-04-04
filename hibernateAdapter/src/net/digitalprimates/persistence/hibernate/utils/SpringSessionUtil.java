package net.digitalprimates.persistence.hibernate.utils;

import org.hibernate.Session;

public class SpringSessionUtil 
{
	public static Session getCurrentSession() 
	{		
		return null;
		/* comment this out if you need it.
		ServletContext ctx = FlexContext.getServletContext();
		WebApplicationContext springContext = WebApplicationContextUtils.getRequiredWebApplicationContext(ctx);
		SessionFactory sessionFactory = (SessionFactory)springContext.getBean("sessionFactory");
		Session session = SessionFactoryUtils.getSession(sessionFactory, false);
		return session;
		*/
    }
	
}
