package com.mangofactory.pepper.controller.events
{
	import com.mangofactory.pepper.model.ApplicationUser;

	public class UserChangedEvent
	{
		private var _user:ApplicationUser;
		
		public function UserChangedEvent(user:ApplicationUser)
		{
			this._user = user;
		}
		public function get user():ApplicationUser
		{
			return _user;
		}
	}
}
