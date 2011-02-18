package com.mangofactory.pepper.service;

import java.util.List;

import javax.annotation.Resource;

import org.dphibernate.services.SpringLazyLoadService;
import org.hibernate.SessionFactory;
import org.springframework.context.ApplicationContext;
import org.springframework.flex.remoting.RemotingDestination;
import org.springframework.stereotype.Service;

import com.mangofactory.pepper.dao.IPostDAO;
import com.mangofactory.pepper.model.Post;

@Service
@RemotingDestination
public class DataService extends SpringLazyLoadService {

	public DataService(SessionFactory sessionFactory,
			ApplicationContext applicationContext) {
		super(sessionFactory, applicationContext);
	}

	@Resource
	private IPostDAO postDAO;
	
	public List<Post> getRecentPosts()
	{
		List<Post> recentPosts = postDAO.getRecentPosts();
		return recentPosts;
	}
}
