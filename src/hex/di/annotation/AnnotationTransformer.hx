package hex.di.annotation;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.Field;
import hex.annotation.AnnotationReplaceBuilder;
import hex.error.PrivateConstructorException;
import hex.reflect.ClassReflectionData;
import hex.util.MacroUtil;

using Lambda;

/**
 * ...
 * @author Francis Bourre
 */
class AnnotationTransformer
{
#if macro
	private static var _map : Map<String, Bool> = new Map();
	
	/** @private */ function new() throw new PrivateConstructorException();
    	
	macro public static function readMetadata( metadataExpr : Expr ) : Array<Field>
	{
		return //if it's an interface we don't want to build reflection data
			if ( Context.getLocalClass().get().isInterface ) Context.getBuildFields();
			else reflect( metadataExpr, Context.getBuildFields() );
	}
	
	public static function reflect( metadataExpr : Expr, fields : Array<Field>  ) : Array<Field>
	{
		var localClass 		= Context.getLocalClass().get();
		var className 		= localClass.pack.join( "." ) + "." + localClass.name;
		var hasBeenBuilt 	= AnnotationTransformer._map.exists( className );
		var annotationFilter = [ "Inject", "PostConstruct", "Optional", "PreDestroy" ];
		
		var data : ClassReflectionData; //Reflection data to be used to generate fields
		
		// use AnnotationReplaceBuilder to to process the metadata but only the ones that we care about
		fields
			.flatMap( function ( f ) return f.meta )
			.filter( function ( m ) return annotationFilter.indexOf( m.name ) != -1 )
			.map( AnnotationReplaceBuilder.processMetadata );
		
		if ( hasBeenBuilt )
		{
			// get the existing data and remove them from the static_classes
			var existingData = hex.reflect.ReflectionBuilder._static_classes.find( function(d) return d.name == MacroUtil.getClassName( localClass ) );
			hex.reflect.ReflectionBuilder._static_classes.remove( existingData );
			
			// reflect new fields
			fields = hex.reflect.ReflectionBuilder.parseMetadata( metadataExpr, fields, annotationFilter, false );
			
			// get new fields
			data = hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ];
			
			//merge everything together
			data = mergeReflectionData( existingData, data );
			
			//write the merged data back
			hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ] = data;
		}
		else
		{
			//parse annotations
			fields = hex.reflect.ReflectionBuilder.parseMetadata( metadataExpr, fields, annotationFilter, false );
			
			//get/set data result
			data = hex.reflect.ReflectionBuilder._static_classes[ hex.reflect.ReflectionBuilder._static_classes.length - 1 ];
			
			var superClass = Context.getLocalClass().get().superClass;
			if ( superClass != null )
			{
				var superData = hex.reflect.ReflectionBuilder._static_classes.find( function(d) return d.name == MacroUtil.getClassName( superClass.t.get() ) );
				if ( superData != null )
				{
					data = mergeReflectionData( superData, data );
				}
			}
		}
		
		AnnotationTransformer._map.set( className, true );
		
		var f = fields.filter( function ( f ) { return f.name == "acceptInjector" || f.name == "__ac" || f.name == "__ap"; } );
		
		//remove existing reflection data
		if ( f.length != 0 ) for ( removedField in f ) fields.remove( removedField );
		
		// Generate and append fields
		hex.di.annotation.FastInjectionBuilder._generateInjectionProcessorExpr( fields, data );
		return fields;
	}
	
	static private function mergeReflectionData( existingData : ClassReflectionData, newData : ClassReflectionData ) : ClassReflectionData
	{
		var properties = existingData.properties.copy().filter( 
			function ( prop ) 
			{
				for ( p in newData.properties ) if ( p.name == prop.name ) return false;
				return true;
			}
		).concat( newData.properties );
		
		var methods = existingData.methods.copy().filter( 
			function ( meth ) 
			{
				for ( m in newData.methods )if ( m.name == meth.name ) return false;
				return true;
			}
		).concat( newData.methods );

		return 
		{
			name: 			newData.name,
			superClassName: newData.superClassName,
			constructor: 	newData.constructor != null ? newData.constructor : existingData.constructor,
			properties: 	properties,
			methods: 		methods
		};
	}
#end
}
