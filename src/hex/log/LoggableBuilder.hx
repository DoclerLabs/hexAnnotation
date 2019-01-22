package hex.log;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import hex.di.annotation.AnnotationTransformer;
import hex.util.MacroUtil;

using haxe.macro.Tools;
using hex.error.Error;

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
		
		var shouldAddField = true;
		var loggerName = "";
		
		var isLogger = function(t:ComplexType):Bool
		{
			return (t == null) ? false : switch(t)
			{
				case macro :ILogger: true;
				case macro :hex.log.ILogger: true;
				case _: false;
			};
		}
		
		var tryLoggerName = function(f:{name:String, pos:Position})
		{
			if (loggerName == "")
			{
				loggerName = f.name;
				shouldAddField = false;
				//trace("Using custom logger variable: " + loggerName);
			}
			else
			{
				Context.warning("There is already one logger with name '" + loggerName+"' which will be used for logger calls", f.pos);
			}
		}
		
		
		//try to get a loggerName from local class
		for ( f in fields )
		{
			switch(f.kind)
			{
				case FVar(t) | FProp(_, _, t) if (isLogger(t)) :
					tryLoggerName(f);
				case _:
			}
		}
		
		if(loggerName == "")
		{
			// no local logger found, scan superclasses
			var superClass = Context.getLocalClass().get().superClass;
			while ( superClass != null )
			{
				
				var classType = MacroUtil.getClassType( superClass.t.toString() );
				
				for (field in classType.fields.get())
				{
					switch(field.kind)
					{
						case FVar(_, _) if (isLogger(field.type.toComplexType())):
							tryLoggerName(field);
						case _:
					}
				}
				
				if(loggerName == "")
				{
					//still no logger name, we have to go higher
					superClass = classType.superClass;
				}
				else
				{
					//logger name found, no reason to go higher
					superClass = null;
				}
			}
		}
		
		if ( shouldAddField )
		{
			loggerName = "logger";
			
			fields.push({ 
				kind: FVar(TPath( { name: "ILogger", pack:  [ "hex", "log" ], params: [] } ), null ), 
		meta: [ { name: "Inject", params: [], pos: Context.currentPos() }, { name: "Optional", params: [macro true], pos: Context.currentPos() }, { name: ":noCompletion", params: [], pos: Context.currentPos() } ], 
				name: loggerName, 
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
					
						var logSetting =  LoggableBuilder._getParameters( meta );
						
						var methArgs : Array<Expr> = [];
						var argsMsg : Array<String> = [];
						var expressions = [ macro @:mergeBlock { } ];
						var argPlaceholer = "='{}'";
						
						if ( logSetting.arg == null )
						{
							func.args.map(function(arg){
								argsMsg.push($v{arg.name} + argPlaceholer);
								methArgs.push(macro @:pos(f.pos) $i { arg.name });
							});
						}
						else
						{
							var printer = new Printer();
							logSetting.arg.map(function(arg){
								argsMsg.push($v{printer.printExpr(arg)} + argPlaceholer);
								methArgs.push(macro @:pos(f.pos) $arg);
							});
						}
						
						//
						var message = logSetting.message;
						var debugArgs = [];
						if ( message == null )
						{
							message = "{}(" + argsMsg.join(", ") + ")";
							debugArgs = [ macro @:pos(f.pos) $v { f.name } ].concat( methArgs );
						}
						else
						{
							if(logSetting.includeArgs && argsMsg != null)
							{
								message += " [" + argsMsg.join(", ") + "]";
							}
							debugArgs = methArgs;
						}
						var methodName = meta[ 0 ].name.toLowerCase();
						
						var body = macro @:pos(f.pos) @:mergeBlock
						{
							$i{loggerName}.$methodName( $v{ message }, [ $a { debugArgs } ] );
						};

						expressions.push( body );
						expressions.push( func.expr );
						func.expr = macro @:pos(f.pos) $b { expressions };
						
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

		return AnnotationTransformer.reflect( macro hex.di.IInjectorContainer, fields );
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
								case "includeArgs":
									switch( f.expr.expr )
									{
										case EConst( CIdent( s ) ):
											logSetting.includeArgs = (s == "true");

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
	public var message 		: String;
	public var arg 			: Array<Expr>;
	public var includeArgs	: Bool;
}