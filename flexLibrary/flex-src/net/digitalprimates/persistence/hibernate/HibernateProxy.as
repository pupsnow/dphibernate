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


package net.digitalprimates.persistence.hibernate
{
	import flash.utils.flash_proxy;
	
	import mx.rpc.AsyncToken;
	import mx.utils.ObjectProxy;
	import mx.utils.object_proxy;

	use namespace flash_proxy; 
	use namespace object_proxy;
	
	[RemoteClass(alias="net.digitalprimates.persistence.hibernate.proxy.HibernateProxy")]

	dynamic public class HibernateProxy extends ObjectProxy
	{
		public var owner:IHibernateProxy;

	    flash_proxy override function getProperty(name:*):* {
			var ro:IHibernateRPC;
			ro = HibernateManaged.getIHibernateRPC( this );

	    	if ( HibernateManaged.areServerCallsEnabled( ro ) ) {
		    	if ( ( name != 'proxyKey' ) &&  ( name != 'proxyInitialized' ) && ( name != 'pending' ) ) {
			    	if ( ( object[ name ] is IHibernateProxy ) && ( !object[ name ].proxyInitialized ) && ( !object[ name ].pending ) ) {
			    		object[ name ].pending = true;
			    		return HibernateManaged.getProperty( owner, name, object[ name ] );
			    	} else if  ( !object.proxyInitialized && !object.pending ) {
			    		object.pending = true;
			    		return HibernateManaged.getProperty( owner, null, object );
			    	} 
			    }
	    	}

	    	return object[ name ];
	    }
	    
	    public function HibernateProxy( owner:Object ) {
	    	this.owner = owner as IHibernateProxy;
	    }
	}
}