package com.mangofactory.pepper.model
{
	import mx.collections.ArrayCollection;

	[Managed]
	[RemoteClass(alias="com.mangofactory.pepper.model.Post")]
	public class Post extends BaseEntity
	{
		public var author:User;
		public var parent:Post;
		public var authorDisplayName:String;
		public var creationDate:Date;
		public var postTags:ArrayCollection;
		public var replies:ArrayCollection;
		public var title:String;
		public var body:String;
		public var answerCount:int;
		public var comments:ArrayCollection;
		public var lastEditorDisplayName:String;
		public var lastEditor:User;
		
		public function Post():void
		{
			super();
		}
		
		public function addComment(comment:Comment):void
		{
			if (!comments)
			{
				comments = new ArrayCollection();
			}
			ArrayCollection(comments).addItem(comment);
			comment.post = this;
		}
		public function removeComment(comment:Comment):void
		{
			if (!comments) return;
			var index:int = ArrayCollection(comments).getItemIndex(comment);
			if ( index == -1 ) return;
			ArrayCollection(comments).removeItemAt(index);
			comment.post = null;
		}
	}

}