package net.digitalprimates.persistence.translators;

import net.digitalprimates.persistence.hibernate.utils.HibernateUtil;

import org.hibernate.SessionFactory;

/**
 * Serializer factory which is configured for use with Hibernate Annotations / JPA.
 * @author owner
 *
 */
public class AnnotationSerializerFactory extends SimpleSerializationFactory
{

	@Override
	protected SessionFactory getSessionFactory()
	{
		return HibernateUtil.getSessionFactory();
	}


}
