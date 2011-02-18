package com.mangofactory.pepper.dao;

import com.mangofactory.pepper.model.BaseEntity;

/**
 * Generic DAO pattern,
 * based off the article at http://www.ibm.com/developerworks/java/library/j-genericdao.html
 * @author Marty Pitt
 *
 */
public interface IEntityDAO<T extends BaseEntity> extends IBaseDAO<T, Integer> {

}