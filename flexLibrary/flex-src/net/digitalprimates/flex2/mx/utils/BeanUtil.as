package net.digitalprimates.flex2.mx.utils
{
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import mx.collections.ICollectionView;
	import mx.utils.DescribeTypeCache;
	import mx.utils.ObjectUtil;
	
	import net.digitalprimates.persistence.hibernate.HibernateManaged;
	import net.digitalprimates.persistence.hibernate.IHibernateProxy;
	import net.digitalprimates.persistence.hibernate.IHibernateRPC;
	

	public class BeanUtil
	{
		protected static var accesssorTypeMap:Dictionary = new Dictionary();

		public static function populateBean( genericObj:Object, 
												classDefinition:Class, 
												existingBean:Object=null, 
												dictionary:Dictionary=null,
												parent:Object=null,
												parentProperty:String=null, 
												ro:IHibernateRPC=null ):Object {			
			var bean:Object;
			var classInfo:XML;
			var accessors:XMLList;

			if ( !genericObj ) {
				return null;
			}

			if ( !dictionary ) {
				dictionary = new Dictionary( true );
			}

			if ( dictionary[ genericObj ] == true ) {
				return genericObj;
			}

			dictionary[ genericObj ] = true;

			if ( accesssorTypeMap[ classDefinition ] == null ) {
				classInfo = DescribeTypeCache.describeType( classDefinition ).typeDescription;
				accesssorTypeMap[ classDefinition ] = classInfo.accessor;
			}

			accessors = accesssorTypeMap[ classDefinition ] as XMLList;

			var property:String;
			var type:String;
			var access:String;
			
			if ( existingBean != null ) {
				bean = existingBean;
			} else {
				
				var name:String = getQualifiedClassName( classDefinition );
				
				if ( name.indexOf( "::I" ) == -1 ) {
					bean = new classDefinition();
				} else {
					return genericObj;
				}
			}

			if ( bean is IHibernateProxy ) {
				HibernateManaged.manageHibernateObject( bean as IHibernateProxy, parent, parentProperty, ro as IHibernateRPC );				
			}

			if ( ( genericObj is IHibernateProxy ) && ( bean is IHibernateProxy ) ) {
				IHibernateProxy( bean ).proxyInitialized = IHibernateProxy( genericObj ).proxyInitialized;
				IHibernateProxy( bean ).proxyKey = IHibernateProxy( genericObj ).proxyKey;				
			} 

			if ( genericObj is IHibernateProxy ) {
				if ( !IHibernateProxy( genericObj ).proxyInitialized ) {
					//if we are not initialized, do not dive any deeper, you will cause Hibernate to lazy load by any of these
					//actions

					return bean;
				}
			} 

			for ( var i:int=0; i<accessors.length(); i++ ) {					
				property = accessors[i].@name;
				type = accessors[i].@type;
				access = accessors[i].@access;
				
				if ( genericObj.hasOwnProperty( property ) && ( access != "readonly" ) ) {
					if ( type == 'Date' ) {
						if ( genericObj[ property ] is Date ) {
							bean[ property ] = new Date( ( genericObj[ property ] as Date ).getTime() );									
						} else {
							bean[ property ] = new Date( genericObj[ property ] );
						}
					} else {
						var beanHelper:BeanHelper = getBeanInformation( accessors[i] );
						
						if ( beanHelper.isSimple ) {
							bean[ property ] = genericObj[ property ];
						} else if ( beanHelper.isArray ) {
							bean[ property ] = new Array();

							for ( var j:int=0; j<genericObj[ property ].length; j++ ) {
								bean[ property ].push( populateBean( genericObj[ property ][ j ], beanHelper.elementClass, null, dictionary ) );
							}
						} else if ( beanHelper.elementClass ) {
							if ( beanHelper.elementClass is ICollectionView ) {
								trace('here');
							}
							if ( property != 'list' ) {
								bean[ property ] = populateBean( genericObj[ property ], beanHelper.elementClass, null, dictionary, bean, property, ro );
							} else {
								//trace("break here");
							}
						} else {								
							bean[ property ] = ObjectUtil.copy( genericObj[ property ] );
						}
					}
				}
			}

			if ( bean is IHibernateProxy && !IHibernateProxy( bean ).proxyKey ) {
				//trace("STOP!");
			}

			return bean;
		}

		protected static function getBeanInformation( accessor:XML ):BeanHelper {
			var type:String;
			var simpleArrayCopy:Boolean;
			var elementType:String;
			var elementClass:Class;
			var helper:BeanHelper = new BeanHelper();

			type = accessor.@type;

			if ( type == 'Array' ) {
				helper.isArray = true;
				var elementTypes:XMLList = accessor.metadata.(@name=="ArrayElementType");

				simpleArrayCopy = true;

				if ( elementTypes.length() > 0 ) {
					elementType = elementTypes[0].arg.@value;
					elementClass = getBeanDefinitionByName( elementType );

					if ( elementClass != null ) {
						simpleArrayCopy = isSimpleType( elementType );
					}
				}

				if ( simpleArrayCopy ) {
					helper.isSimple = true;
					elementClass = null;
				}					
			} else if ( isSimpleType( type ) ) {
				helper.isSimple = true;
				helper.isArray = false;
			} else {
				//some type of object, try to call recursively and see what we can do
				elementClass = getBeanDefinitionByName( type );
				helper.isSimple = false;
				helper.isArray = false;
				
				if ( type == 'Object' ) {						
					elementClass = null
				}
			}

			helper.elementClass = elementClass;
			return helper;
		}

		protected static var simpleTypes:Array = ['String','Number','uint','int','Boolean','Date', 'Array'];
		protected static function isSimpleType( type:String ):Boolean {
			for ( var i:int = 0; i<simpleTypes.length; i++ ) {
				if ( type == simpleTypes[ i ] ) {
					return true;
				}
			}
			
			return false;
		}
		
		protected static function getBeanDefinitionByName( name:String ):Class {
			var beanClass:Class;
			
			try {
				beanClass = getDefinitionByName( name ) as Class;
			}
			
			catch (error:Error ) {
				trace("Can not get definition of bean " + name );
				beanClass = null; //getDefinitionByName( "Object" ) as Class;
			}
			
			return beanClass;
		}
	}
}

class BeanHelper
{
	//simple, arrayvo, vo
	public var isSimple:Boolean = false;
	public var isArray:Boolean = false;
	public var elementClass:Class;
}
