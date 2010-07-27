package net.digitalprimates.persistence.state
{
	import net.digitalprimates.persistence.hibernate.ClassUtils;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	
	[RemoteClass(alias="net.digitalprimates.persistence.state.HibernateProxyDescriptor")]	
	public class HibernateProxyDescriptor implements IHibernateProxyDescriptor
	{
		public function HibernateProxyDescriptor( source : IHibernateProxy )
		{
			_remoteClassName = ClassUtils.getRemoteClassName( source );
			_proxyId = source.proxyKey;
			_source = source;
		}
		private var _remoteClassName : String;
		public function get remoteClassName():String
		{
			return _remoteClassName;
		}
		public function set remoteClassName( value : String ) : void
		{
			_remoteClassName = value;
		}
		private var _proxyId:Object;
		public function get proxyId():Object
		{
			return _proxyId;
		}
		public function set proxyId( value : Object ) : void
		{
			_proxyId = value;
		}
		private var _source : IHibernateProxy;
		[Transient]
		public function get source() : IHibernateProxy
		{
			return _source;
		}
	}
}