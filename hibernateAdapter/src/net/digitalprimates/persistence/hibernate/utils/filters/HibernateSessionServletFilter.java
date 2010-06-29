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
import org.hibernate.Transaction;
import org.hibernate.stat.SessionStatistics;


/**
 * Servlet Filter to open a close the Hibernate session for each request.
 * 
 * based on the servlet filter code: http://www.hibernate.org/43.html
 * 
 * @author mike nimer, Marty Pitt
 */
public class HibernateSessionServletFilter extends AbstractHibernateSessionServletFilter
{

	@Override
	public SessionFactory getSessionFactory()
	{
		SessionFactory sessionFactory = HibernateUtil.getSessionFactory();
		return sessionFactory;
	}

}
