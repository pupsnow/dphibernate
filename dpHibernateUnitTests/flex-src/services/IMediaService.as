package services
{
	import mx.rpc.AsyncToken;
	
	import support.SupportCase;
	
	public interface IMediaService
	{
		function getAllConsultants():AsyncToken;
		function saveSupportCase(case_:SupportCase):AsyncToken;
	}
}