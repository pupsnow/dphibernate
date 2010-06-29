package net.digitalprimates.persistence.hibernate.utils.services;

import java.io.Serializable;

public interface IProxyLoadService
{
	Object loadBean(Class daoClass, Serializable id);
}
