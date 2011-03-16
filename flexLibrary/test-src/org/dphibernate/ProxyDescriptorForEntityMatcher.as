package org.dphibernate
{
	import org.dphibernate.core.IHibernateProxy;
	import org.dphibernate.persistence.state.IHibernateProxyDescriptor;
	import org.dphibernate.util.ClassUtils;
	import org.dphibernate.util.PropertyHelper;
	import org.hamcrest.BaseMatcher;
	import org.hamcrest.Matcher;
	
	public class ProxyDescriptorForEntityMatcher extends BaseMatcher implements Matcher
	{
		private var entity:IHibernateProxy;
		public function ProxyDescriptorForEntityMatcher(expectedEntity:IHibernateProxy)
		{
			this.entity = expectedEntity;
		}
		public override function matches(item:Object):Boolean
		{
			var descriptor:IHibernateProxyDescriptor = IHibernateProxyDescriptor(item);
			return (descriptor.proxyId == entity.proxyKey)
					&& (ClassUtils.getRemoteClassName(entity) == descriptor.remoteClassName);
		}


	}
}