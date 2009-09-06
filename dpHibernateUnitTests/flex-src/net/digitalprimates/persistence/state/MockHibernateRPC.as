package net.digitalprimates.persistence.state
{
	import mx.rpc.AsyncToken;
	
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	
	import org.mock4as.Mock;

	public class MockHibernateRPC extends Mock implements IHibernateRPC
	{
		public function MockHibernateRPC()
		{
		}

		
		public function loadProxy(proxyKey:Object, hibernateProxy:IHibernateProxy):AsyncToken
		{
			record("loadProxy" , proxyKey , hibernateProxy );
			return expectedReturnFor( "loadProxy" ) as AsyncToken;
		}
		public function saveProxy( hibernateProxy : IHibernateProxy , objectChangeMessages : Array ) : AsyncToken
		{
			record("saveProxy" , hibernateProxy );
			return expectedReturnFor( "saveProxy" ) as AsyncToken;
		}
		
	}
}