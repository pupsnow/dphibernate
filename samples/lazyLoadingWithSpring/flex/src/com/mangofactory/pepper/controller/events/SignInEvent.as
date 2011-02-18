package com.mangofactory.pepper.controller.events
{
	import com.mangofactory.pepper.model.ApplicationUser;

	public class SignInEvent
	{
		public function SignInEvent(user:ApplicationUser)
		{
			this._user = user;
		}
		private var _user:ApplicationUser;
		public function get user():ApplicationUser
		{
			return _user;
		}
	}
}