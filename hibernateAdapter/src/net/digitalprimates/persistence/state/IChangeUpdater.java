package net.digitalprimates.persistence.state;

import java.util.List;


public interface IChangeUpdater {

	public List<ObjectChangeResult> update();
}
