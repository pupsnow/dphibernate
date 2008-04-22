package services
{
	import mx.messaging.*;
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.IResponder;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import net.digitalprimates.persistence.hibernate.rpc.HibernateRemoteObject;
	
	import services.hibernate.SupportServiceHib;

	
	public class ServiceFactory
	{
		public static const USE_STUB_DATA:Boolean = false;

		public var _flexChannelSet:ChannelSet;
		// cached services
		private static var _serviceFactory:ServiceFactory;
		private static var _supportService:HibernateRemoteObject;
		
						
		public static function getInstance():ServiceFactory 
		{
			if (_serviceFactory == null) {
				_serviceFactory = new ServiceFactory();	
			}			
			return _serviceFactory;
		}
		
		public function ServiceFactory() 
		{
 			var _flexChannel:Channel = new AMFChannel("my-amf", "http://localhost:8080/samples_peterEnt/messagebroker/amf");			
				_flexChannelSet = new ChannelSet();
				_flexChannelSet.addChannel(_flexChannel);
		}
		
		
		
		/**
		 * 
		 */
		public static function getSupportService(resp_:IResponder):ISupportService
		{
			
			if (!USE_STUB_DATA) 
			{
				if (_supportService == null) 
				{
					_supportService = new HibernateRemoteObject('supportService');				
					_supportService.channelSet = ServiceFactory.getInstance()._flexChannelSet;
					RemoteObject(_supportService).showBusyCursor = true;				
				}
				return new SupportServiceHib(resp_, _supportService);
			} else {
				return null;
				//var _stubService:StubDataService = new StubDataService();
				//return new SampleServiceLocal(resp_, _stubService);
			}
		}
				
	}
}