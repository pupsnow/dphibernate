package net.digitalprimates.flex2.mx.utils
{
	import flash.utils.Dictionary;
	
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;

	public interface IBeanPopulator
	{
		function populateBean( genericObj:Object, 
												classDefinition:Class, 
												existingBean:Object=null, 
												dictionary:Dictionary=null,
												parent:Object=null,
												parentProperty:String=null, 
												ro:IHibernateRPC=null ):Object;	
	}
}