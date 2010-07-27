package net.digitalprimates.persistence.hibernate.utils;

import net.digitalprimates.persistence.state.IChangeMessageInterceptor;

/**
 * Marker interface for PasswordEncryptionInterceptor.
 * Required for Spring's Transaction Manager
 * to be able to create a proxy of PasswordEncryptionManager 
 * @author Marty Pitt
 *
 */
public interface IPasswordEncryptionInterceptor extends IChangeMessageInterceptor
{

}
