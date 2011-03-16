package org.dphibernate
{
	import org.dphibernate.core.IHibernateProxy;

	public function proxyDescriptorMatchingEntity(entity:IHibernateProxy):ProxyDescriptorForEntityMatcher
	{
		return new ProxyDescriptorForEntityMatcher(entity);
	}
}