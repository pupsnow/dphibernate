package net.digitalprimates.persistence.state;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.List;

import net.digitalprimates.persistence.conversion.TypeMapper;
import net.digitalprimates.persistence.hibernate.proxy.IHibernateProxy;

import org.apache.commons.lang.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class PropertyChangeUpdater implements IChangeUpdater {

	protected final PropertyChangeMessage propertyChangeMessage;
	protected final IHibernateProxy entity;
	protected final IProxyResolver proxyResolver;

	protected final String propertyName;
	protected final String getterName;
	protected final String setterName;
	protected final TypeMapper typeMapper = new TypeMapper();
	
	protected final Logger log = LoggerFactory
			.getLogger(PropertyChangeUpdater.class);

	public PropertyChangeUpdater(PropertyChangeMessage propertyChangeMessage,
			IHibernateProxy entity, IProxyResolver proxyResolver) {
		this.propertyChangeMessage = propertyChangeMessage;
		this.proxyResolver = proxyResolver;
		this.entity = entity;

		String rawPropertyName = propertyChangeMessage.getPropertyName();
		propertyName = StringUtils.capitalize(rawPropertyName);
		setterName = "set" + propertyName;
		getterName = "get" + propertyName;
	}

	public List<ObjectChangeResult> update() {
		ArrayList<ObjectChangeResult> result = new ArrayList<ObjectChangeResult>();
		if (!hasSetter())
		{
			return result;
		}
		Object currentValue = getCurrentValue();
		Object oldValue = getOldValue();
		checkConcurrency(currentValue, oldValue);
		updateNewValue();
		return result;
	}

	private Object getOldValue() {
		Object value = propertyChangeMessage.getOldValue();
		if (value instanceof IHibernateProxyDescriptor) {
			value = proxyResolver.resolve((IHibernateProxyDescriptor) value);
		}
		return value;
	}

	private void checkConcurrency(Object currentValue, Object receivedOldValue) {
		if ((currentValue == null && receivedOldValue != null)
				|| (currentValue != null && !currentValue
						.equals(receivedOldValue))) {
			throw new DataUpdateConcurrencyException();
		}
	}

	protected Object getCurrentValue() {
		try {
			String getterName = "get" + propertyName;
			Method getter = getGetter();
			Object currentValue = getter.invoke(entity, null);
			return currentValue;
		} catch (InvocationTargetException e) {
			log.error("InvocationTargetException calling " + getterName);
			log.error(e.getMessage());
			throw new RuntimeException(e);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	protected boolean hasSetter() {
		try {
			Method getter = getGetter();
			Class declaredPropertyClass = getter.getReturnType();
			Method setter = entity.getClass().getMethod(setterName,
					declaredPropertyClass);
			if (setter == null) {
				log.warn("Tried update on readonly property " + propertyName
						+ " - ignoring");
				return false;
			}
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
		return true;
	}
	protected Method getSetter()
	{
		try {
			Method getter = getGetter();
			Class declaredPropertyClass = getter.getReturnType();
			Method setter = entity.getClass().getMethod(setterName,
					declaredPropertyClass);
			return setter;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	protected Method getGetter() {
		Method getter;
		try {
			getter = entity.getClass().getMethod(getterName, null);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
		return getter;
	}
	protected void updateNewValue() {
		try {
			Method setter = getSetter();
			Object updatedValue = getUpdatedValue();
			setter.invoke(entity, updatedValue);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	protected Object getUpdatedValue() {
		if (propertyChangeMessage.getNewValue() instanceof IHibernateProxyDescriptor) {
			IHibernateProxyDescriptor proxy = (IHibernateProxyDescriptor) propertyChangeMessage
					.getNewValue();
			Object entity = proxyResolver.resolve(proxy);
			if (entity == null)
			{
				throw new RuntimeException("Proxy not resolved: " + proxy.toString());
			}
			return entity;
		} else {
			Object newValue;
			newValue = propertyChangeMessage.getNewValue();
			if (typeMapper !=null && newValue != null)
			{
				Class<?> targetClass = getGetter().getReturnType();
				if (!targetClass.isAssignableFrom(newValue.getClass()))
				{
					if (typeMapper.canConvert(propertyChangeMessage.getNewValue(), targetClass))
					{
						newValue = typeMapper.convert(propertyChangeMessage.getNewValue(), targetClass);
					} else {
						throw new RuntimeException("Cannot assign or map " + propertyChangeMessage.getNewValue() + " to expected type " + targetClass.getName());
					}
				}
			}
			return newValue;
		}
	}
}
