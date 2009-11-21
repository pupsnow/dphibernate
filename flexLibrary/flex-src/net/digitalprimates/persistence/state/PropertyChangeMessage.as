package net.digitalprimates.persistence.state
{
	[RemoteClass(alias="net.digitalprimates.persistence.state.PropertyChangeMessage")]
	public class PropertyChangeMessage
	{
		public function PropertyChangeMessage( propertyName : String , oldValue : Object , newValue : Object ) 
		{
			_propertyName = propertyName;
			_oldValue = oldValue;
			_newValue = newValue;
		}
		private var _propertyName : String;
		private var _oldValue : Object;
		private var _newValue : Object;
		
		public function get propertyName() : String
		{
			return _propertyName;
		}
		public function set propertyName( value : String ) : void
		{
			throw new ReadOnlyError();
		}
		public function get oldValue() : Object
		{
			return _oldValue;
		}
		public function set oldValue( value : Object ) : void
		{
			throw new ReadOnlyError();
		}
		public function get newValue() : Object
		{
			return _newValue;
		}
		public function set newValue( value : Object ) : void
		{
			throw new ReadOnlyError();
		}
		public function get oldAndNewValueMatch() : Boolean
		{
			return oldValue == newValue;
		}
	}
}