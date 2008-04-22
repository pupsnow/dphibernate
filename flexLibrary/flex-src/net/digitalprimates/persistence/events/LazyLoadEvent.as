package net.digitalprimates.persistence.events
{
	import flash.events.Event;
	
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;

	public class LazyLoadEvent extends Event
	{
		public static const pending:String = "LazyLoadPending";
		public static const complete:String = "LazyLoadComplete";
		public static const failed:String = "LazyLoadFailed";
		//public var proxy:IHibernateProxy;

		public function LazyLoadEvent( type:String, bubbles:Boolean=false, cancelable:Boolean=false )
		{
			//this.proxy = proxy;
			super(type, bubbles, cancelable);
		}

		override public function clone():Event {
			return new LazyLoadEvent( type, bubbles, cancelable );
		}
	}
}