package net.digitalprimates.persistence.state
{
//	import com.inversion.util.Stopwatch;
	
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import net.digitalprimates.persistence.hibernate.HibernateManaged;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	import net.digitalprimates.util.LogUtil;
	
	public class HibernateUpdater
	{
		private static const log : ILogger = LogUtil.getLogger( HibernateUpdater );
		public function HibernateUpdater()
		{
		}
		
		public static function save( object : IHibernateProxy , responder : IResponder = null ) : AsyncToken
		{
//			var stopwatch : Stopwatch = new Stopwatch();
//			stopwatch.start("HibenrateUpdater.save");
			var ro : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( object );
			if ( !ro )
			{
				ro = HibernateManaged.defaultHibernateService;
			}
			var generator : ChangeMessageGenerator = new ChangeMessageGenerator();
			
			var changes : Array = generator.getChanges( object );
//			log.info( "ChangeMessageFactory.getChanges completed in {0}ms" , stopwatch.getTimeInMilliSeconds() );
			var token : AsyncToken = ro.saveProxy( object , changes );
			token.ro = ro;
			token.obj = object;
			token.addResponder( new Responder( saveCompleted , saveFailed ) );
			if ( responder )
			{
				token.addResponder( responder );
			}
			StateRepository.saveStarted( object );
//			stopwatch.stop();
//			log.info( "Save process passed to server in {0}ms" , stopwatch.getTimeInMilliSeconds() );
			return token;
		}
		
		internal static function saveCompleted( event : ResultEvent )  : void
		{
			// TODO : We could modify the reuslt of the 
			// remote operation to return a list of properties
			// successfully updated and individually update them.
			// It would be a more fine-grained approach.
			var obj : IHibernateProxy = event.token.obj;
			log.info( "save operation completed on {0}" , StateRepository.getKey( obj ) )
			StateRepository.saveCompleted( obj );
			var parentRO : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( obj );
			var result : ArrayCollection = event.result as ArrayCollection
			for each ( var changeResult : ObjectChangeResult in result )
			{
				// TODO : Need to encapsulate this key generation
				var oldKey : String = changeResult.remoteClassName + "::" + changeResult.oldId;
				var proxy : IHibernateProxy = StateRepository.getStoredObject( oldKey );
				if ( proxy )
				{
					proxy.proxyKey = changeResult.newId;
					var newKey : String = StateRepository.getKey( proxy );
					StateRepository.updateKey( oldKey , newKey , proxy );
					StateRepository.saveCompleted( proxy );
				} else {
					log.error( "Cannot find proxy in StoreRepository with key {0} to update.  (New id from save operation is {1})",oldKey,changeResult.newId);
				}
				
			}
			
		}
		internal static function saveFailed( event : FaultEvent ) : void
		{
			trace("Save Failed");
		}
		
		public static function deleteRecord( object : IHibernateProxy , responder:IResponder = null) : AsyncToken
		{
			var descriptor : HibernateProxyDescriptor = new HibernateProxyDescriptor( object );
			var changes : Array = [ ObjectChangeMessage.createDeleted( descriptor ) ];
			var ro : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( object );
			var token : AsyncToken = ro.saveProxy( object , changes );
			token.addResponder( new Responder( deleteCompleted , deleteFailed ) );
			if ( responder )
			{
				token.addResponder(responder);
			}
			token.obj = object;
			return token;
		}
		internal static function deleteCompleted( event : ResultEvent ) : void
		{
			var source : IHibernateProxy = event.token.obj as IHibernateProxy;
			StateRepository.removeFromStore( source );
		}
		internal static function deleteFailed( event : FaultEvent ) : void
		{
			trace("Delete failed : " + event.fault.faultString );
		}
	}
}