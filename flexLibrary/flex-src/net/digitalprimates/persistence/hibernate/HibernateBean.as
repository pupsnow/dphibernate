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
	import mx.rpc.AsyncToken;
	
	import net.digitalprimates.persistence.state.HibernateUpdater;
	import net.digitalprimates.persistence.state.StateRepository;
	
	public class HibernateBean implements IHibernateProxy 
	{
		private var __proxyKey:Object = StateRepository.getKeyForNewObject();
		private var __proxyInitialized:Boolean = true;

		public function get proxyKey():Object {
			return __proxyKey;
		}
		
		public function set proxyKey( value:Object ):void {
			StateRepository.removeFromNewEntityList( __proxyKey.toString() );
			__proxyKey = value;
		}

	    [Bindable(event="propertyChange")]
		public function get proxyInitialized():Boolean {
			return __proxyInitialized;
		}
		
		public function set proxyInitialized( value:Boolean ):void {
			__proxyInitialized = value;
		}
		public function save() : AsyncToken
		{
			return HibernateUpdater.save( this );
		}
	}
}