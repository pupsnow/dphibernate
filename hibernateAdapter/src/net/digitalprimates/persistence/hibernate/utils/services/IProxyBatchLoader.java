package net.digitalprimates.persistence.hibernate.utils.services;

import java.util.List;

public interface IProxyBatchLoader
{
	 List<ProxyLoadResult> loadProxyBatch(ProxyLoadRequest[] requests);
}
