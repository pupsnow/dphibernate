package com.mangofactory.pepper.view
{
	import com.mangofactory.pepper.controller.commands.LoadRecentQuestionsCommand;
	import com.mangofactory.pepper.controller.events.LoadRecentQuestionsEvent;
	import com.mangofactory.pepper.controller.events.UserChangedEvent;
	
	import mx.collections.ArrayCollection;

	public class RecentQuestionsPM extends BasePM
	{
		[Bindable]
		public var questions:ArrayCollection;
		
		[MessageHandler]
		public function onUserLoggedIn(event:UserChangedEvent):void
		{
			broadcast(new LoadRecentQuestionsEvent());
		}
		[CommandResult]
		public function onRecentPostsLoaded(posts:ArrayCollection,trigger:LoadRecentQuestionsEvent):void
		{
			this.questions = posts;
		}
	}
}