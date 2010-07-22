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

	import flash.events.IEventDispatcher;
	import flash.utils.*;

	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.core.IPropertyChangeNotifier;
	import mx.events.PropertyChangeEvent;
	import mx.logging.ILogger;
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.DescribeTypeCache;
	import mx.utils.DescribeTypeCacheRecord;
	import mx.utils.ObjectUtil;

	import net.digitalprimates.flex2.mx.utils.BeanUtil;
	import net.digitalprimates.persistence.collections.ManagedArrayList;
	import net.digitalprimates.persistence.events.LazyLoadEvent;
	import net.digitalprimates.persistence.state.StateRepository;
	import net.digitalprimates.util.LogUtil;

	public class HibernateManaged
	{
		public static const PROXY_LOAD_METHOD:String="loadDPProxy";

		public static const PROXY_SAVE_METHOD:String="saveDPProxy";

		protected static var recursionWatch:Dictionary=new Dictionary(true);

		protected static var pendingDictionary:Dictionary=new Dictionary(true);

		protected static var hibernateDictionary:Dictionary=new Dictionary(true);

		protected static var objectTypeMap:Object=new Object();

		protected static var serverCallsEnanabled:Dictionary=new Dictionary(true);

		private static var log:ILogger=LogUtil.getLogger(HibernateManaged);

		private static var _defaultHibernateService:IHibernateRPC;

		public static function set defaultHibernateService(value:IHibernateRPC):void
		{
			_defaultHibernateService=value;
		}

		public static function get defaultHibernateService():IHibernateRPC
		{
			return _defaultHibernateService;
		}

		public static function areServerCallsEnabled(ro:IHibernateRPC):Boolean
		{
			return (serverCallsEnanabled[ro] != false);
		}

		public static function enableServerCalls(ro:IHibernateRPC):void
		{
			serverCallsEnanabled[ro]=true;
		}

		public static function disableServerCalls(ro:IHibernateRPC):void
		{
			serverCallsEnanabled[ro]=false;
		}

		public static function getIHibernateRPC(obj:HibernateProxy):IHibernateRPC
		{
			return hibernateDictionary[obj] as IHibernateRPC
		}

		public static function getIHibernateRPCForBean(obj:IHibernateProxy):IHibernateRPC
		{
			var ro:Object=hibernateDictionary[obj];
			if (!ro)
				return defaultHibernateService;
			if (ro is IHibernateRPC)
				return ro as IHibernateRPC;
			if (ro is HibernateManagedEntry)
				return HibernateManagedEntry(ro).ro;
			return defaultHibernateService;
		}

		public static function manageChildTree(object:Object, parent:Object=null, propertyName:String=null, ro:IHibernateRPC=null):void
		{
			recursionWatch=new Dictionary(true);
			manageChildHibernateObjects(object, parent, propertyName, ro);
			recursionWatch=new Dictionary(true);
		}

		public static function manageChildHibernateObjects(object:Object, parent:Object=null, propertyName:String=null, ro:IHibernateRPC=null):void
		{
			var entry:XML;
			var accessors:XMLList

			if (!object)
			{
				return;
			}

			if (recursionWatch[object] == true)
			{
				//we have already examined this object, get out!
				return;
			}

			recursionWatch[object]=true;

			if (!(object is String))
			{
				var cacheRecord:DescribeTypeCacheRecord=DescribeTypeCache.describeType(object);
				entry=cacheRecord.typeDescription;
				accessors=entry.accessor;
			}

			if (object is IHibernateProxy)
			{
				manageHibernateObject(IHibernateProxy(object), parent, propertyName, ro);

				if (IHibernateProxy(object).proxyInitialized)
				{
					for (var k:int=0; k < accessors.length(); k++)
					{
						var accessor:Object=accessors[k];
						if (accessor.metadata.(@name == "Transient").length() > 0 || accessor.@access == "readonly")
						{
							// Skip, because it's transient
//                            log.info("Not managing {0}.{1} because transient or readonly", accessor.@declaredBy, accessor.@name);
						}
						else
						{
							manageChildHibernateObjects(object[accessors[k].@name], object, accessors[k].@name, ro);
						}
					}
				}
			}
			else if (object is ArrayCollection)
			{
				manageArrayCollection(ArrayCollection(object), ro);
			}
			else if (!ObjectUtil.isSimple(object))
			{
				for (var j:int=0; j < accessors.length(); j++)
				{
					manageChildHibernateObjects(object[accessors[j].@name], object, accessors[j].@name, ro);
				}
			}
		}

		public static function manageArrayCollection(collection:ArrayCollection, ro:IHibernateRPC):void
		{
			if (collection.list is ManagedArrayList)
			{
				ManagedArrayList(collection.list).serverCallsEnabled=false;
			}
			var isPagedCollection:Boolean=false;
			for (var i:int=0; i < collection.length; i++)
			{
				var collectionMember:Object=collection[i];
				manageChildHibernateObjects(collectionMember, collection, String(i), ro)
				if (collectionMember is IHibernateProxy && IHibernateProxy(collectionMember).proxyInitialized == false)
				{
					isPagedCollection=true;
				}
			}
			if (isPagedCollection)
			{
				var managedArrayList:ManagedArrayList=new ManagedArrayList(collection.source);
				collection.list=managedArrayList;
			}
			if (collection.list is ManagedArrayList)
			{
				ManagedArrayList(collection.list).serverCallsEnabled=true;
			}
		}

		public static function manageHibernateObject(obj:IHibernateProxy, parent:Object, parentProperty:String, ro:IHibernateRPC):void
		{
			hibernateDictionary[obj]=new HibernateManagedEntry(ro, parent, parentProperty);

			if ((obj is IPropertyChangeNotifier) && parent)
			{
				(obj as IPropertyChangeNotifier).addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, parent.dispatchEvent);
			}
		}

		protected static function isManaged(obj:IHibernateProxy):Boolean
		{
			return hibernateDictionary[obj] != null;
		}

		protected static function getLazyDataFromServer(obj:IHibernateProxy, property:String=null, value:*=null):*
		{
			var repopulateResponder:Responder=new Responder(HibernateManaged.lazyLoadArrived, HibernateManaged.lazyLoadFailed);

			var token:AsyncToken;

			var rpc:*=hibernateDictionary[obj];
			token=(hibernateDictionary[obj].ro as IHibernateRPC).loadProxy(obj.proxyKey, obj);

			token.addResponder(repopulateResponder);
			token.obj=obj;
			token.property=property;
			token.ro=hibernateDictionary[obj].ro;

			token.oldValue=obj;

			token.parent=hibernateDictionary[obj].parent;
			token.parentProperty=hibernateDictionary[obj].parentProperty;
			trace("Asking for Lazy Data for Property " + token.parentProperty);


			if (obj is IEventDispatcher)
			{
				IEventDispatcher(obj).dispatchEvent(new LazyLoadEvent(LazyLoadEvent.pending, property, true, true));
			}

			//this is where we need to be cautious. We either need to give back a simple value or another proxy
			if (property)
			{
				return value;
			}
			return obj;
		}

		public static function getProperty(obj:IHibernateProxy, property:String, value:*):*
		{

			var ro:IHibernateRPC;
			var entry:HibernateManagedEntry=hibernateDictionary[obj] as HibernateManagedEntry

			if (entry == null)
			{
				return value;
			}

			ro=entry.ro;

			if (obj.proxyInitialized)
			{
				//We need to check here if this particular item we are about to return is a proxy itself...
				//If it is a proxy,then we probably need to go and instantiate it now
				/*
				   //I don't believe this is needed, this is occuring if we try to access the proxy itself
				   //At this point, we have not tried to access the children of the proxy, which is what
				   //should cause the lazy load
				   if ( ( value ) && ( value is IHibernateProxy ) && ( !IHibernateProxy(value).proxyInitialized ) ) {
				   if ( hibernateDictionary[ value ] ) {
				   if ( !pendingDictionary[ value ] && areServerCallsEnabled( ro ) ) {
				   pendingDictionary[ value ] = true;
				   return getLazyDataFromServer( value );
				   }
				   }
				   }
				 */
				return value;
			}
			else
			{
				if (!pendingDictionary[obj] && areServerCallsEnabled(ro))
				{
					pendingDictionary[obj]=true;
					return getLazyDataFromServer(obj, property, value);
				}
				else
				{
					return value;
				}
			}
		}

		public static function rebroadcastEvent(event:PropertyChangeEvent):void
		{
			trace(event.property + " propogating ");
		}

		public static function setProperty(obj:IHibernateProxy, property:Object, oldValue:*, newValue:*, parent:Object=null, parentProperty:String=null):void
		{

			var dispatcher:IEventDispatcher=obj as IEventDispatcher;

			if ((oldValue is IPropertyChangeNotifier) && parent)
			{
				oldValue.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, parent.dispatchEvent);
			}

			if ((newValue is IPropertyChangeNotifier) && parent)
			{
				newValue.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, parent.dispatchEvent);
			}

			if (dispatcher) // && (dispatcher.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE)) )
			{
				var event:PropertyChangeEvent=PropertyChangeEvent.createUpdateEvent(dispatcher, property, oldValue, newValue);
				dispatcher.dispatchEvent(event);
			}
		}

		public static function lazyLoadArrived(event:ResultEvent):void
		{
			var token:AsyncToken=event.token;

			delete pendingDictionary[token.obj];

			var classDef:Class=getDefinitionByName(getQualifiedClassName(token.obj)) as Class;

			disableServerCalls(token.ro as IHibernateRPC);
			token.obj.proxyInitialized=true;

			StateRepository.ignorePropertyChanges=true;
			BeanUtil.populateBean(event.result, classDef, token.obj, new Dictionary(true), token.parent, token.parentProperty, token.ro as IHibernateRPC);
			StateRepository.ignorePropertyChanges=false;
			//ValueObjectUtil.populateVO( event.result, classDef, token.obj, new Dictionary( true ) ); 

			//In theory, this part would no longer be needed after the changes to populateBean
			//manageChildTree( token.obj, token.parent, token.property, token.ro as IHibernateRPC );
			enableServerCalls(token.ro as IHibernateRPC);

			setProperty(token.obj, token.property, token.oldValue, event.result, token.parent, token.parentProperty)

			if (token.obj is IEventDispatcher)
			{
				IEventDispatcher(token.obj).dispatchEvent(new LazyLoadEvent(LazyLoadEvent.complete, token.parentProperty, token.parent, true, true));
			}
		}

		public static function lazyLoadFailed(event:FaultEvent):void
		{
			trace("Lazy load failed");

			var token:AsyncToken=event.token;

			if (token && token.obj && token.obj is IEventDispatcher)
			{
				IEventDispatcher(token.obj).dispatchEvent(new LazyLoadEvent(LazyLoadEvent.failed, token.parentProperty, token.parent, true, true));
			}
		}

		public static function addHibernateResponder(ro:IHibernateRPC, token:AsyncToken):void
		{
			var managedResponder:Responder=new Responder(handleHibernateResult, handleHibernateFault);
			token.ro=ro;
			token.addResponder(managedResponder);
		}

		protected static function handleHibernateResult(event:ResultEvent):void
		{
			disableServerCalls(event.token.ro);
			var remoteService:IHibernateRPC=IHibernateRPC(event.token.ro);
			manageChildTree(event.result, null, null, remoteService);
			if (remoteService.stateTrackingEnabled)
			{
				manageStateOfResultObject(event);
			}
			enableServerCalls(event.token.ro);
		}

		protected static function manageStateOfResultObject(event:ResultEvent):void
		{
			if (event.result is IHibernateProxy)
			{
				StateRepository.store(event.result as IHibernateProxy);
			}
			else if (event.result is IList)
			{
				StateRepository.storeList(event.result as IList);
			}
		}

		public static function repopulateObject(oldObject:IHibernateProxy, newObject:IHibernateProxy, classDef:Class):void
		{
			var existingEntry:HibernateManagedEntry=hibernateDictionary[oldObject] as HibernateManagedEntry;
			BeanUtil.populateBean(newObject, classDef, oldObject, null, null, null, existingEntry.ro);
		}

		protected static function handleHibernateFault(event:FaultEvent):void
		{
			trace("Something bad happend\n" + event.fault.faultString);
		}


	}
}
