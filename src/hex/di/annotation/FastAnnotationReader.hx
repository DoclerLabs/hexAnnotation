package hex.di.annotation;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import hex.annotation.AnnotationReplaceBuilder;
import hex.di.reflect.ClassDescription;
import hex.error.PrivateConstructorException;
import hex.reflect.ClassReflectionData;

using Lambda;

/**
 * ...
 * @author Francis Bourre
 */
class FastAnnotationReader
{
#if macro
	private static var _map : Map<String, ExprOf<ClassDescription>> = new Map();
	
	/** @private */
    function new()
    {
        throw new PrivateConstructorException();
    }
	
	macro public static function readMetadata( metadataExpr : Expr ) : Array<Field>
	{
		//if it's an interface we don't want to build reflection data
		if ( Context.getLocalClass().get().isInterface )
		{
			return Context.getBuildFields();
		}

		return reflect( metadataExpr, Context.getBuildFields() );
	}
	
	public static function reflect( metadataExpr : Expr, fields : Array<Field>  ) : Array<Field>
	{
		var localClass 		= Context.getLocalClass().get();
		var className 		= localClass.pack.join( "." ) + "." + localClass.name;
		var hasBeenBuilt 	= FastAnnotationReader._map.exists( className );
		
		var reflectionData:Null<ExprOf<ClassDescription>>;
		
		var annotationFilter = [ "Inject", "PostConstruct", "Optional", "PreDestroy" ];
		
		// use AnnotationReplaceBuilder to to process the metadata but only the ones that we care about
		fields
			.flatMap(function (f) return f.meta)
			.filter(function (m) return annotationFilter.indexOf(m.name) != -1)
			.map(AnnotationReplaceBuilder.processMetadata);
		
		if ( hasBeenBuilt )
		{
			// get the existing data and remove them from the static_classes
			var existingData = hex.reflect.ReflectionBuilder._static_classes.find( function(d) return d.name == localClass.module );
			hex.reflect.ReflectionBuilder._static_classes.remove(existingData);
			
			// reflect new fields
			fields = hex.reflect.ReflectionBuilder.parseMetadata( metadataExpr, fields, annotationFilter, false );
			
			// get new fields
			var data = hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ];
			
			//merge everything together
			var mergedData = mergeReflectionData(existingData, data);
			
			//write the merged data back
			hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ] = mergedData;
			
			//get complete reflection data
			reflectionData = hex.di.annotation.ReflectionBuilder.getClassDescriptionExpression( mergedData );
		}
		else
		{
			//parse annotations
			fields = hex.reflect.ReflectionBuilder.parseMetadata( metadataExpr, fields, annotationFilter, false );
			
			//get/set data result
			var data = hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ];
			
			//get reflection data
			reflectionData = hex.di.annotation.ReflectionBuilder.getClassDescriptionExpression( data );
		}
		
		FastAnnotationReader._map.set( className, reflectionData );
		
		var f = fields.filter( function ( f ) { return f.name == "__INJECTION_DATA"; } );
		if ( f.length != 0 )
		{
			//remove existing reflection data
			fields.remove( f[ 0 ] );
		}
		
		// append the expression as a field
		fields.push(
		{
			name:  "__INJECTION_DATA",
			access:  [ Access.APublic, Access.AStatic ],
			kind: FieldType.FVar( macro: hex.di.reflect.ClassDescription, reflectionData ),
			meta: [ { name: ":noDoc", params: null, pos: Context.currentPos() } ],
			pos: Context.currentPos()
		});

		return fields;
	}
	
	static private function mergeReflectionData(data1:ClassReflectionData, data2:ClassReflectionData):ClassReflectionData
	{
		return {
			name: data1.name,
			superClassName: data1.superClassName,
			constructor: data2.constructor, // using constructor from the new data (nothing to merge here)
			properties: data1.properties.concat(data2.properties),
			methods: data1.methods.concat(data2.methods)
		};
	}
	
#end
}
