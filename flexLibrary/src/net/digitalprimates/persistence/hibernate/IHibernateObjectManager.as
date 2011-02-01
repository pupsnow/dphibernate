package net.digitalprimates.persistence.hibernate {
	public interface IHibernateObjectManager {
		function getProperty(obj:*, property:String ):*;
		function setProperty(obj:*, property:Object, oldValue:*, newValue:*, parent:Object=null, parentProperty:String=null ):void;
	}
}