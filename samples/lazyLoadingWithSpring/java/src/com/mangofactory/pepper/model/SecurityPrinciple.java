package com.mangofactory.pepper.model;

import java.util.Arrays;
import java.util.List;

import javax.persistence.Column;

import org.dphibernate.serialization.annotations.EagerlySerialize;

@EagerlySerialize
public class SecurityPrinciple extends BaseEntity {
	private static final String ADMINISTRATOR_NAME = "ADMINISTRATOR";
	private static final String USER_NAME = "USER";
	private static final List<String> PRINCIPLES = Arrays.asList(ADMINISTRATOR_NAME,USER_NAME);
	
	public static final SecurityPrinciple USER = new SecurityPrinciple(1, USER_NAME);
	public static final SecurityPrinciple ADMINISTRATOR = new SecurityPrinciple(2, ADMINISTRATOR_NAME);
	
	// Param-less constructor for Blaze & Hibernate
	public SecurityPrinciple()
	{
	}
	private SecurityPrinciple(Integer id,String name)
	{
		setId(id);
		setName(name);
	}
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = super.hashCode();
		result = prime * result + ((name == null) ? 0 : name.hashCode());
		return result;
	}

	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (!super.equals(obj))
			return false;
		if (getClass() != obj.getClass())
			return false;
		SecurityPrinciple other = (SecurityPrinciple) obj;
		if (name == null) {
			if (other.name != null)
				return false;
		} else if (!name.equals(other.name))
			return false;
		return true;
	}

	@Column(unique=true)
	private String name;

	public void setName(String name) {
		if (!isValidSecurityPrinciple(name)){
			throw new IllegalArgumentException("Invalid security principle");
		}
		this.name = name;
	}
	private boolean isValidSecurityPrinciple(String name)
	{
		return (PRINCIPLES.contains(name));
	}
	public String getName() {
		return name;
	}
}
