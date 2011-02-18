package com.mangofactory.pepper.controller.events
{
	import com.mangofactory.pepper.model.Comment;
	
	import flash.events.Event;

	public class DeleteCommentEvent extends Event
	{
		public static const DELETE_COMMENT:String = "deleteComment";
		private var _comment:Comment;
		public function DeleteCommentEvent(comment:Comment)
		{
			super(DELETE_COMMENT,true);
			this._comment = comment;
		}
		public function get comment():Comment
		{
			return _comment;
		}
	}
}