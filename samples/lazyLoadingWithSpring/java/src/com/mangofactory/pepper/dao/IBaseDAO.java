package com.mangofactory.pepper.dao;

import java.io.Serializable;
import java.util.Collection;
import java.util.List;

import org.hibernate.Session;
import org.hibernate.criterion.Criterion;

/**
 * Generic DAO pattern,
 * based off the article at http://www.ibm.com/developerworks/java/library/j-genericdao.html
 * @author Marty Pitt
 *
 */
public interface IBaseDAO <T, PK extends Serializable> {

    /** Persist the newInstance object into database */
    PK create(T newInstance);

    /** Retrieve an object that was previously persisted to the database using
     *   the indicated id as primary key
     */
    T get(PK id);

    /** Save changes made to a persistent object.  */
    void update(T transientObject);

    /** Remove an object from persistent storage in the database */
    void delete(T persistentObject);
    
    public List<T> findByCriterion(Criterion... criterions);
    public List<T> findByCriterion(List<Criterion> criterions);
    
    public T findUniqueByCriterion(Criterion... criterions);
    
    public List<T> getAll();
    
    public T merge(T entity);
    
    public Session getSession();
    
    public void updateAll(Collection<T> objects);
    public void mergeAll(Collection<T> objects);
}
