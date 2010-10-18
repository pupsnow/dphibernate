package com.mangofactory.pepper.dao;

import java.util.List;

import org.hibernate.Criteria;
import org.hibernate.criterion.Order;
import org.hibernate.criterion.Restrictions;

import com.mangofactory.pepper.model.Post;

public class PostDAO extends EntityDAO<Post>implements IPostDAO {

	public PostDAO()
	{
		super(Post.class);
	}
	@Override
	public List<Post> getRecentPosts() {
		Criteria recentPostsCriteria = createCriteria(Restrictions.isNull("parent")).addOrder(Order.desc("creationDate")).setMaxResults(100);
		return recentPostsCriteria.list();
	}
}
