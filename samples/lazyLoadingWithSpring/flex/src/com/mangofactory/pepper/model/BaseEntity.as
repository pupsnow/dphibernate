package com.mangofactory.pepper.model
{
	import flash.events.EventDispatcher;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import org.dphibernate.core.HibernateBean;
	import org.dphibernate.core.IHibernateProxy;
	import org.dphibernate.core.IUpdatableHibernateProxy;
	import org.dphibernate.persistence.state.HibernateUpdater;
	import org.dphibernate.persistence.state.StateRepository;
	import org.spicefactory.lib.reflect.ClassInfo;

	/**
	 * This is the base entity. 
	 * Common dpHibernate functions are defined here, and made available to all other entities that subclass this.
	 * 
	 * Note, that you can either have your entity subclass HibernateBean, or alternatively, 
	 * implement IHibernateProxy, which we do here.
	 * 
	 * Because this class provides update methods (save,delete), it implements IUpdateableHibernateProxy, which
	 * extends IHibernateProxy.
	 * 
	 * It adds the methods save() and deleteRecord();
	 * 
	 * This class is not part of the dpHibernate project, but is a good example implementation of
	 * the IHibernateProxy and IUpdatableHibernateProxy interfaces.  
	 * 
	 * Feel free to use this class as a basis for Entity classes in your own projects.
	 * */
	[RemoteClass(alias="com.mangofactory.pepper.model.BaseEntity")]
	public class BaseEntity extends EventDispatcher implements IHibernateProxy
	{
		public var id:int;
		
		private var hibernateProxy:IHibernateProxy=new HibernateBean();

		/* Constructor */
		public function BaseEntity():void
		{
			super();
		}
		
		//==================================================
		// IHibernateProxy impl..
		//==================================================
		public function get proxyKey():Object
		{
			return hibernateProxy.proxyKey;
		}

		public function set proxyKey(value:Object):void
		{
			hibernateProxy.proxyKey=value;
		}

		public function get proxyInitialized():Boolean
		{
			return hibernateProxy.proxyInitialized;
		}

		public function set proxyInitialized(value:Boolean):void
		{
			hibernateProxy.proxyInitialized=value;
		}
		
		public function equals(other:BaseEntity):Boolean
		{
			if (!other) return false;
			
			if (ClassInfo.forInstance(other).getClass() != ClassInfo.forInstance(this).getClass())
				return false;
			return this.proxyKey == other.proxyKey;
		}
	}

}