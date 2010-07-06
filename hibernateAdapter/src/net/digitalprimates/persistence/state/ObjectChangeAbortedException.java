package net.digitalprimates.persistence.state;

public class ObjectChangeAbortedException extends RuntimeException
{
	public ObjectChangeAbortedException()
	{
		super();
	}
	public ObjectChangeAbortedException(String message)
	{
		super(message);
	}
}
