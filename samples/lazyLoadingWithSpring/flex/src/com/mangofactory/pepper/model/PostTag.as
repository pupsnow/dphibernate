package com.mangofactory.pepper.model
{

	[RemoteClass(alias="com.mangofactory.pepper.model.PostTag")]
	[Managed]
	public class PostTag extends BaseEntity
	{
		public var post:Post;
		public var tag:String;
		public function PostTag():void
		{
			super();
		}

	}

}