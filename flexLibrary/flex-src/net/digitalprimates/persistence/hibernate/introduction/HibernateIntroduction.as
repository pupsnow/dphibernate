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
package net.digitalprimates.persistence.hibernate.introduction {
	import net.digitalprimates.persistence.entity.manager.IEntityManager;
	import net.digitalprimates.persistence.hibernate.manager.HibernateEntityManager;

	public class HibernateIntroduction {

		public var uid:String;

		private var _comStatus:uint = 0;
		private var _proxyKey:Object;
		private var _proxyInitialized:Boolean = true;
		private var _manager:IEntityManager;
		
		public function get comStatus():uint {
			return _comStatus;
		}

		public function set comStatus(value:uint):void {
			_comStatus = value;
		}

		public function get proxyKey():Object {
			return _proxyKey;
		}

		public function set proxyKey(value:Object):void {
			_proxyKey = value;
		}

		public function get proxyInitialized():Boolean {
			return _proxyInitialized;
		}

		public function set proxyInitialized(value:Boolean):void {
			_proxyInitialized = value;
		}

		public function get manager():IEntityManager {
			return _manager;
		}

		public function set manager(value:IEntityManager):void {
			_manager = value;
		}

		public function HibernateIntroduction() {
			super();
		}
	}
}