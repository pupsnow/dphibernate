package net.digitalprimates.persistence.state
{
	import mx.collections.IList;
	
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	[RemoteClass(alias="net.digitalprimates.persistence.state.CollectionChangeMessage")]	
	public class CollectionChangeMessage extends PropertyChangeMessage
	{
		private var _collection : IList
		public function CollectionChangeMessage( propertyName : String , collection : IList )
		{
			super( propertyName , null , null );
			_collection = collection;
		}
		
		public override function get newValue() : Object // Array of ObjectChangeMessage
		{
			var result : Array = []
			for each ( var proxy : IHibernateProxy in _collection )
			{
				if ( StateRepository.hasChanges( proxy  ) )
				{
					result.push( ChangeMessageFactory.getChangesForEntityOnly( proxy ) )
				} else {
					result.push( generateNoChangeMessage( proxy ) );
				}
			}
			return result;
		}
		
		private function generateNoChangeMessage( proxy : IHibernateProxy ) : ObjectChangeMessage
		{
			var message : ObjectChangeMessage = new ObjectChangeMessage( new HibernateProxyDescriptor( proxy ) );
			return message;
		}
	}
}