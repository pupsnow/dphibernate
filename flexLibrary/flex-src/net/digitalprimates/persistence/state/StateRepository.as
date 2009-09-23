package net.digitalprimates.persistence.state
{
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.logging.ILogger;
	import mx.utils.UIDUtil;
	
	import net.digitalprimates.persistence.events.LazyLoadEvent;
	import net.digitalprimates.persistence.hibernate.ClassUtils;
	import net.digitalprimates.persistence.hibernate.HibernateManaged;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	import net.digitalprimates.util.LogUtil;


	public class StateRepository
	{
		private static var log : ILogger = LogUtil.getLogger( StateRepository );
		private static var changeEntries:Array=new Array(); // Hash of Key : getKey() Value : ObjectChangeMessage
		private static var savePendingEntities : Object = new Object(); // List of keys of entities being saved
		private static var pendingChangeEntries : Array = new Array(); // Hash of changes made on entities with pending save Key: getKey() Value : ObjectChangeMessage 
		private static var listTable : Dictionary = new Dictionary(true) // of Key: IList , value : PropertyReference
        private static var lazyLoadingEntities:Dictionary = new Dictionary(true);
		private static var newEntities : Object = new Object();

		public function StateRepository()
		{
		}

		public static function storeList(list:IList,owner:IHibernateProxy=null,propertyName : String=null):void
		{
			if ( owner != null )
			{
				log.debug("Store list {0}::{1} {2}" , getQualifiedClassName(owner),owner.proxyKey,propertyName);
				list.addEventListener(CollectionEvent.COLLECTION_CHANGE, onCollectionChange, false, 0, true);
				listTable[ list ] = new PropertyReference( propertyName , owner );
			}
			for (var i:int=0; i < list.length; i++)
			{
				if (list.getItemAt(i) is IHibernateProxy)
				{
					var proxy : IHibernateProxy = list.getItemAt(i) as IHibernateProxy;
					if ( isNew( proxy ) )
					{
						addNewObject( proxy )
					} else {
						store(proxy);
					}
				}
			}
		}
		
		public static function hasChanges( object : IHibernateProxy ) : Boolean
		{
			if ( !contains( object ) ) return false;
			var changes : Array = ChangeMessageFactory.getChanges( object , true );
			for each ( var changeMessage : ObjectChangeMessage in changes )
			{
				if ( changeMessage.numChanges > 0 ) return true;
			}
			return false;
		}
		public static function store(object:IHibernateProxy):String
		{
			if ( !object ) return null;
			var objectIsNew : Boolean = isNew(object);
			var key:String=getKey(object);
			if (containsByKey(key))
			{
				log.info("Store {0} :: REDUNDANT!" , key );				
				return null;
			}
			if ( ClassUtils.isImmutable( object ) )
			{
				log.info("Store {0} :: Object is immutable - exiting")
				return null;
			}
			log.info("Store {0}" , key );
			if (key == null)
				throw new Error("Null key generated");
			if (!object is IEventDispatcher)
			{
				log.warn("Object is not an EventDispatcher.  Changes won't be detected");
			}
			else
			{
				var dispatcher : IEventDispatcher = IEventDispatcher(object); 
				dispatcher.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange, false, 0, true);
				dispatcher.addEventListener(LazyLoadEvent.pending , onLazyLoadStart , false , 0 , true );
				dispatcher.addEventListener(LazyLoadEvent.complete , onLazyLoadComplete , false , 0 , true );
			}
			var descriptor : HibernateProxyDescriptor = new HibernateProxyDescriptor( object );
			var targetStore : Object = getChangeRepositoryObject( object );
			
			targetStore[key]=new ObjectChangeMessage(descriptor,objectIsNew);
			storeChildren(object);
			return key;
		}

		private static function storeChildren(object:IHibernateProxy):void
		{
			// Prevent triggering loads of data
			log.debug("storeChildren {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var ro : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( object );
			var reEnableServerCalls : Boolean;
			if ( HibernateManaged.areServerCallsEnabled( ro ) )
			{
				HibernateManaged.disableServerCalls( ro );
				reEnableServerCalls = true;
				
			} 
			for each (var accessor:XML in ClassUtils.getAccessors(object))
			{
				var propertyName : String = accessor.@name;
				if ( ClassUtils.isTransient( object , propertyName ) ) 
					continue;
				if ( ignoreProperty( propertyName ) ) 
					continue;
 
				var child:Object=object[propertyName];
				if (child is IHibernateProxy)
				{
					store(child as IHibernateProxy);
				}
				if (child is IList)
				{
					storeList(child as IList,object,propertyName);
				}
			}
			if ( reEnableServerCalls )
			{
				HibernateManaged.enableServerCalls( ro );
			}
		}
		internal static function removeFromStore( object : IHibernateProxy , recursionTracker : ArrayCollection = null ) : void
		{
			log.debug("removeFromSTore {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var key:String=getKey(object);
			delete changeEntries[ key ];

			if ( !recursionTracker ) recursionTracker = new ArrayCollection();
			if ( recursionTracker.contains( key ) ) return;
			recursionTracker.addItem( key );
			resetStateOnChildren( object , recursionTracker );
		}
		internal static function getStoredObject( key : String ) : IHibernateProxy
		{
			log.debug("getStoredObject {0}" , key );
			var entry : ObjectChangeMessage = changeEntries[ key ];
			if ( !entry ) return null;
			return entry.owner.source;
		} 
		internal static function updateKey( oldKey : String , newKey : String , object : IHibernateProxy ) : void
		{
			var oldValue : ObjectChangeMessage = changeEntries[ oldKey ];
			if ( !oldValue ) return;
			
			delete changeEntries[ oldKey ];
			log.info( "Updated key for store repository.  Was: {0}  Now: {1}" , oldKey , newKey );
			
			// Because the key has changed, we need to update the owner reference
			var proxyOwner : HibernateProxyDescriptor = new HibernateProxyDescriptor( object );
			oldValue.owner = proxyOwner;
			changeEntries[newKey] = oldValue;
		}
		private static function resetStateOnChildren( object : IHibernateProxy , recursionTracker : ArrayCollection ) : void
		{
			log.debug("resetSTateOnChildren {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var children : ArrayCollection = getChildrenValues( object );
			resetStateOnList( children , recursionTracker );
		}
		internal static function resetStateOnList(list:IList, recursionTracker : ArrayCollection ):void
		{
			for each ( var member : Object in list )
			{
				if (member is IHibernateProxy)
				{
					removeFromStore(member as IHibernateProxy , recursionTracker );
				}
				if (member is IList)
				{
					resetStateOnList(member as IList, recursionTracker)
				}
			}
		}
		

		public static function contains(object:IHibernateProxy):Boolean
		{
			return containsByKey(getKey(object));
		}

		internal static function containsByKey(key:String):Boolean
		{
			var repository : Object = getChangeRepositoryObjectByKey( key );
			return repository[key] != null;
		}

		public static function reset():void
		{
			changeEntries=new Array();
			savePendingEntities = new Object();
			pendingChangeEntries = new Array(); 
			listTable = new Dictionary();
		}

		internal static function getKey(object:IHibernateProxy):String
		{
			return ClassUtils.getRemoteClassName( object ) + "::" + object.proxyKey;
		}

		public static function hasChangedProperty(object:IHibernateProxy, propertyName:String):Boolean
		{
			if (!contains(object))
				return false;
			return ChangeMessageFactory.getChangesForEntityOnly(object).hasChangedProperty(propertyName);
		}
		
		public static function saveCompleted( object : IHibernateProxy ) : void
		{
			log.debug("saveCompleted {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var key : String = getKey( object );
			delete savePendingEntities[ key ];
			removeFromStore( object );
			store( object );
			
			// Migrate any pending changes
			var pendingChangeMessage : ObjectChangeMessage = pendingChangeEntries[ key ];
			if ( pendingChangeMessage )
			{
				var currentChangeMessage : ObjectChangeMessage = changeEntries[ key ];
				for each ( var changedProperty : PropertyChangeMessage in pendingChangeMessage.changedProperties )
				{
					currentChangeMessage.addChange( changedProperty );
				} 
			}
			
		}
		public static function saveStarted( object : IHibernateProxy ) : void
		{
			var key : String = getKey( object );
			savePendingEntities[ key ] = object;
			// Store a baseline for changes that occur while save is in progress
			store( object );
		}
		
		internal static function hasPendingSave( proxy : IHibernateProxy ) : Boolean
		{
			return hasPendingSaveByKey( getKey( proxy ) );
		}
		internal static function hasPendingSaveByKey( key : String ) : Boolean
		{
			return savePendingEntities[ key ] != null;
		}
		internal static function getPendingChanges( key : String ) : ObjectChangeMessage
		{
			return null;
		}
		private static var changesRecursionDictionary : Dictionary = new Dictionary(true); 
		internal static function getStoredChanges(object:IHibernateProxy):ObjectChangeMessage
		{
			log.debug("getSToredChanges {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var key : String = getKey( object );
			var repository : Object = getChangeRepositoryObject( object );
			return repository[ key ];
		}
		/**
		 * Returns the object where changes will be stored.
		 * This value changes if a save is pending */
		private static function getChangeRepositoryObject( object : IHibernateProxy ) : Object
		{
			return getChangeRepositoryObjectByKey( getKey( object ) );
		}
		private static function getChangeRepositoryObjectByKey( key : String ) : Object
		{
			if ( hasPendingSaveByKey( key ) )
			{
				return pendingChangeEntries;
			} else {
				return changeEntries;
			}
		}
		
		
		
		private static function onPropertyChange(event:PropertyChangeEvent):void
		{
			if (!(event.source is IHibernateProxy))
			{
				trace("Got PropertyChange event on non IHibernateProxy - shouldn't happen");
				return;
			}
			var proxy:IHibernateProxy=event.source as IHibernateProxy;
			var key:String=getKey(proxy);
			log.debug("onPropertyChange {0}" , key);
			
			// We don't track changes while lazyLoading is underway, as it's gonna get reset anyway.
			if ( isLazyLoadingByKey( key ) ) return;
			
			storeChange(proxy, event.property as String, event.oldValue, event.newValue);
		}

		private static function storeChange(proxy:IHibernateProxy, propertyName:String, oldValue:Object, newValue:Object):void
		{
			log.debug("storeChange {0}::{1} {2}" , getQualifiedClassName(proxy),proxy.proxyKey,propertyName);
			if ( ClassUtils.isTransient( proxy , propertyName ) ) return;
			if ( isLazyLoading( proxy ) ) return;
			var changes:ObjectChangeMessage=ChangeMessageFactory.getChangesForEntityOnly(proxy);
			if ( !changes )
			{
				log.error( "Cannot store change without base change position.  Something's wrong!" );
				return;
			}
			var propertyChangeMessage:PropertyChangeMessage;
			var hasExistingChange : Boolean = false;
			if (changes.hasChangedProperty(propertyName))
			{
				hasExistingChange = true;
				var existingChange:PropertyChangeMessage=changes.getPropertyChange(propertyName);
				var mergedChange:PropertyChangeMessage=getPropertyChangeMessage(propertyName, existingChange.oldValue, newValue);
				propertyChangeMessage=mergedChange;
			}
			else
			{
				propertyChangeMessage=getPropertyChangeMessage(propertyName, oldValue, newValue);
			}
			if ( propertyChangeMessage.oldValue == propertyChangeMessage.newValue )
			{
				if ( hasExistingChange )
				{
					changes.removeChangeForProperty( propertyName );
				}
			} else {
				changes.addChange(propertyChangeMessage);
			}
			if ( oldValue is IList || newValue is IList )
			{
				updateListReferences( oldValue as IList , newValue as IList , proxy , propertyName );
			}
		}
		
		private static function updateListReferences( oldValue : IList , newValue : IList , owner : IHibernateProxy , propertyName : String ) : void
		{
			log.debug("updateListReferences {0}::{1} {2}" , getQualifiedClassName(owner),owner.proxyKey,propertyName);
			if ( oldValue )
			{
				delete listTable[ oldValue ];
				oldValue.removeEventListener( CollectionEvent.COLLECTION_CHANGE , onCollectionChange )
			}
			storeList( newValue , owner , propertyName );
		}
		// TODO : This is a util method.  Refactor
		internal static function getChildrenValues( object : IHibernateProxy ) : ArrayCollection // of Object
		{
			log.debug("getChildrenValue {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			var result : ArrayCollection = new ArrayCollection();
			// Prevent triggering loads of data
			var ro : IHibernateRPC = HibernateManaged.getIHibernateRPCForBean( object );
			var reEnableServerCalls : Boolean;
			if ( HibernateManaged.areServerCallsEnabled( ro ) )
			{
				HibernateManaged.disableServerCalls( ro );
				reEnableServerCalls = true;
				
			} 
			for each (var accessor:XML in ClassUtils.getAccessors(object))
			{
				var propertyName : String = accessor.@name; 
				if ( ClassUtils.isTransient( object , propertyName ) ) 
					continue;
				if ( ignoreProperty( propertyName ) ) 
					continue;
					
				var child:Object=object[propertyName];
				if ( child ) result.addItem( child );
			}
			if ( reEnableServerCalls )
			{
				HibernateManaged.enableServerCalls( ro );
			}
			return result;
		}
		private static function getPropertyChangeMessage(propertyName:String, oldValue:Object, newValue:Object):PropertyChangeMessage
		{
			log.debug("getPropertyChangeMessage: {0}" , propertyName);
			if ( newValue is IList ) 
			{
				return getCollectionChangeMessage( propertyName , newValue as IList );
			}
			if (oldValue is IHibernateProxy)
			{
				oldValue= new HibernateProxyDescriptor( oldValue as IHibernateProxy );
			}
			if (newValue is IHibernateProxy)
			{
				newValue=new HibernateProxyDescriptor( newValue as IHibernateProxy );
			}
			var propertyChangeMessage : PropertyChangeMessage = new PropertyChangeMessage(propertyName, oldValue, newValue);
			return propertyChangeMessage;
		}
		private static function getCollectionChangeMessage( propertyName : String , list : IList ) : CollectionChangeMessage
		{
			log.debug( "getCollectionChangeMessage {0} " , propertyName );
			var message : CollectionChangeMessage = new CollectionChangeMessage( propertyName , list );
			return message; 
		}

		private static function onCollectionChange(event:CollectionEvent):void
		{
			log.debug( "onCollectionChange : {0} " , event.kind );
			if (event.kind == CollectionEventKind.ADD)
			{
				for each (var item:IHibernateProxy in event.items)
				{
					generateFullChangeMessage(item);
				}
			}
			var list : IList = event.target as IList;
			var propertyReference : PropertyReference = listTable[ list ];
			// For collections, we don't store the old value
			if ( event.kind == CollectionEventKind.ADD || event.kind == CollectionEventKind.REMOVE || event.kind == CollectionEventKind.REPLACE )
			{
				storeChange( propertyReference.owner , propertyReference.propertyName , null , list );
			}
		}
		public static function addNewObject( object : IHibernateProxy ) : void
		{
			log.debug("addNewObject {0}::{1}" , getQualifiedClassName(object),object.proxyKey);
			generateFullChangeMessage( object );
		}
		private static function generateFullChangeMessage(item:IHibernateProxy):void
		{
			log.debug("generateFullChangeMessage {0}::{1}" , getQualifiedClassName(item),item.proxyKey);
			var key : String = store(item);
			for each (var accessor:XML in ClassUtils.getAccessors(item))
			{
				var propertyName : String = accessor.@name; 
				if ( !ignoreProperty( propertyName ) && !ClassUtils.isTransient( item , propertyName ) )
				{
					var property:Object = item[ propertyName ];
					if ( property is IHibernateProxy )
					{
						var proxy : IHibernateProxy = property as IHibernateProxy;
						if ( isNew( proxy ) && !contains( proxy ) )
						{
							addNewObject( proxy );
						}
					}
					storeChange( item , propertyName , null , property );
				}
			}
		}
		public static function isNew( object : IHibernateProxy ) : Boolean
		{
			return newEntities.hasOwnProperty( object.proxyKey );
		}
		public static function removeFromNewEntityList( oldKey : String ) : void
		{
			delete newEntities[ oldKey ];
		}
		private static var _ignoredProperties : ArrayCollection = new ArrayCollection([ "proxyInitialized" , "proxyKey" ])
		private static function ignoreProperty( propertyName : String ) : Boolean 
		{
			return _ignoredProperties.contains( propertyName );
		}
		
		
		private static function onLazyLoadStart( event : LazyLoadEvent ) : void
		{
			var proxy : IHibernateProxy = event.target as IHibernateProxy;
			var key : String = getKey( proxy );
			lazyLoadingEntities[ key ] = true;
		}

		private static function onLazyLoadComplete( event : LazyLoadEvent ) : void
		{
			var proxy : IHibernateProxy = event.target as IHibernateProxy;
			var key : String = getKey( proxy );
			delete lazyLoadingEntities[ key ];
			
			// TODO : This seems a bit heavy handed - resetting on an object when it's lazy load has finished.
			// It could be just for a property
			removeFromStore( proxy );
			store( proxy );
		}
		private static function isLazyLoading( object : IHibernateProxy ) : Boolean
		{
			var key : String = getKey( object );
			return isLazyLoadingByKey( key );
		}
		private static function isLazyLoadingByKey( key : String ) : Boolean
		{
			return lazyLoadingEntities[ key ] != null && lazyLoadingEntities[ key ] == true;
		}
		
		public static function getKeyForNewObject() : Object
		{
			var key : String = UIDUtil.createUID();
			newEntities[ key ] = key;
			return key;
		}
		
		 
	}
}
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	
class PropertyReference
{
	public var propertyName : String;
	public var owner : IHibernateProxy;
	public function PropertyReference( propertyName : String , owner : IHibernateProxy ) 
	{
		this.propertyName = propertyName;
		this.owner = owner;
	}
}