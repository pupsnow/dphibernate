package net.digitalprimates.persistence.hibernate.loader.stub
{
	import flash.events.EventDispatcher;
	
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.IHibernateManagedEntity;
	import net.digitalprimates.persistence.hibernate.manager.IHibernateEntityManager;
	
	[RemoteClass(alias="net.digitalprimates.persistence.hibernate.loader.stub.SampleEntity")]
	public class SampleDispatchingEntity extends EventDispatcher implements IHibernateManagedEntity
	{
		public function SampleDispatchingEntity()
		{
		}
		
		public function get testABC():String {
			return null;
		}
		
		public function set testABC( value:String ):void {
			
		}
		
		public function get manager():IHibernateEntityManager
		{
			return null;
		}
		
		public function set manager(value:IHibernateEntityManager):void
		{
		}
		
		public function get proxyKey():Object
		{
			return null;
		}
		
		public function set proxyKey(value:Object):void
		{
		}
		
		public function get proxyInitialized():Boolean
		{
			return false;
		}
		
		public function set proxyInitialized(value:Boolean):void
		{
		}
		
		public function get comStatus():uint
		{
			return 0;
		}
		
		public function set comStatus(value:uint):void
		{
		}
	}
}