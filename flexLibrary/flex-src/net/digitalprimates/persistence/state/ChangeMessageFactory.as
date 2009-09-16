package net.digitalprimates.persistence.state
{
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	
	import net.digitalprimates.persistence.hibernate.ClassUtils;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;

	public class ChangeMessageFactory
	{
		public static function getChangesForEntityOnly(object:IHibernateProxy):ObjectChangeMessage
		{
			var result:Array=getChanges(object, false, true);
			if (result.length == 0)
				return null;
			return (result[0] as ObjectChangeMessage);
		}

		public static function getChanges(object:IHibernateProxy, cascade:Boolean=true, includeUnchangedObject:Boolean=false):Array // Of ObjectChangeMessage
		{
			var changeCollection:ObjectChangeMessageCollection=doGetChanges(object, cascade, includeUnchangedObject);
			return changeCollection.changeMessages;
		}

		// Recursion entry point
		private static function doGetChanges(object:IHibernateProxy, cascade:Boolean=true, includeUnchangedObject:Boolean=false, recursionTracker:ArrayCollection=null, collection:ObjectChangeMessageCollection=null):ObjectChangeMessageCollection
		{
			if (!collection)
				collection=new ObjectChangeMessageCollection();
			if (ClassUtils.isImmutable( object ) )
			{
				return collection;
			}
			var key:String=StateRepository.getKey(object);
			if (StateRepository.isNew(object) && !StateRepository.contains(object))
			{
				StateRepository.addNewObject(object);
			}
			var objectChangeMessage:ObjectChangeMessage;
			objectChangeMessage=StateRepository.getStoredChanges(object);


			if (objectChangeMessage && objectChangeMessage.numChanges > 0 || (objectChangeMessage && objectChangeMessage.numChanges == 0 && includeUnchangedObject))
			{
				collection.add(objectChangeMessage);
			}
			if (!cascade)
				return collection;

			if (!recursionTracker)
				recursionTracker=new ArrayCollection();

			if (recursionTracker.contains(key))
				return collection;
			recursionTracker.addItem(key);

			appendChangesOfChildren(object, recursionTracker, collection);

			return collection;
		}

		internal static function appendChangesOfChildren(object:IHibernateProxy, recursionTracker:ArrayCollection, collection:ObjectChangeMessageCollection):void
		{
			var childrenValue:ArrayCollection=StateRepository.getChildrenValues(object);
			appendChangesForList(childrenValue, recursionTracker, collection);
		}

		internal static function appendChangesForList(list:IList, recursionTracker:ArrayCollection, collection:ObjectChangeMessageCollection):void
		{
			for each (var child:Object in list)
			{
				if (child is IHibernateProxy)
				{
					doGetChanges(child as IHibernateProxy, true, false, recursionTracker, collection);
				}
				if (child is IList)
				{
					appendChangesForList(child as IList, recursionTracker, collection)
				}
			}
		}

	}
}