package com.mangofactory.pepper.model;

import java.io.Serializable;

import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.MappedSuperclass;
import javax.persistence.TableGenerator;
import javax.persistence.Transient;

import org.dphibernate.core.IHibernateProxy;
@MappedSuperclass
public class BaseEntity implements Serializable, IHibernateProxy  {

	@Id
	@TableGenerator(name="tg", table="pk_table",
			pkColumnName="name", valueColumnName="value", initialValue=1000,
			allocationSize=20
			)
	@GeneratedValue(strategy=GenerationType.AUTO)
	private Integer id;
	
	@Transient
	private Boolean proxyInitialized = true;
	
	public Integer getId()
	{
		return id;
	}
	public void setId(Integer id)
	{
		this.id = id;
	}
	@Override
	public Boolean getProxyInitialized() {
		return proxyInitialized;
	}
	@Override
	public Object getProxyKey() {
		return id;
	}
	@Override
	public void setProxyInitialized(Boolean arg0) {
		proxyInitialized = arg0;
	}
	@Override
	public int hashCode() {
		final int prime = 31;
		int result = 1;
		result = prime * result + ((id == null) ? 0 : id.hashCode());
		return result;
	}
	@Override
	public boolean equals(Object obj) {
		if (this == obj)
			return true;
		if (obj == null)
			return false;
		if (getClass() != obj.getClass())
			return false;
		BaseEntity other = (BaseEntity) obj;
		if (id == null) {
			if (other.id != null)
				return false;
		} else if (!id.equals(other.id))
			return false;
		return true;
	}
	@Override
	public void setProxyKey(Object arg0) {
		throw new RuntimeException("ProxyKey is read only!");
	}
}
