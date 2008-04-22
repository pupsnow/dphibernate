package services.hibernate
{
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	
	import net.digitalprimates.persistence.hibernate.rpc.HibernateRemoteObject;
	
	import services.ISupportService;
	
	import support.SupportCase;
	
	public class SupportServiceHib implements ISupportService
	{
		private var responder:IResponder;
		private var service:HibernateRemoteObject;
		
		public function SupportServiceHib(resp_:IResponder, service_:HibernateRemoteObject)
		{
			this.responder = resp_;
			this.service = service_;
		}


		public function getAllConsultants():AsyncToken
		{
			var asyncToken:AsyncToken = this.service.getAllConsultants();
				asyncToken.addResponder( responder );
			
			return asyncToken;
		}
		
		
		public function saveSupportCase(case_:SupportCase):AsyncToken
		{
			var asyncToken:AsyncToken = this.service.saveSupportCase(case_);
				asyncToken.addResponder( responder );
			
			return asyncToken;
		}
	}
}