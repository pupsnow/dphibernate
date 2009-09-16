package net.digitalprimates.persistence.conversion;

import java.util.ArrayList;
import java.util.List;


public class TypeMapper {
	List<IConverter> converters;
	public TypeMapper()
	{
		converters = new ArrayList<IConverter>();
		converters.add(new DateCalendarConverter());
	}
	
	public Object convert(Object source,Class<?> targetClass)
	{
		for (IConverter converter : converters)
		{
			if (converter.canConvert(source.getClass(),targetClass))
			{
				return converter.convert(source,targetClass);
			}
		}
		throw new RuntimeException("No converter found");

	}
	public boolean canConvert(Object source,Class<?> targetClass)
	{
		for (IConverter converter : converters)
		{
			if (converter.canConvert(source.getClass(),targetClass))
			{
				return true;
			}
		}
		return false;
	}
}
