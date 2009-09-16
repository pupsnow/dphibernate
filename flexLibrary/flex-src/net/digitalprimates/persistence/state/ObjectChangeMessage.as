package net.digitalprimates.persistence.state
{

    [RemoteClass(alias="net.digitalprimates.persistence.state.ObjectChangeMessage")]
    public class ObjectChangeMessage
    {
        public function ObjectChangeMessage(owner:IHibernateProxyDescriptor, isNew:Boolean = false)
        {
            _owner = owner;
            _isNew = isNew;
            _changedPropertiesTable = new Object();
            _isDeleted = false;
        }

        public static function createDeleted(owner:IHibernateProxyDescriptor):ObjectChangeMessage
        {
            var result:ObjectChangeMessage = new ObjectChangeMessage(owner,false);
            result.isDeleted = true;
			return result;
        }

        private var _owner:IHibernateProxyDescriptor;

        public function get owner():IHibernateProxyDescriptor
        {
            return _owner;
        }

        public function set owner(value:IHibernateProxyDescriptor):void
        {
            _owner = value;
        }

        private var _changedPropertiesTable:Object // ofkey :PropertyName , value: PropertyChangeMessage

        public function hasChangedProperty(propertyName:String):Boolean
        {
            return _changedPropertiesTable[propertyName] != null;
        }

        public function getPropertyChange(propertyName:String):PropertyChangeMessage
        {
            return _changedPropertiesTable[propertyName];
        }

        private var _isDeleted:Boolean;

        public function get isDeleted():Boolean
        {
            return _isDeleted;
        }

        public function set isDeleted(value:Boolean):void
        {
            _isDeleted = value;
        }

        private var _isNew:Boolean;

        public function get isNew():Boolean
        {
            return _isNew;
        }

        public function set isNew(value:Boolean):void
        {
            throw new ReadOnlyError();
        }

        private var _changedProperties:Array; // Cached table

        public function get changedProperties():Array
        {
            if (!_changedProperties)
            {
                var result:Array = new Array();
                for (var propertyName:String in _changedPropertiesTable)
                {
                    if (_changedPropertiesTable[propertyName] is PropertyChangeMessage)
                    {
                        result.push(_changedPropertiesTable[propertyName]);
                    }
                }
                _changedProperties = result;
            }
            return _changedProperties;
        }

        public function set changedProperties(value:Array):void
        {
            throw new ReadOnlyError();
        }

        public function addChange(change:PropertyChangeMessage):void
        {
            _changedPropertiesTable[change.propertyName] = change;
            invalidateCache();
        }

        public function removeChangeForProperty(propertyName:String):PropertyChangeMessage
        {
            var existingChange:PropertyChangeMessage = _changedPropertiesTable[propertyName];
            delete _changedPropertiesTable[propertyName];
            invalidateCache();
            return existingChange;
        }

        private function invalidateCache():void
        {
            _changedProperties = null;
        }

        public function getChangeAt(index:int):PropertyChangeMessage
        {
            return changedProperties[index];
        }

        public function get numChanges():int
        {
            return changedProperties.length;
        }

        public function get hasChanges():Boolean
        {
            return numChanges > 0;
        }
    }
}