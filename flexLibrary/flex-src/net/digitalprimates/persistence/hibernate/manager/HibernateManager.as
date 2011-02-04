/**
 * Copyright (c) 2011 Digital Primates
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 * 
 * @author     Michael Labriola 
 * @version    
 **/
package net.digitalprimates.persistence.hibernate.manager {
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	
	import net.digitalprimates.persistence.hibernate.proxy.HibernateEntityProxyBuilder;

	public class HibernateManager {
		private static var entityProxyBuilder:HibernateEntityProxyBuilder;
		private static var initialized:Boolean = false;
		
		/**
		 * Not really sure if I want to keep this here yet.. just not sure where it should live
		 *  
		 * @param loaderInfo
		 * @param success
		 * @param failure
		 * 
		 */		
		public static function initialize( loaderInfo:LoaderInfo, success:Function=null, failure:Function=null ):void {
			
			//Until we clean this up, just guard against it being called twice
			if ( initialized ) {
				return;
			}
			
			entityProxyBuilder = new HibernateEntityProxyBuilder( loaderInfo );
			
			if ( success != null ) {
				entityProxyBuilder.addEventListener( Event.COMPLETE, success );
			}
			
			if ( failure != null ) {
				entityProxyBuilder.addEventListener( IOErrorEvent.VERIFY_ERROR, failure );
			}
			
			entityProxyBuilder.manageEntities();
			initialized = true;
		}
		
		public static function createEntity( clazz:Class, args:Array = null ):* {
			if ( !entityProxyBuilder ) {
				return null;
			}
			
			return entityProxyBuilder.createEntity( clazz, args );
		}
		
		public static function getEntityClass( clazz:Class ):Class {
			if ( !entityProxyBuilder ) {
				return null;
			}
			
			return entityProxyBuilder.getEntityClass( clazz );	
		}	
		
		public function HibernateManager() {
		}
	}
}