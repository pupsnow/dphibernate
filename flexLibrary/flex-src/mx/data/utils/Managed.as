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


package mx.data.utils {
	import mx.data.IManaged;
	
	import org.dphibernate.rpc.HibernateManaged;
	import org.dphibernate.core.IHibernateProxy;
	

	public class Managed extends Object {
		public static function getProperty(obj:IManaged, property:String, value:*):* {
			if ( obj is IHibernateProxy ) {
				return HibernateManaged.getProperty( obj as IHibernateProxy, property, value );
			} else {
				return value;
			}
		}

		public static function setProperty(obj:IManaged, property:Object, oldValue:*, newValue:* ):void {
			if ( obj is IHibernateProxy ) {
				HibernateManaged.setProperty(obj as IHibernateProxy, property, oldValue, newValue );
			}
		}
	}
}
