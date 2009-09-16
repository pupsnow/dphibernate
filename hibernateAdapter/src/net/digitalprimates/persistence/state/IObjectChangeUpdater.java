package net.digitalprimates.persistence.state;

import java.util.List;

public interface IObjectChangeUpdater {
	public List<ObjectChangeResult> update(ObjectChangeMessage changeMessage);

	public List<ObjectChangeResult> update(
			List<ObjectChangeMessage> changeMessages);

	public List<ObjectChangeMessage> orderByDependencies(
			List<ObjectChangeMessage> objectChangeMessages);
}
