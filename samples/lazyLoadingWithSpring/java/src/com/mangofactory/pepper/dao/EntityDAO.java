package com.mangofactory.pepper.dao;

import org.hibernate.SessionFactory;

import com.mangofactory.pepper.model.BaseEntity;

public class EntityDAO<T extends BaseEntity> extends BaseDAO<T, Integer> implements IEntityDAO<T> {

	public EntityDAO(Class<T> type) {
		super(type);
	}
	public EntityDAO(Class<T> type,SessionFactory sessionFactory) {
		super(type,sessionFactory);
	}
	@Override
	public void update(T entity) {
		if (entity.getId() == null)
		{
			super.create(entity);
		} else {
			super.update(entity);
		}
	}

}
