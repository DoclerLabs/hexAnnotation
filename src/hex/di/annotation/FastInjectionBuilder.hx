package hex.di.annotation;

#if macro
import haxe.ds.ArraySort;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Access;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.FieldType;
import hex.reflect.ClassReflectionData;
import hex.util.MacroUtil;

using Lambda;
#end

/**
 * ...
 * @author Francis Bourre
 */
class FastInjectionBuilder
{
	/** @private */ function new() throw new hex.error.PrivateConstructorException( "This class can't be instantiated." );

	#if macro
	static public function _generateInjectionProcessorExpr( fields : Array<Field>, data : ClassReflectionData ) : Void
    {
		var applyClassInjection : ExprOf<Dynamic->InjectorCall->Class<Dynamic>->Void> = null;
		var applyConstructorInjection : ExprOf<InjectorCall->Dynamic> = null;
		var applyPreDestroyInjection : ExprOf<Dynamic->Void> = null;
		
		var className 	= data.name;
		var type 		= macro $i { "type" };
		
		var expressions = [ macro {} ];
		var consExpression = [ macro {} ];
		expressions.push(macro var t = $i{ Context.getLocalClass().get().name });
		expressions.push(macro var f:hex.di.annotation.InjectorCall = i.getInstanceWithClassName);
		//constructor parsing
		var ctorArgProvider 	= [];
		var ctorAnn = data.constructor;

		if ( ctorAnn != null )
		{
			for ( i in 0...ctorAnn.arguments.length )
			{
				var inject 		= ctorAnn.annotations.find(function(e) return e.annotationName == "Inject");
				var key 		= inject != null ? inject.annotationKeys[ i ] : "";
				var optional 	= ctorAnn.annotations.find( function(e) return e.annotationName == "Optional");
				var isOpt 		= optional != null ? optional.annotationKeys[ i ] : false;

				var injectionName 	= key == null ? "" : key;
				var isOptional 		= isOpt == null ? true : isOpt;
				isOptional 			= !isOptional;
				ctorArgProvider.push( macro @:mergeBlock { cast f( $v { ctorAnn.arguments[ i ].type }, $v { injectionName }, null, $v { isOptional } );} );
			}
			
			//TODO make null provider
			var tp = MacroUtil.getTypePath( className );
			consExpression.push( macro @:mergeBlock { return new $tp( $a { ctorArgProvider } ); } );
			applyConstructorInjection = macro function g( f : hex.di.annotation.InjectorCall ) : Dynamic { $b{ consExpression }; };
		}

		//properties parsing
		var propValues: Array<Expr> = [];
		for ( property in data.properties )
		{
			var inject 		= property.annotations.find(function(e) return e.annotationName == "Inject");
			var key 		= inject != null ? inject.annotationKeys[ 0 ] : "";
			var optional 	= property.annotations.find(function(e) return e.annotationName == "Optional" );
			var isOpt 		= optional != null ? optional.annotationKeys[ 0 ] : false;

			var propertyName 	= property.name;
			var injectionName 	= key == null ? "" : key;
			var isOptional 		= isOpt == null ? true : isOpt;

			var providerID 		= 'p' + expressions.length;
			var provider 		= macro $i { providerID };
			isOptional 			= !isOptional;
			expressions.push( macro @:mergeBlock { this.$propertyName = f( $v { property.type }, $v { injectionName }, t, $v { isOptional } ); } );
		}
		
		//methods parsing
		var postConstructExprs: 	Array<Expr> = [];
		var preDestroyExprs: 		Array<Expr> = [];
		var methodExprs: 			Array<Expr> = [];
		
		for ( method in data.methods )
		{
			var argProviders 	= [];
			var methodName 		= method.name;
			
			var argData = method.arguments;
			for ( j in 0...argData.length )
			{
				var inject 			= method.annotations.find(function(e) return e.annotationName == "Inject");
				var key 			= inject != null ? inject.annotationKeys[ j ] : "";
				var optional 		= method.annotations.find(function(e) return e.annotationName == "Optional");
				var isOpt 			= optional != null ? optional.annotationKeys[ j ] : false;
				
				var injectionName 	= key == null ? "" : key;
				var isOptional 		= isOpt == null ? true : isOpt;
				isOptional 			= !isOptional;
				argProviders.push( macro @:mergeBlock { cast f( $v { argData[ j ].type }, $v { injectionName }, null, $v { isOptional } );} );
			}

			//method building
			var postConstruct 	= method.annotations.find(function(e) return e.annotationName == "PostConstruct");
			var preDestroy 		= method.annotations.find(function(e) return e.annotationName == "PreDestroy");
			var order 			= 0;

			if ( postConstruct != null )
			{
				order = postConstruct.annotationKeys[ 0 ];
				postConstructExprs.push( macro @:mergeBlock @:order($v{order==null?0:order}) { this.$methodName( $a{argProviders} ); } );
			}
			else if ( preDestroy != null )
			{
				order = preDestroy.annotationKeys[ 0 ];
				preDestroyExprs.push( macro @:mergeBlock @:order($v{order==null?0:order}) { this.$methodName( $a{argProviders} ); } );
			}
			else
			{
				methodExprs.push( macro @:mergeBlock { this.$methodName( $a{argProviders} ); } );
			}
		}
		
		if ( methodExprs.length > 0 ) 
		{
			expressions = expressions.concat( methodExprs );
		}
		
		if ( postConstructExprs.length > 0 ) 
		{
			ArraySort.sort( postConstructExprs, FastInjectionBuilder._sortExpressions );
			expressions = expressions.concat( postConstructExprs );
		}
		
		if ( preDestroyExprs.length > 0 ) 
		{
			ArraySort.sort( preDestroyExprs, FastInjectionBuilder._sortExpressions );
			applyPreDestroyInjection = macro function g() : Void { $b{ preDestroyExprs }; };
		}

		applyClassInjection = macro function g( instance : Dynamic, f : hex.di.annotation.InjectorCall ) : Void { $b { expressions }; };
		
		var aiAccess = _isOverriden( 'acceptInjector' ) ? [ Access.APublic, Access.APublic, Access.AOverride ] : [ Access.APublic, Access.APublic ];
		var apAccess = _isOverriden( '__ap' ) ? [ Access.APublic, Access.APublic, Access.AOverride ] : [ Access.APublic, Access.APublic ];
		//expressions.push( macro trace( this ) );
		fields.push(
		{
			name:  "acceptInjector",
			meta: [ { name: ":noCompletion", params: [], pos: Context.currentPos() },
					{ name: ":keep", params: [], pos: Context.currentPos() }
					],
			access:  aiAccess,
			kind: FieldType.FFun( 
				{
					args:  	[ { name: 'i', type: macro:hex.di.IBasicInjector, opt: false }],
					ret: 	macro : Void,
					expr:	macro $b { expressions }
				}
			), 
			pos: Context.currentPos(),
		});
		
		if ( applyConstructorInjection != null )
		{
			fields.push(
			{
				name:  "__ac",
				meta: [ 	{ name: ":noCompletion", params: [], pos: Context.currentPos() },
							{ name: ":keep", params: [], pos: Context.currentPos() }
						],
				access:  [ Access.APublic, Access.AStatic ],
				kind: FieldType.FFun( 
					{
						args:  	[ { name: 'f', type: macro:hex.di.annotation.InjectorCall, opt: false } ],
						ret: 	macro:Dynamic,
						expr:	macro $b{ consExpression }
					}
				), 
				pos: Context.currentPos(),
			});
		}

		if ( applyPreDestroyInjection != null )
		{
			fields.push(
			{
				name:  "__ap",
				meta: [ 	{ name: ":noCompletion", params: [], pos: Context.currentPos() },
							{ name: ":keep", params: [], pos: Context.currentPos() } 
						],
				access:  apAccess,
				kind: FieldType.FFun( 
					{
						args:  	[],
						ret: 	macro : Void,
						expr:	macro $b{ preDestroyExprs }
					}
				), 
				pos: Context.currentPos(),
			});
		}
	}
	
	static function _isOverriden( fieldName : String ) : Bool
	{
		var superClass = Context.getLocalClass().get().superClass;
		if ( superClass != null )
		{
			return superClass.t.get().fields.get().find( function( f ) return f.name == fieldName ) != null;
		}
		
		return false;
	}
	
	static function _sortExpressions( a : Expr, b : Expr ) : Int
	{
		return _getExpOrder( a ) - _getExpOrder( b );
	}
	
	static function _getExpOrder( e : Expr ) : Int
	{
		switch( e.expr )
		{
			case EMeta( _, _.expr => EMeta( s, _ ) ):
				switch( s.params )
				{
					case [ _.expr => EConst( CInt( i ) )]:
						return Std.parseInt( i );
					case _:
				}		
			case _:
		}
		return -1;
	}
	#end
}