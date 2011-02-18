package com.mangofactory.pepper.model
{

	[Managed]
	[RemoteClass(alias="com.mangofactory.pepper.model.Badge")]
	public class Badge extends BaseEntity
	{
		public var user:User;
		public var name:String;
		public var date:Date;
		
		public function Badge():void
		{
			super();
		}

	}

}