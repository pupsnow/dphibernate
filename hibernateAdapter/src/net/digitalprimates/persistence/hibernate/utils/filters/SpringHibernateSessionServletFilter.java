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


package net.digitalprimates.persistence.hibernate.utils.filters;

import java.io.IOException;

import javax.annotation.Resource;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;

import net.digitalprimates.persistence.hibernate.utils.HibernateUtil;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.StaleObjectStateException;
import org.hibernate.stat.SessionStatistics;


/**
 * Servlet Filter to open a close the Hibernate session for each request.
 * 
 * based on the servlet filter code: http://www.hibernate.org/43.html
 * 
 * @author mike nimer
 */
public class SpringHibernateSessionServletFilter implements Filter
{
	@Resource
	private SessionFactory sessionFactory;

	private static Log log = LogFactory.getLog(SpringHibernateSessionServletFilter.class);


	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException
	{
		try
		{
			Session session = sessionFactory.getCurrentSession();
			HibernateUtil.beginTransaction(session);
			
			// Call the next filter (continue request processing)
			chain.doFilter(request, response);

			// Commit and cleanup
			log.debug("Committing the database transaction");
			HibernateUtil.commitTransaction();

		} 
		catch (StaleObjectStateException staleEx)
		{
			log.error("This interceptor does not implement optimistic concurrency control!");
			log.error("Your application will not work until you add compensation actions!");

			// Rollback, close everything, possibly compensate for any permanent
			// changes
			// during the conversation, and finally restart business
			// conversation. Maybe
			// give the user of the application a chance to merge some of his
			// work with
			// fresh data... what you do here depends on your applications
			// design.
			throw staleEx;
		} catch (Throwable ex)
		{
			// Rollback only
			ex.printStackTrace();
			try
			{
				if (HibernateUtil.getTransaction().isActive())
				{
					log.debug("Trying to rollback database transaction after exception");
					HibernateUtil.rollbackTransaction();
				}
			} 
			catch (Throwable rbEx)
			{
				log.error("Could not rollback transaction after exception!", rbEx);
			}

			// Let others handle it... maybe another interceptor for exceptions?
			throw new ServletException(ex);
		} 
		finally
		{
			//SessionStatistics statistics = session.getStatistics();
		}
	}


	public void init(FilterConfig filterConfig) throws ServletException
	{
		log.debug("Initializing filter...");
	}


	public void destroy()
	{
	}


	public void setSessionFactory(SessionFactory sessionFactory)
	{
		this.sessionFactory = sessionFactory;
	}


	public SessionFactory getSessionFactory()
	{
		return sessionFactory;
	}
}
