package com.mangofactory.pepper.view
{
	import com.mangofactory.pepper.controller.events.SignInEvent;
	import com.mangofactory.pepper.model.ApplicationUser;
	import com.mangofactory.pepper.service.interceptors.UsernameNotUniqueException;
	
	import flash.events.Event;
	
	import mx.controls.Alert;
	import mx.rpc.AsyncToken;
	import mx.rpc.Responder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	[Event(name="usernameError",type="flash.events.Event")]
	[Event(name="passwordError",type="flash.events.Event")]
	public class SignInPM extends BasePM
	{
		public static const USERNAME_ERROR:String = "usernameError";
		public static const PASSWORD_ERROR:String = "passwordError";
		[Bindable]
		public var usernameErrorString:String;
		[Bindable]
		public var passwordErrorString:String;
		
		public function SignInPM()
		{
		}
		
		
		public function registerAndSignIn(username:String,password:String):void
		{
			resetErrorProperties();
			// To create a new entity, simply instatiate it normally...
			var user:ApplicationUser = new ApplicationUser();
			user.username = username;
			user.password = password;
			
			// Calling save on the user persists the user on the server
			// Passing a responder is optional, but is used to register for callbacks on either 
			// success to failure of the save.
			var token:AsyncToken = user.save(new Responder(onUserCreated,onUserCreationFailed));
			
			// Store the user on the AsyncToken so it's accessible on the resultEvent handler
			token.user = user;
		}
		public function signIn(username:String,password:String):void
		{
			var user:ApplicationUser = ApplicationUser.create(username,password);
			
			// See SignInCommand for the actual sign-in logic
			broadcast(new SignInEvent(user));	
		}
		private function resetErrorProperties():void
		{
			usernameErrorString = null;
		}
		private function onUserCreated(resultEvent:ResultEvent):void
		{
			var user:ApplicationUser = resultEvent.token.user;
			
			// See SignInCommand for the actual sign-in logic
			broadcast(new SignInEvent(user));
		}
		private function onUserCreationFailed(faultEvent:FaultEvent):void
		{
			var rootCause:Object = faultEvent.fault.rootCause;
			if (rootCause is UsernameNotUniqueException)
			{
				usernameErrorString = "This username is taken.  Please try again";
				dispatchEvent(new Event(USERNAME_ERROR));
			}
		}
		
		// Parsley annotation.  This method is called if the sign-in fails.
		[CommandError]
		public function onSignInFailed(faultEvent:FaultEvent,trigger:SignInEvent):void
		{
			usernameErrorString = "Your username or password are incorrect.  Please try again";
			passwordErrorString = usernameErrorString;
			dispatchEvent(new Event(USERNAME_ERROR));
			dispatchEvent(new Event(PASSWORD_ERROR));
		}
	}
}