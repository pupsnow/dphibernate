package net.digitalprimates.persistence.translators.hibernate;

class Publisher  extends BaseEntity
{
	private String name;
	private String address;
	public Publisher(){};
	public Publisher(String name, String address)
	{
		super();
		this.name = name;
		this.address = address;
	}
	public void setName(String name)
	{
		this.name = name;
	}
	public String getName()
	{
		return name;
	}
	public void setAddress(String address)
	{
		this.address = address;
	}
	public String getAddress()
	{
		return address;
	}
}
