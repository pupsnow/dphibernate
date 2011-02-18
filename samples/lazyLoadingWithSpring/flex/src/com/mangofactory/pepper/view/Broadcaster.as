package com.mangofactory.pepper.view
{
	import flash.events.EventDispatcher;

	public class Broadcaster extends EventDispatcher
	{
		[MessageDispatcher]
		public var broadcast:Function;
	}
}