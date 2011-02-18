package com.mangofactory.pepper.dao;

import java.io.Serializable;
import java.util.Arrays;
import java.util.Collection;
import java.util.List;

import org.hibernate.Criteria;
import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.criterion.Criterion;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

/**
 * Generic DAO pattern,
 * based off the article at http://www.ibm.com/developerworks/java/library/j-genericdao.html
 * @author Marty Pitt
 *
 */
@Transactional(readOnly=true)
public class BaseDAO<T, PK extends Serializable> implements IBaseDAO<T, PK> {
	private Class<T> type;
	
	@Autowired(required=true)
	private SessionFactory sessionFactory;
	
	public BaseDAO(Class<T> type, SessionFactory sessionFactory)
	{
		this.type = type;
		this.setSessionFactory(sessionFactory);
	}
	public BaseDAO(Class<T> type)
	{
		this.type = type;
	}
	
	@SuppressWarnings("unchecked")
	@Override
	@Transactional(readOnly=false)
	public PK create(T newInstance) {
		return (PK) getSession().save(newInstance);
	}

	@Override
	@Transactional(readOnly=false)
	public void delete(T entity) {
		getSession().delete(entity);
		
	}

	@SuppressWarnings("unchecked")
	@Override
	public T get(PK id) {
		return (T) getSession().get(type, id);
	}

	@Override
	public void update(T entity) {
		getSession().update(entity);
	}
	
	@SuppressWarnings("unchecked")
	@Override
	public T merge(T entity)
	{
		return (T) getSession().merge(entity);
	}

	@SuppressWarnings("unchecked")
	public T findUniqueByCriterion(Criterion... criterions)
	{
		Criteria criteria = createCriteria(criterions);
		return (T) criteria.uniqueResult();
	}
	@SuppressWarnings("unchecked")
	public T findUniqueByCriterion(List<Criterion> criterions)
	{
		Criteria criteria = createCriteria(criterions);
		return (T) criteria.uniqueResult();
	}
	@Override
	@SuppressWarnings("unchecked")
	public List<T> findByCriterion(Criterion... criterions)
	{
		Criteria criteria = createCriteria(criterions);
		return (List<T>) criteria.list();
	}
	@Override
	@SuppressWarnings("unchecked")
	public List<T> findByCriterion(List<Criterion> criterions)
	{
		Criteria criteria = createCriteria(criterions);
		return (List<T>) criteria.list();
	}
	protected Criteria createCriteria()
	{
		return getSession().createCriteria(type);
	}
	protected Criteria createCriteria(Criterion... criterions)
	{
		List<Criterion> list = Arrays.asList(criterions);
		return createCriteria(list);
	}
	protected Criteria createCriteria(List<Criterion> criterions)
	{
		Criteria criteria = getSession().createCriteria(type);
		for (Criterion criterion : criterions)
		{
			criteria.add(criterion);
		}
		return criteria;
	}
	
	protected List<?> getForQuery(String query)
	{
		return getSession().createQuery(query).list();
	}
	@SuppressWarnings("unchecked")
	public List<T> getAll()
	{
		Criteria criteria = createCriteria(new Criterion[]{});
		return (List<T>) criteria.list();
	}
	public Session getSession()
	{
		return getSessionFactory().getCurrentSession();
	}
	public void evictList(List source)
	{
		for(Object obj : source)
		{
			getSession().evict(obj);
		}
	}
	@Override
	public void mergeAll(Collection<T> objects) {
		for (T obj:objects)
		{
			merge(obj);
		}
	}
	@Override
	public void updateAll(Collection<T> objects) {
		for (T obj:objects)
		{
			update(obj);
		}
	}
	public void setSessionFactory(SessionFactory sessionFactory) {
		this.sessionFactory = sessionFactory;
	}
	public SessionFactory getSessionFactory() {
		return sessionFactory;
	}
}
