package org.dphibernate.persistence.state.testObjects
{
	import mx.collections.ArrayCollection;
	
	import org.dphibernate.core.HibernateBean;
	
	
	[Managed]
	[RemoteClass(alias="net.digitalprimates.persistence.hibernate.testObjects.Author")]
	public class Author extends HibernateBean
	{
		public function Author()
		{
		}
		
		public var name : String;
		public var age : int;
		public var books : ArrayCollection = new ArrayCollection();
		public var publisher : Publisher;
		
		public static function withNameAndId(name:String,id:int):Author
		{
			var author:Author = new Author();
			author.name = name;
			author.proxyKey = id;
			return author;
		}
		
		public static function withName(name:String):Author
		{
			var author:Author = new Author();
			author.name = name;
			return author;
		}
	}
}