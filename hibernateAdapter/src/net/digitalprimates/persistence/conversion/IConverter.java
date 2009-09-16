package net.digitalprimates.persistence.conversion;

public interface IConverter {

	boolean canConvert(Class<?> class1, Class<?> targetClass);

	Object convert(Object source, Class<?> targetClass);

}
