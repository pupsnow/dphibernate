package com.mangofactory.pepper.model
{
	import mx.collections.ArrayCollection;

	[RemoteClass(alias="com.mangofactory.pepper.model.User")]
	[Managed]
	public class User extends BaseEntity
	{
		public var aboutMe:String;
		public var age:int;
		public var creationDate:Date;
		public var displayName:String;
		public var emailHash:String;
		public var reputation:int;
		public var badges:ArrayCollection;
		public var posts:ArrayCollection;
		public var location:String;
		/* Constructor */
		public function User():void
		{
			super();
		}
	}

}