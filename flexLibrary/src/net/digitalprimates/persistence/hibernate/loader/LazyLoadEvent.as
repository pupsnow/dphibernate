package net.digitalprimates.persistence.hibernate.loader
{
	import flash.events.Event;
	
	public class LazyLoadEvent extends Event
	{
		public static const PENDING:String = "pending";
		public function LazyLoadEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}