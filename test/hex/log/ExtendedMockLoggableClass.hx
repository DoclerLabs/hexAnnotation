package hex.log;

/**
 * ...
 * @author Francis Bourre
 */
class ExtendedMockLoggableClass extends MockLoggableClass
{
	
}

class AnotherExtendedMockLoggableClass extends ExtendedMockLoggableClass
{
	
}

class MockLoggableClassWithCustomLogger implements IsLoggable
{
	public var myLogger:ILogger;
	
	public function new() 
	{
	}
	
	@Debug
	public function callDebug()
	{
		
	}
	
}

class ExtendsLoggableWithCustomLogger extends MockLoggableClassWithCustomLogger
{
	
	@Debug
	public function callDebugExtend()
	{
		
	}
}

class ClassWithCustomLogger
{
	public var custom:ILogger;
	
	public function new() 
	{
	}
	
}

class MockLoggableWithExtendsCustomLogger extends ClassWithCustomLogger implements IsLoggable
{
	
	@Debug
	public function callDebugExtend()
	{
		
	}
}

class ExtendsLoggableAndOverridesLogger extends MockLoggableClassWithCustomLogger
{
	public var overriddenLogger:ILogger;
	
	@Debug
	public function callDebugExtend()
	{
		
	}
}

class ClassWithVariableWithoutType implements IsLoggable
{
	var unknown = "unknown";
	
	public function new() 
	{
	}
}

class ClassThatExtendsClassWithVariableWithoutType extends ClassWithVariableWithoutType implements IsLoggable
{
	
}