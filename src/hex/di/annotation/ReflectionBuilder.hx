package hex.di.annotation;

import haxe.ds.ArraySort;
import haxe.macro.Context;
import haxe.macro.Expr;
import hex.di.reflect.ClassDescription;
import hex.error.PrivateConstructorException;
import hex.reflect.ClassReflectionData;

using Lambda;

/**
 * ...
 * @author Francis Bourre
 */
class ReflectionBuilder
{
#if macro
	/** @private */
    function new()
    {
        throw new PrivateConstructorException();
    }
	
	static function _sortExpr( a : Expr, b : Expr ) : Int
	{
		return _getOrder( a ) - _getOrder( b );
	}
	
	static function _getOrder( e : Expr ) : Int
	{
		switch( e.expr )
		{
			case EObjectDecl( fields ):
				for ( f in fields )
				{
					if ( f.field == 'o' )
					{
						switch( f.expr.expr )
						{
							case EConst( CInt( s ) ):
									return Std.parseInt( s );
							case _:
						}
					}
				}
			case _:
		}
		
		return -1;
	}
	
	public static function getClassDescriptionExpression( data : ClassReflectionData ) : ExprOf<ClassDescription>
    {
		//properties parsing
		var propValues: Array<Expr> = [];
		for ( property in data.properties )
		{
			var inject 				= property.annotations.find( function(e) return e.annotationName == "Inject" );
			var key					= inject != null ? inject.annotationKeys[ 0 ] : "";
			var optional 			= property.annotations.find( function(e) return e.annotationName == "Optional" );
			var isOpt : Null<Bool> 	= optional != null ? optional.annotationKeys[ 0 ] : false;
			
			var eProp = EObjectDecl([
				//propertyName
				{field: "p", expr: macro $v { property.name }}, 
				//propertyType
				{field: "t", expr: macro $v { property.type }},
				//injectionName
				{field: "n", expr: macro $v { key == null?"":key }},
				//isOptional
				{field: "o", expr: macro $v{isOpt==null?false:isOpt}}
			]);
			propValues.push( {expr: eProp, pos:Context.currentPos()} );
		}
		
		//methods parsing
		var postConstructValues: 	Array<Expr> = [];
		var preDestroyValues: 		Array<Expr> = [];
		var methodValues: 			Array<Expr> = [];
		
		for ( method in data.methods )
		{
			var argValues: Array<Expr> = [];
			var argData = method.arguments;
			for ( j in 0...argData.length )
			{
				var inject 				= method.annotations.find( function(e) return e.annotationName == "Inject" );
				var key 				= inject != null ? inject.annotationKeys[ j ] : "";
				var optional 			= method.annotations.find( function(e) return e.annotationName == "Optional" );
				var isOpt : Null<Bool> 	= optional != null ? optional.annotationKeys[ j ] : false;
				
				var eArg = EObjectDecl([
					//type
					{field: "t", expr: macro $v { argData[ j ].type }},
					//injectionName
					{field: "n", expr: macro $v { key == null?"":key }},
					//isOptional
					{field: "o", expr: macro $v{isOpt==null?false:isOpt}}
				]);
				
				argValues.push( { expr: eArg, pos:Context.currentPos() } );
			}

			//method building
			var postConstruct 		= method.annotations.find( function(e) return e.annotationName == "PostConstruct" );
			var preDestroy	 		= method.annotations.find( function(e) return e.annotationName == "PreDestroy" );
			var order : Null<Int> 	= 0;

			if ( postConstruct != null )
			{
				order = postConstruct.annotationKeys[ 0 ];
				var eMethod = EObjectDecl([
					//methodName
					{field: "m", expr: macro $v { method.name }},
					//args
					{field: "a", expr: { expr:EArrayDecl(argValues), pos: Context.currentPos() }},
					//order
					{field: "o", expr: macro $v{order==null?0:order}}
				]);
				
				postConstructValues.push( { expr: eMethod, pos: Context.currentPos() } );
			}
			else if ( preDestroy != null )
			{
				order = preDestroy.annotationKeys[ 0 ];
				var eMethod = EObjectDecl([
					//methodName
					{field: "m", expr: macro $v { method.name }},
					//args
					{field: "a", expr: { expr:EArrayDecl(argValues), pos: Context.currentPos() }},
					//order
					{field: "o", expr: macro $v{order==null?0:order}}
				]);
				
				preDestroyValues.push( {expr: eMethod, pos: Context.currentPos()} );
			}
			else
			{
				var eMethod = EObjectDecl([
					//methodName
					{field: "m", expr: macro $v { method.name }},
					//args
					{field: "a", expr: {expr:EArrayDecl(argValues), pos: Context.currentPos()}}
				]);
				
				methodValues.push( { expr: eMethod, pos: Context.currentPos() } );
			}
		}
		
		if ( postConstructValues.length > 0 ) ArraySort.sort( postConstructValues, ReflectionBuilder._sortExpr );
		if ( preDestroyValues.length > 0 ) ArraySort.sort( preDestroyValues, ReflectionBuilder._sortExpr );

		//constructor parsing
		var ctorArgValues: Array<Expr> = [];
		var ctorAnn = data.constructor;

		if ( ctorAnn != null )
		{
			for ( i in 0...ctorAnn.arguments.length )
			{
				var inject 				= ctorAnn.annotations.find( function(e) return e.annotationName == "Inject" );
				var key 				= inject != null ? inject.annotationKeys[ i ] : "";
				var optional 			= ctorAnn.annotations.find( function(e) return e.annotationName == "Optional" );
				var isOpt : Null<Bool> 	= optional != null ? optional.annotationKeys[ i ] : false;
				
				var eCtorArg = EObjectDecl([
					//type
					{field: "t", expr: macro $v { ctorAnn.arguments[ i ].type }},
					//injectionName
					{field: "n", expr: macro $v { key == null?"":key }},
					//isOptional
					{field: "o", expr: macro $v{isOpt == null?false:isOpt}}
				]);
				
				ctorArgValues.push( { expr: eCtorArg, pos:Context.currentPos() } );
			}
		}

		var ctor = EObjectDecl([
				//args
				{field: "a", expr: {expr:EArrayDecl(ctorArgValues), pos: Context.currentPos()}}
			]);
		
			
		var finalExpressions = [];
		
		//constructorInjection
		finalExpressions.push( {field: "c", expr: { expr: ctor, pos: Context.currentPos() }} );

		//properties
		finalExpressions.push( {field: "p", expr: { expr: EArrayDecl(propValues), pos: Context.currentPos() }} );

		//methods
		finalExpressions.push( {field: "m", expr: { expr: EArrayDecl(methodValues), pos: Context.currentPos() }} );

		//postConstruct
		finalExpressions.push( {field: "pc", expr: { expr: EArrayDecl(postConstructValues), pos: Context.currentPos() }} );

		//preDestroy
		finalExpressions.push( {field: "pd", expr: {expr: EArrayDecl(preDestroyValues), pos: Context.currentPos()}} );

		//final expression
		var classDescription = EObjectDecl( finalExpressions );
		return { expr: classDescription, pos: Context.currentPos() };
	}
#end
}
