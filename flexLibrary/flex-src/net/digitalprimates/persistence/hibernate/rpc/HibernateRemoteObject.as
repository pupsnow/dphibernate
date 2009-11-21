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
    import mx.rpc.AsyncToken;
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
		
        public function HibernateRemoteObject(destination:String = null)
        {
            super(destination);
        }

        public function loadProxy(proxyKey:Object, hibernateProxy:IHibernateProxy):AsyncToken
        {
        	var className : String =  getQualifiedClassName( hibernateProxy ) 
        	log.info( "Reuqesting proxy for {0} id: {1}" , className , proxyKey );
        	var remoteClassName : String = ClassUtils.getRemoteClassName( hibernateProxy );
            return this.loadDPProxy(proxyKey, remoteClassName);
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
    }
}
