package com.mangofactory.pepper.controller.events
{
	import com.mangofactory.pepper.model.Comment;

	public class CommentUpdatedEvent
	{
		private var _comment:Comment;
		public function CommentUpdatedEvent(comment:Comment)
		{
			_comment = comment;
		}
		public function get comment():Comment
		{
			return _comment;
		}
	}
}