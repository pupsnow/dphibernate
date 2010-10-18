package com.mangofactory.pepper.view
{
	import com.mangofactory.pepper.model.User;
	
	import flash.events.Event;

	public class ShowUserEvent extends Event
	{
		public static const SHOW_USER:String = "showUser";
		private var _user:User;
		public function ShowUserEvent(user:User)
		{
			super(SHOW_USER,true);
			this._user = user;
		}
		public function get user():User
		{
			return _user;
		}
	}
}