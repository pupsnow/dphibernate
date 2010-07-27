package net.digitalprimates.dphibernate.model;

import net.digitalprimates.persistence.annotations.NeverSerialize;

public class User
{
	private final String username;
	private final String password;

	public User(String username,String password)
	{
		this.username = username;
		this.password = password;
		
	}

	public String getUsername()
	{
		return username;
	}
	@NeverSerialize
	public String getPassword()
	{
		return password;
	}
}
