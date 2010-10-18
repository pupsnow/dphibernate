package com.mangofactory.pepper.dao;

import java.util.List;

import com.mangofactory.pepper.model.Post;

public interface IPostDAO extends IEntityDAO<Post> {
	List<Post> getRecentPosts();
}
