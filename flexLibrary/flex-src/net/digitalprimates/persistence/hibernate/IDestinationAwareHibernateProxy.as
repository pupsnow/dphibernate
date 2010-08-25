package net.digitalprimates.persistence.hibernate
{
	public interface IDestinationAwareHibernateProxy extends IHibernateProxy
	{
		function get destinationName():String;
		function set destinationName(value:String):void;
	}
}