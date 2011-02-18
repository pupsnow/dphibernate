package com.mangofactory.pepper.view
{
	import com.mangofactory.pepper.model.Post;
	
	import flash.events.Event;

	public class ShowPostEvent extends Event
	{
		public static const SHOW_POST:String = "showPost";
		public function ShowPostEvent(post:Post)
		{
			super(SHOW_POST,true);
			_post = post;
		}
		private var _post:Post;
		public function get post():Post
		{
			return _post;
		}
	}
}