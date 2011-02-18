package com.mangofactory.pepper.model.util
{
	import com.mangofactory.pepper.model.User;
	
	import mx.utils.StringUtil;

	public class GravatarUtil
	{
		public function GravatarUtil()
		{
		}
		
		public static function getGravatarURL(emailHash:String):String
		{
			var url:String = StringUtil.substitute("http://www.gravatar.com/avatar/{0}.jpg?d=identicon",emailHash);
			return url;
		}
	}
}