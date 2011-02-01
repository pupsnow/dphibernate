package net.digitalprimates.persistence.hibernate
{
	import flash.events.IEventDispatcher;
	
	import net.digitalprimates.persistence.entity.interceptor.EntityInterceptor;
	import net.digitalprimates.persistence.hibernate.loader.LazyLoadEvent;
	import net.digitalprimates.persistence.hibernate.loader.LazyLoader;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;

	public class HibernateObjectManagerImpl implements IHibernateObjectManager
	{
		public function HibernateObjectManagerImpl()
		{
		}
		
		public function getProperty(obj:*, property:String ):*
		{
			var entityManager:HibernateEntityManager = obj.manager as HibernateEntityManager;

			if ( !entityManager.serializing ) {
				entityManager.serializing = true;
				var lazyLoader:LazyLoader = new LazyLoader( obj.manager as HibernateEntityManager, obj, property );
				lazyLoader.load();
				entityManager.serializing = false;
	
				if ( obj is IEventDispatcher ) {
					IEventDispatcher( obj ).dispatchEvent( new LazyLoadEvent( LazyLoadEvent.PENDING, true, true ) );
				}
	
				//Set this to pending
				obj.comStatus |= HibernateConstants.PENDING;
			}

			return null;
		}
		
		public function setProperty(obj:*, property:Object, oldValue:*, newValue:*, parent:Object=null, parentProperty:String=null):void
		{
		}
	}
}