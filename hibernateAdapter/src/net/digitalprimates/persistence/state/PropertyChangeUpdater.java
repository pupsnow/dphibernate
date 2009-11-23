package net.digitalprimates.persistence.state;

import java.lang.annotation.Annotation;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;

import net.digitalprimates.persistence.annotations.SetterFor;
import net.digitalprimates.persistence.conversion.TypeMapper;
import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;

import org.apache.commons.lang.ClassUtils;
import org.apache.commons.lang.ObjectUtils;
import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import flex.messaging.io.ArrayCollection;

public class PropertyChangeUpdater implements IChangeUpdater
{

	protected final PropertyChangeMessage propertyChangeMessage;
	protected final IHibernateProxy entity;
	protected final IProxyResolver proxyResolver;

	protected final String propertyName;
	private final String getterName;
	private final String setterName;
	protected final TypeMapper typeMapper = new TypeMapper();

	protected final Logger log = LoggerFactory.getLogger(PropertyChangeUpdater.class);


	public PropertyChangeUpdater(PropertyChangeMessage propertyChangeMessage, IHibernateProxy entity, IProxyResolver proxyResolver)
	{
		this.propertyChangeMessage = propertyChangeMessage;
		this.proxyResolver = proxyResolver;
		this.entity = entity;

		propertyName = propertyChangeMessage.getPropertyName();
		// propertyName = StringUtils.capitalize(rawPropertyName);
		setterName = findSetterName(entity);
		getterName = findGetterName(entity);
	}


	private String findSetterName(IHibernateProxy entity)
	{
		String annotatedSetterName = findAnnotatedSetter(entity, propertyName);
		if (annotatedSetterName != null)
		{
			return annotatedSetterName;
		}
		// TODO : Check that the method exists!
		String capitalizedName = StringUtils.capitalize(propertyName);
		return "set" + capitalizedName;
	}


	private String findAnnotatedSetter(IHibernateProxy entity, String propertyName)
	{
		for (Method method : entity.getClass().getMethods())
		{
			SetterFor annotation = method.getAnnotation(SetterFor.class);
			if (annotation != null)
			{
				if (annotation.value().equals(propertyName))
				{
					return method.getName();
				}
			}
		}
		return null;
	}


	private String findGetterName(IHibernateProxy entity)
	{
		String matchedName = null;
		String capitalizedName = StringUtils.capitalize(propertyName);
		for (String attemptedName : Arrays.asList("get" + capitalizedName, "is" + capitalizedName))
		{
			if (hasMethod(entity, attemptedName))
			{
				matchedName = attemptedName;
			}
		}
		if (matchedName == null)
		{
			throw new RuntimeException("Property " + propertyName + " has no getter");
		}
		return matchedName;
	}


	private boolean hasMethod(Object object, String methodName, Class<?>... parameterTypes)
	{
		try
		{
			object.getClass().getMethod(methodName, parameterTypes);
			return true;
		} catch (SecurityException e)
		{
			throw e;
		} catch (NoSuchMethodException e)
		{
			return false;
		}
	}


	public List<ObjectChangeResult> update()
	{
		ArrayList<ObjectChangeResult> result = new ArrayList<ObjectChangeResult>();
		if (!hasSetter())
		{
			return result;
		}
		/*
		 * Object currentValue = getCurrentValue(); Object oldValue =
		 * getOldValue(); // checkConcurrency(currentValue, oldValue);
		 */
		Object newValue = getUpdatedValue();
		updateNewValue(newValue);
		return result;
	}


	private Object getOldValue()
	{
		Object value = propertyChangeMessage.getOldValue();
		if (value instanceof IHibernateProxyDescriptor)
		{
			value = proxyResolver.resolve((IHibernateProxyDescriptor) value);
		}
		return value;
	}


	private void checkConcurrency(Object currentValue, Object receivedOldValue)
	{
		if ((currentValue == null && receivedOldValue != null) || (currentValue != null && !currentValue.equals(receivedOldValue)))
		{
			throw new DataUpdateConcurrencyException();
		}
	}


	protected Object getCurrentValue()
	{
		try
		{
			Method getter = getGetter();
			Object currentValue = getter.invoke(entity, null);
			return currentValue;
		} catch (InvocationTargetException e)
		{
			log.error("InvocationTargetException calling " + getGetterName());
			log.error(e.getMessage());
			throw new RuntimeException(e);
		} catch (Exception e)
		{
			throw new RuntimeException(e);
		}
	}


	protected boolean hasSetter()
	{
		Method setter = getSetter();
		if (setter == null)
		{
			log.warn("Tried update on readonly property " + propertyName + " - ignoring");
			return false;
		}
		return true;
	}

	private Method setter;


	protected Method getSetter()
	{
		if (setter != null)
		{
			return setter;
		}

		Method result;
		result = findSetterFromGetter();
		if (result == null)
		{
			result = findSetterFromNewValue();
		}
		if (result == null)
		{
			result = findSetterFromCollection();
		}
		setter = result;
		return result;
	}

	private boolean useCollectionUpdateStrategy = false;


	private Method findSetterFromCollection()
	{
		Object updatedValue = getUpdatedValue();
		if (updatedValue == null)
			return null;
		if (!(updatedValue instanceof Collection))
			return null;
		Collection<?> collection = (Collection<?>) updatedValue;
		return findSetterFromCollection(collection);
	}


	private Method findSetterFromCollection(Collection<?> collection)
	{
		if (collection.size() == 0)
			return null;
		Object firstInstance = collection.iterator().next();
		Class<?> collectionMemeberClass = firstInstance.getClass();
		Method setter = findSetterForType(collectionMemeberClass);
		if (setter != null)
		{
			useCollectionUpdateStrategy = true;
		}
		return setter;
	}


	private boolean canUseCollectionStrategyForValue(Object value)
	{
		if (value instanceof Collection<?>)
		{
			Method findSetterFromCollection = findSetterFromCollection((Collection<?>) value);
			return findSetterFromCollection != null;
		} else
		{
			return false;
		}
	}


	private Method findSetterFromNewValue()
	{
		Object updatedValue = getUpdatedValue();
		if (updatedValue == null)
			return null;
		Class declaredPropertyClass = updatedValue.getClass();
		return findSetterForType(declaredPropertyClass);

	}


	private Method findSetterForType(Class<?> setterType)
	{
		try
		{
			Method setter = entity.getClass().getMethod(getSetterName(), setterType);
			return setter;
		} catch (Exception e)
		{
			return null;
		}
	}


	private Method findSetterFromGetter()
	{
		Method getter = getGetter();
		Class declaredPropertyClass = getter.getReturnType();
		return findSetterForType(declaredPropertyClass);
	}


	protected Method getGetter()
	{
		Method getter;
		try
		{
			getter = entity.getClass().getMethod(getGetterName(), null);
		} catch (Exception e)
		{
			throw new RuntimeException(e);
		}
		return getter;
	}


	protected void updateNewValue(Object updatedValue)
	{
		if (useCollectionUpdateStrategy)
		{
			updateAsCollection(updatedValue);
			return;
		}
		Method setter = getSetter();
		try
		{
			setter.invoke(entity, updatedValue);
		} catch (IllegalArgumentException e)
		{
			throw new RuntimeException(e);
		} catch (IllegalAccessException e)
		{
			throw new RuntimeException(e);
		} catch (InvocationTargetException e)
		{
			throw new RuntimeException(e);
		}
	}


	private void updateAsCollection(Object updatedValue)
	{
		for (Object object : (Collection<?>) updatedValue)
		{
			try
			{
				setter.invoke(entity, object);
			} catch (Exception e)
			{
				throw new RuntimeException(e);
			}
		}
	}

	private Object updatedValue;


	protected Object getUpdatedValue()
	{
		if (updatedValue != null)
			return updatedValue;
		Object resolvedProxies = attemptProxyResolution(propertyChangeMessage.getNewValue());
		if (resolvedProxies != null)
		{
			updatedValue = resolvedProxies;
			return resolvedProxies;
		}
		Object newValue;
		newValue = propertyChangeMessage.getNewValue();
		if (typeMapper != null && newValue != null)
		{
			Class<?> targetClass = getGetter().getReturnType();
			if (!targetClass.isAssignableFrom(newValue.getClass()))
			{
				if (typeMapper.canConvert(propertyChangeMessage.getNewValue(), targetClass))
				{
					newValue = typeMapper.convert(propertyChangeMessage.getNewValue(), targetClass);
				} else if (canUseCollectionStrategyForValue(newValue))
				{
					// Don't need to do anything
				} else
				{
					throw new RuntimeException("Cannot assign or map " + propertyChangeMessage.getNewValue() + " to expected type " + targetClass.getName());
				}
			}
		}
		updatedValue = newValue;
		return newValue;
	}


	private Object attemptProxyResolution(Object newValue)
	{
		if (newValue instanceof IHibernateProxyDescriptor)
		{
			return doProxyResolution((IHibernateProxyDescriptor) newValue);
		}
		if (newValue instanceof IHibernateProxyDescriptor[])
		{
			List<IHibernateProxyDescriptor> list = new ArrayList<IHibernateProxyDescriptor>();
			for (IHibernateProxyDescriptor proxy : (IHibernateProxyDescriptor[])newValue)
			{
				list.add(proxy);	
			}
			newValue = list;
		}
		if (newValue instanceof Collection<?>)
		{
			List<IHibernateProxy> result = new ArrayList<IHibernateProxy>();
			for (Object member : ((Collection<?>) newValue))
			{
				if (!(member instanceof IHibernateProxyDescriptor))
				{
					// If there are any non-proxies in the collection, bail.
					return null;
				}
				result.add(doProxyResolution((IHibernateProxyDescriptor) member));
			}
			return result;
		}
		return null;
	}


	private IHibernateProxy doProxyResolution(IHibernateProxyDescriptor proxy)
	{
		IHibernateProxy entity = (IHibernateProxy) proxyResolver.resolve(proxy);
		if (entity == null)
		{
			throw new RuntimeException("Proxy not resolved: " + proxy.toString());
		}
		return entity;
	}


	public String getGetterName()
	{
		return getterName;
	}


	public String getSetterName()
	{
		return setterName;
	}
}
