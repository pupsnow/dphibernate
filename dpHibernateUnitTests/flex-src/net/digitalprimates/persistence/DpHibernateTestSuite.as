package net.digitalprimates.persistence
{
	import net.digitalprimates.persistence.state.HibernateUpdaterTests;
	import net.digitalprimates.persistence.state.StateRepositoryTests;
	import net.digitalprimates.persistence.hibernate.rpc.LoadProxyRequestBufferTests;

	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class DpHibernateTestSuite
	{
//		public var stateRepositoryTests:StateRepositoryTests;
//		public var hibernateUpdaterTests:HibernateUpdaterTests;
		public var loadBuffer:LoadProxyRequestBufferTests;
	}
}