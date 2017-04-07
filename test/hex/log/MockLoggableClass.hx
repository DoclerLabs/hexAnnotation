package hex.log;

import hex.log.IsLoggable;

/**
 * ...
 * @author Francis Bourre
 */
class MockLoggableClass implements IsLoggable
{
	public var member : String = "member";
	
	public function new() 
	{
		
	}
	
	@Debug
	public function debug( s : String, i : Int ) : Void
	{
		
	}
	
	@Info
	public function info( s : String, i : Int ) : Void
	{
		
	}
	
	@Warn
	public function warn( s : String, i : Int ) : Void
	{
		
	}
	
	@Error
	public function error( s : String, i : Int ) : Void
	{
		
	}
	
	@Fatal
	public function fatal( s : String, i : Int ) : Void
	{
		
	}
	
	@Debug({
		msg: "customMessage" 
	})
	public function debugCustomMessage( s : String, i : Int ) : Void
	{
		
	}

	@Debug({
		msg: "anotherMessage",
		arg: [ i, this.member ] 
	})
	public function debugCustomArgument( s : String, i : Int ) : Void
	{
		
	}
	
	@Debug({
		msg: "customMessage",
		includeArgs: true
	})
	public function debugCustomMessageWithIncludedArgs( s : String, i : Int ) : Void
	{
		
	}

	@Debug({
		msg: "anotherMessage",
		arg: [ i, this.member ],
		includeArgs: true
	})
	public function debugCustomArgumentWithIncludedArgs( s : String, i : Int ) : Void
	{
		
	}

	@Debug({
		arg: [ i, this.member ]
	})
	public function debugCustomArgumentOnly( s : String, i : Int ) : Void
	{
		
	}
	
	
}