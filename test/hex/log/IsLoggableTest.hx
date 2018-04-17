package hex.log;

import hex.unittest.assertion.Assert;

/**
 * ...
 * @author Francis Bourre
 */
class IsLoggableTest 
{
	public var loggable 	: MockLoggableClass;
	public var extLoggable 	: ExtendedMockLoggableClass;
	public var logger		: MockLogger;
	
	@Before
	public function setUp(): Void
	{
		loggable 		= new MockLoggableClass();
		logger 			= new MockLogger();
		loggable.logger = logger;
	}
	
	@Test( "test debug" )
	public function testDebug(): Void
	{
		loggable.debug( "debug", 1 );
		var args : Array<Dynamic> = [ "debug", "debug", 1 ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals("{}(s='{}', i='{}')", logger.debugMsg);
		Assert.isNull( logger.infoParams );
		Assert.isNull( logger.warnParams );
		Assert.isNull( logger.errorParams );
		Assert.isNull( logger.fatalParams );
	}
	
	@Test( "test info" )
	public function testInfo(): Void
	{
		loggable.info( "info", 2 );
		var args : Array<Dynamic> = [ "info", "info", 2 ];
		
		Assert.deepEquals( args, logger.infoParams );
		Assert.equals("{}(s='{}', i='{}')", logger.infoMsg);
		Assert.isNull( logger.debugParams );
		Assert.isNull( logger.warnParams );
		Assert.isNull( logger.errorParams );
		Assert.isNull( logger.fatalParams );
	}
	
	@Test( "test warn" )
	public function testWarn(): Void
	{
		loggable.warn( "warn", 3 );
		var args : Array<Dynamic> = [ "warn", "warn", 3 ];
		
		Assert.deepEquals( args, logger.warnParams );
		Assert.equals("{}(s='{}', i='{}')", logger.warnMsg);
		Assert.isNull( logger.debugParams );
		Assert.isNull( logger.infoParams );
		Assert.isNull( logger.errorParams );
		Assert.isNull( logger.fatalParams );
	}
	
	@Test( "test error" )
	public function testError(): Void
	{
		loggable.error( "error", 4 );
		var args : Array<Dynamic> = [ "error", "error", 4 ];
		
		Assert.deepEquals( args, logger.errorParams );
		Assert.equals("{}(s='{}', i='{}')", logger.errorMsg);
		Assert.isNull( logger.debugParams );
		Assert.isNull( logger.infoParams );
		Assert.isNull( logger.warnParams );
		Assert.isNull( logger.fatalParams );
	}
	
	@Test( "test fatal" )
	public function testFatal(): Void
	{
		loggable.fatal( "fatal", 5 );
		var args : Array<Dynamic> = [ "fatal", "fatal", 5 ];
		
		Assert.deepEquals( args, logger.fatalParams );
		Assert.equals("{}(s='{}', i='{}')", logger.fatalMsg);
		Assert.isNull( logger.debugParams );
		Assert.isNull( logger.infoParams );
		Assert.isNull( logger.warnParams );
		Assert.isNull( logger.errorParams );
	}
	
	@Test( "test custom message" )
	public function testCustomMessage(): Void
	{
		loggable.debugCustomMessage( "debug", 6 );
		var message = "customMessage";
		var args : Array<Dynamic> = [ "debug", 6 ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoParams );
		Assert.isNull( logger.warnParams );
		Assert.isNull( logger.errorParams );
		Assert.isNull( logger.fatalParams );
	}
	
	@Test( "test custom arguments with custom message" )
	public function testCustomArgumentsWithCustomMessage(): Void
	{
		loggable.debugCustomArgument( "debug", 7 );
		var message = "anotherMessage";
		var args : Array<Dynamic> = [ 7, "member" ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test custom message with included arguments" )
	public function testCustomMessageWithIncludedArguments(): Void
	{
		loggable.debugCustomMessageWithIncludedArgs( "debug", 8 );
		var message = "customMessage [s='{}', i='{}']";
		var args : Array<Dynamic> = [ "debug", 8 ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test custom message with custom arguments with included arguments" )
	public function testCustomMessageWithCustomArgumentsWithIncludedArguments(): Void
	{
		loggable.debugCustomArgumentWithIncludedArgs( "debug", 9 );
		var message = "anotherMessage [i='{}', this.member='{}']";
		var args : Array<Dynamic> = [ 9, "member" ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test custom arguments only" )
	public function testCustomArgumentsOnly(): Void
	{
		loggable.debugCustomArgumentOnly( "debug", 10 );
		var message = "{}(i='{}', this.member='{}')";
		var args : Array<Dynamic> = [ "debugCustomArgumentOnly", 10, "member" ];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test no arguments" )
	public function testNoArguments(): Void
	{
		loggable.debugNoArgs();
		var message = "{}()";
		var args : Array<Dynamic> = ["debugNoArgs"];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test no arguments with custom message" )
	public function testNoArgumentsCustomMessage(): Void
	{
		loggable.debugNoArgsCustomMessage();
		var message = "no arguments";
		var args : Array<Dynamic> = [];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test no arguments with custom arguments" )
	public function testNoArgumentsCustomArgs(): Void
	{
		loggable.debugNoArgsCustomArgs();
		var message = "{}(this.member='{}')";
		var args : Array<Dynamic> = ["debugNoArgsCustomArgs","member"];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test no arguments with custom message, custom arguments and includeArgs" )
	public function testNoArgumentsCustomArgsCustomMessageIncludeArgs(): Void
	{
		loggable.debugNoArgsCustomMsgCustomArgsIncludeArgs();
		var message = "custom message [this.member='{}']";
		var args : Array<Dynamic> = ["member"];
		
		Assert.deepEquals( args, logger.debugParams );
		Assert.equals(message, logger.debugMsg);
		Assert.isNull( logger.infoMsg );
		Assert.isNull( logger.warnMsg );
		Assert.isNull( logger.errorMsg );
		Assert.isNull( logger.fatalMsg );
	}
	
	@Test( "test interfaces implementation order" )
	public function testInterfacesImplementationOrder() : Void
	{
		var loggable = new MockLoggableClassInjected();
		var f = function( s: String, n: String, c: Class<Dynamic>, o: Bool ): Dynamic  return this.logger;
		loggable.acceptInjector( cast { getInstanceWithClassName: f } );
		Assert.equals( this.logger, loggable.logger, "'MockLoggableClassInjected' should have reflection data for its logger property" );
	}
}
