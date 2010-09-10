package net.digitalprimates.persistence.state.testObjects
{
	import net.digitalprimates.persistence.hibernate.HibernateBean;
	

	[Managed]
	[RemoteClass(alias="net.digitalprimates.persistence.hibernate.testObjects.Publisher")]
	public class Publisher extends HibernateBean
	{
		public function Publisher()
		{
		}
		public var name : String;
		public var address : String;
	}
}