package hex.annotation;

import haxe.macro.Context;
import haxe.macro.Expr;
import hex.error.PrivateConstructorException;

/**
 * ...
 * @author Francis Bourre
 */
class AnnotationReader
{
	public static var _static_classes : Array<ClassAnnotationData> = [];

	/** @private */
    function new()
    {
        throw new PrivateConstructorException( "This class can't be instantiated." );
    }

	macro public static function readMetadata( metadataExpr : Expr, allowedAnnotations : Array<String> = null ) : Array<Field>
	{
		var localClass = Context.getLocalClass().get();
		
		//parse annotations
		var fields : Array<Field> = AnnotationReader.parseMetadata( metadataExpr, Context.getBuildFields(), allowedAnnotations );
		
		//get data result
		var data = AnnotationReader._static_classes[ AnnotationReader._static_classes.length - 1 ];

		//append the expression as a field
		fields.push(
		{
			name:  "__INJECTION_DATA",
			access:  [ Access.APublic, Access.AStatic ],
			kind: FieldType.FVar( macro: hex.annotation.ClassAnnotationData, macro $v{ data } ), 
			pos: Context.currentPos(),
		});
		
		return fields;
	}
	
	#if macro
	public static function parseMetadata( metadataExpr : Expr, classFields : Array<Field>, allowedAnnotations : Array<String> = null, displayWarning : Bool = false ) : Array<Field>
	{
		//parse metadata name
		var metadataName = switch( metadataExpr.expr )
		{
			case EConst( c ):
				switch ( c )
				{
					case CIdent( v ):
						hex.util.MacroUtil.getClassNameFromExpr( metadataExpr );

					default: 
						null;
				}

			case EField( e, field ):
				haxe.macro.ExprTools.toString( e ) + "." + field;

			default: null;
		}
		
		var localClass = Context.getLocalClass().get();
		var superClassName : String;
		var superClassAnnotationData : ClassAnnotationData = null;

		var superClass = Context.getLocalClass().get().superClass;
		if ( superClass != null )
		{
			superClassName = superClass.t.get().module;
			for ( classAnnotationData in AnnotationReader._static_classes )
			{
				if ( classAnnotationData.name == superClassName )
				{
					superClassAnnotationData = classAnnotationData;
					break;
				}
			}
		}
		
		var constructorAnnotationData : MethodAnnotationData = null;

		var properties : Array<PropertyAnnotationData>	= [];
		if ( superClassAnnotationData != null )
		{
			properties = properties.concat( superClassAnnotationData.properties );
		}

		var methods 	: Array<MethodAnnotationData>	= [];
		if ( superClassAnnotationData != null )
		{
			methods = methods.concat( superClassAnnotationData.methods );
		}

		for ( f in classFields )
		{
			var annotationDatas : Array<AnnotationData> = [];
			var metaID = f.meta.length -1;
			
			while ( metaID > -1 )
			{
				var m = f.meta[ metaID ];
				var annotationKeys : Array<Dynamic> = [];
				if ( allowedAnnotations == null || allowedAnnotations.indexOf( m.name )  != -1 )
				{
					for ( param in m.params )
					{
						switch( param.expr )
						{
							case EConst( c ):
								switch ( c )
								{
									case CInt( s ):
										var i = Std.parseInt( s );
										annotationKeys.push(  ( i != null ) ? i : Std.parseFloat( s ) ); // if the number exceeds standard int return as float

									case CFloat( s ):
										annotationKeys.push(  Std.parseFloat( s ) );

									case CString( s ):
										annotationKeys.push( s );

									case CIdent( "null" ):
										annotationKeys.push( null );

									case CIdent( "true" ):
										annotationKeys.push( true );

									case CIdent("false"):
										annotationKeys.push( false );

									case CRegexp( r, opt ):
										//do nothing

									case CIdent( v ):
										annotationKeys.push( hex.util.MacroUtil.getClassNameFromExpr( param ) );

									default: 
										null;
								}
							case EField( e, field ):
								annotationKeys.push( haxe.macro.ExprTools.toString( e ) + "." + field );

							default: null;
						}
					}
					annotationDatas.unshift( { annotationName: m.name, annotationKeys: annotationKeys } );
					f.meta.remove( m );//remove metadata
				}
				else if ( displayWarning && m.name.charAt( 0 ) != ":" )
				{
					Context.warning( "Warning: Unregistered annotation '@" + m.name + "' found on field '" + Context.getLocalClass().get().module + "::" + f.name + "'", m.pos );
				}
				metaID--;
			}

			if ( annotationDatas.length > 0 )
			{
				switch ( f.kind )
				{
					case FVar( TPath( p ), e ):
						var t : haxe.macro.Type = null;
						try
						{
							t = Context.getType( p.pack.concat( [ p.name ] ).join( '.' ) );
						}
						catch ( e : Dynamic )
						{
							Context.error( e, f.pos );
						}
						
						var propertyType : String = "";
						switch ( t )
						{
							case TInst( t, p ):
								var ct = t.get();
								propertyType = ct.pack.concat( [ct.name] ).join( '.' );
								
							case TAbstract( t, params ):
								propertyType = t.toString();
								
							case TDynamic( t ):
								propertyType = "Dynamic";
								
							default:
						}

						properties.push( { annotationDatas: annotationDatas, propertyName: f.name, propertyType: propertyType } );

					case FFun( func ) :
						var argumentDatas : Array<hex.annotation.ArgumentData> = [];
						for ( arg in func.args )
						{
							switch ( arg.type )
							{
								case TPath( p ):
									var t : haxe.macro.Type = null;
									try
									{
										t = Context.getType( p.pack.concat( [ p.name ] ).join( '.' ) );
									}
									catch ( e : Dynamic )
									{
										Context.error( e, f.pos );
									}

									var argumentType : String = "";
									switch ( t )
									{
										case TInst( t, p ):
											var ct = t.get();
											argumentType = ct.pack.concat( [ct.name] ).join( '.' );
											
										case TAbstract( t, params ):
											argumentType = t.toString();
											
										case TDynamic( t ):
											argumentType = "Dynamic";
											
										default:
									}

									argumentDatas.push( { argumentName: arg.name, argumentType: argumentType } );

								default:
							}
						}

						if ( f.name == "new" )
						{
							constructorAnnotationData = { annotationDatas: annotationDatas, argumentDatas: argumentDatas, methodName: f.name };
						}
						else
						{
							if ( superClassAnnotationData != null )
							{
								var methodName = f.name;
								var superMethodAnnotationDatas : Array<MethodAnnotationData> = superClassAnnotationData.methods;
								for ( superMethodAnnotationData in  superMethodAnnotationDatas )
								{
									if ( superMethodAnnotationData.methodName == methodName )
									{
										methods.splice( methods.indexOf( superMethodAnnotationData ), 1 );
										break;
									}
								}
							}

							methods.push( { annotationDatas: annotationDatas, argumentDatas: argumentDatas, methodName: f.name } );
						}

					default: null;
				}
			}
		}

		var data = { name:Context.getLocalClass().get().module, superClassName: superClassName, constructorAnnotationData: constructorAnnotationData, properties:properties, methods:methods };
		AnnotationReader._static_classes.push( data );
		return classFields;
	}
	#end
}