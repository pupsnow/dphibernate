package com.mangofactory.pepper.model
{

	[RemoteClass(alias="com.mangofactory.pepper.model.Comment")]
	[Managed]
	public class Comment extends BaseEntity
	{
		public var post:Post;
		public var user:User;
		public var creationDate:Date;
		public var text:String;

		/* Constructor */
		public function Comment():void
		{
			super();
		}
		[Transient]
		public var editable:Boolean;
		
		

	}

}