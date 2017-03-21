package hex.log;

import haxe.macro.Context;
import haxe.macro.Expr;
import hex.di.annotation.FastAnnotationReader;
import hex.error.PrivateConstructorException;
import hex.util.MacroUtil;

/**
 * ...
 * @author Francis Bourre
 */
class LoggableBuilder
{
#if macro

	public static inline var DebugAnnotation 	= "Debug";
	public static inline var InfoAnnotation 	= "Info";
	public static inline var WarnAnnotation 	= "Warn";
	public static inline var ErrorAnnotation 	= "Error";
	public static inline var FatalAnnotation 	= "Fatal";
	
	/** @private */
    function new()
    {
        throw new PrivateConstructorException( "This class can't be instantiated." );
    }
	
	macro static public function build() : Array<Field> 
	{
		var fields = Context.getBuildFields();

		if ( Context.getLocalClass().get().isInterface )
		{
			return fields;
		}
		
		for ( f in fields )
		{
			if ( f.name == "logger" )
			{
				Context.error( "'logger' member will be added automatically in class that implements 'IsLoggable'", f.pos );
			}
		}
		
		var shouldAddField = true;
		var superClass = Context.getLocalClass().get().superClass;
		if ( superClass != null )
		{
			var classType = MacroUtil.getClassType( superClass.t.toString() );
			if ( MacroUtil.implementsInterface( classType, MacroUtil.getClassType( Type.getClassName( IsLoggable ) ) ) )
			{
				shouldAddField = false;
			}
		}
		
		if ( shouldAddField )
		{
			fields.push({ 
				kind: FVar(TPath( { name: "ILogger", pack:  [ "hex", "log" ], params: [] } ), null ), 
		meta: [ { name: "Inject", params: [], pos: Context.currentPos() }, { name: "Optional", params: [macro true], pos: Context.currentPos() }, { name: ":noCompletion", params: [], pos: Context.currentPos() } ], 
				name: "logger", 
				access: [ Access.APublic ],
				pos: Context.currentPos()
			});
		}
		
		
		var className = Context.getLocalClass().get().module;
		var loggerAnnotations = [ DebugAnnotation, InfoAnnotation, WarnAnnotation, ErrorAnnotation, FatalAnnotation ];

		for ( f in fields )
		{
			switch( f.kind )
			{
				case FFun( func ):
					
					var meta = f.meta.filter( function ( m ) { return loggerAnnotations.indexOf( m.name ) != -1; } );
					var isLoggable = meta.length > 0;
					if ( isLoggable ) 
					{
						if ( f.name == "new" )
						{
							Context.error( "log metadata is forbidden on constructor", f.pos );
						}
					
						#if debug
						var logSetting =  LoggableBuilder._getParameters( meta );
						
						var methArgs : Array<Expr> = null;
						var expressions = [ macro @:mergeBlock { } ];
						if ( logSetting.arg == null )
						{
							methArgs = [ for ( arg in func.args ) macro @:pos(f.pos) $i { arg.name } ];
						}
						else
						{
							methArgs = [ for ( arg in logSetting.arg ) macro @:pos(f.pos) $arg ];
						}
						
						//
						var message = logSetting.message;
						if ( message == null )
						{
							message = className + '::' + f.name;
						}
						var debugArgs = [ macro @:pos(f.pos) $v { message } ].concat( methArgs );
						var methodName = meta[ 0 ].name.toLowerCase();
		
						var body = macro @:pos(f.pos) @:mergeBlock
						{
							if ( logger == null ) logger = ${hex.log.HexLog.getLoggerCall()};
							logger.$methodName( [$a { debugArgs } ] );
						};

						expressions.push( body );
						expressions.push( func.expr );
						func.expr = macro @:pos(f.pos) $b { expressions };
						#end
						
						for ( m in meta )
						{
							if ( loggerAnnotations.indexOf( m.name ) != -1 )
							{
								f.meta.remove( m );
							}
						}
					}
					
				case _:
			}
			
		}
		
		return FastAnnotationReader.reflect( macro hex.di.IInjectorContainer, fields );
	}
	
	static function _getParameters( meta : Metadata ) : LogSetting
	{
		for ( m in meta )
		{
			var params = m.params;
			if ( params.length > 1 )
			{
				Context.warning( "Only one argument is allowed", m.pos );
			}
			
			for ( p in params )
			{
				var e = switch( p.expr )
				{
					case EObjectDecl( o ):
						
						var logSetting = new LogSetting();
						
						for ( f in o )
						{
							switch( f.field )
							{
								case "msg":
									switch( f.expr.expr )
									{
										case EConst( CString( s ) ):
											logSetting.message = s;

										case _: null;
									}
									
								case "arg":
									switch( f.expr.expr )
									{
										case EArrayDecl( a ):
											logSetting.arg = a;

										case _: null;
									}
									
								case _: null;
							}
						}

						
					
						return logSetting;
						
					case _: null;
				}
				
				//
			}
		}
		return new LogSetting();
	}
#end
}

private class LogSetting
{
	public function new(){}
	public var message 	: String;
	public var arg 		: Array<Expr>;
}