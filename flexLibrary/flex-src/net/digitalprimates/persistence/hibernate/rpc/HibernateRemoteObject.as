/**
   Copyright (c) 2008. Digital Primates IT Consulting Group
   http://www.digitalprimates.net
   All rights reserved.

   This library is free software; you can redistribute it and/or modify it under the
   terms of the GNU Lesser General Public License as published by the Free Software
   Foundation; either version 2.1 of the License.

   This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
   without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
   See the GNU Lesser General Public License for more details.


   @author: malabriola
   @ignore
 **/

package net.digitalprimates.persistence.hibernate.rpc
{
    import flash.utils.*;
    
    import mx.core.mx_internal;
    import mx.logging.ILogger;
    import mx.rpc.AbstractOperation;
    import mx.rpc.AsyncToken;
    import mx.rpc.Responder;
    import mx.rpc.events.FaultEvent;
    import mx.rpc.events.ResultEvent;
    import mx.rpc.remoting.mxml.RemoteObject;
    
    import net.digitalprimates.persistence.hibernate.ClassUtils;
    import net.digitalprimates.persistence.hibernate.HibernateManaged;
    import net.digitalprimates.persistence.hibernate.IHibernateProxy;
    import net.digitalprimates.persistence.hibernate.IHibernateRPC;
    import net.digitalprimates.util.LogUtil;

    use namespace flash_proxy;
    use namespace mx_internal;

    use namespace flash_proxy;

    dynamic public class HibernateRemoteObject extends RemoteObject implements IHibernateRPC
    {
		private var log : ILogger = LogUtil.getLogger( this );
		private var loadingProxies:Object = new Object();
		
		public var operationBufferFactory:IOperationBufferFactory;
		
		/**
		 * A method which is invoked after the operation has been
		 * constructed.  Allows for modifying an operation, before
		 * it's used for anything.
		 * Useful for testing.
		 * 
		 * Method must be of type:
		 * function(operation:Operation):void {}
		 * */
		internal var operationPostConstructDecorator:Function;
		
        public function HibernateRemoteObject(destination:String = null,operationBufferFactory:IOperationBufferFactory=null)
        {
            super(destination);
//			requestBuffer = new LoadProxyRequestBuffer(this,50,350);
			this.operationBufferFactory = operationBufferFactory;
        }
		
		override public function getOperation(name:String):AbstractOperation
		{
			var operation:AbstractOperation = super.getOperation(name);
			bufferOperation(operation);
			if (operationPostConstructDecorator != null)
			{
				operationPostConstructDecorator(operation);
			}
			return operation;
		}

		private function bufferOperation(operation:AbstractOperation):void
		{
			if (!operationBufferFactory)
				return;

			var buffer:IOperationBuffer = operationBufferFactory.getBuffer(this,operation);
			if (buffer)
			{
				operation.operationManager = buffer.bufferedSend;
			}
		}


        public function loadProxy(proxyKey:Object, hibernateProxy:IHibernateProxy):AsyncToken
        {
        	var className : String =  getQualifiedClassName( hibernateProxy );
			var qualifiedProxyKey:String = getQualifiedProxyKey(className,proxyKey);
			if (isProxyLoading(qualifiedProxyKey))
			{
				return getTokenForLoadingProxy(qualifiedProxyKey);
			}
			
        	log.info( "Reuqesting proxy for {0} id: {1}" , className , proxyKey );
        	var remoteClassName : String = ClassUtils.getRemoteClassName( hibernateProxy );
            var token : AsyncToken = this.loadDPProxy(proxyKey, remoteClassName);
			token.addResponder(new Responder(onProxyLoadComplete,onProxyLoadFault));
			setProxyLoading(qualifiedProxyKey,token);
			token.qualifiedProxyKey = qualifiedProxyKey;
			return token;
        }
		private function getQualifiedProxyKey(className:String,proxyKey:Object):String
		{
			return className + proxyKey.toString();
		}
		private function isProxyLoading(qualifiedProxyKey:String):Boolean
		{
			return loadingProxies.hasOwnProperty(qualifiedProxyKey);
		}
		private function setProxyLoading(qualifiedProxyKey:String,token:AsyncToken):void
		{
			loadingProxies[qualifiedProxyKey] = token;
		}
		private function setProxyLoaded(qualifiedProxyKey:String):void
		{
			delete loadingProxies[qualifiedProxyKey];
		}
		private function getTokenForLoadingProxy(qualifiedProxyKey:String):AsyncToken
		{
			return loadingProxies[qualifiedProxyKey] as AsyncToken;
		}
		public function saveProxy( hibernateProxy : IHibernateProxy , objectChangeMessages : Array ) : AsyncToken
		{
			var className : String = getQualifiedClassName( hibernateProxy );
			log.info( "Saving {0} {1}" , className , hibernateProxy.proxyKey );
			return this.saveDPProxy( objectChangeMessages );
		}
        override flash_proxy function callProperty(name:*, ... args:Array):*
        {
            var token:AsyncToken;

            HibernateManaged.disableServerCalls(this);
            token = getOperation(getLocalName(name)).send.apply(null, args);

            HibernateManaged.addHibernateResponder(this, token);
            HibernateManaged.enableServerCalls(this);

            return token;
        }
		
		private var _stateTrackingEnabled : Boolean = false;
		public function get stateTrackingEnabled() : Boolean
		{
			return _stateTrackingEnabled;
		}
		public function set stateTrackingEnabled( value : Boolean ) : void
		{
			_stateTrackingEnabled = value;
		}
		private function onProxyLoadComplete(event:ResultEvent):void
		{
			var key:String = event.token.qualifiedProxyKey;
			setProxyLoaded(key);
		}
		private function onProxyLoadFault(fault:FaultEvent):void
		{
			var key:String = fault.token.qualifiedProxyKey;
			setProxyLoaded(key);
		}
    }
}
