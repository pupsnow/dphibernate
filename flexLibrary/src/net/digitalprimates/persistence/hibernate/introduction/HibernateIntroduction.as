package net.digitalprimates.persistence.hibernate.introduction {
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;

	public class HibernateIntroduction {

		public var uid:String;
		public var comStatus:uint = 0;

		private var _proxyKey:Object;
		private var _proxyInitialized:Boolean = true;

		private var _manager:IEntityManager;
		
		public function get proxyKey():Object
		{
			return _proxyKey;
		}

		public function set proxyKey(value:Object):void
		{
			_proxyKey = value;
		}

		public function get proxyInitialized():Boolean
		{
			return _proxyInitialized;
		}

		public function set proxyInitialized(value:Boolean):void
		{
			_proxyInitialized = value;
		}

		public function get manager():IEntityManager {
			return _manager;
		}

		public function set manager(value:IEntityManager):void {
			_manager = value;
		}

/*		public function save():AsyncToken {
			return null;
		}*/

		public function HibernateIntroduction() {
			super();
		}
	}
}