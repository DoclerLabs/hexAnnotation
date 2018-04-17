package hex.di;

/**
 * @author Francis Bourre
 */
#if !macro
@:autoBuild( hex.di.annotation.AnnotationTransformer.readMetadata( hex.di.IInjectorContainer ) )
#end
interface IInjectorContainer extends IInjectorAcceptor
{
	
}