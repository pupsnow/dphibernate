package net.digitalprimates.persistence.hibernate.utils.services;

import java.util.List;
import java.util.Set;

import net.digitalprimates.persistence.state.ObjectChangeMessage;
import net.digitalprimates.persistence.state.ObjectChangeResult;

public interface IProxyUpdateService
{
	Set<ObjectChangeResult> saveBean(List<ObjectChangeMessage> objectChangeMessage);
	Set<ObjectChangeResult> saveBean(ObjectChangeMessage objectChangeMessage);
}
