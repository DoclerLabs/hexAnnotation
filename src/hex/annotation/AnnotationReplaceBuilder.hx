package hex.annotation;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.MetadataEntry;
import hex.log.ILogger;
import hex.log.LogManager;

using haxe.macro.Tools;
using Lambda;

#if macro
class AnnotationReplaceBuilder 
{
	
	static var staticsCache:Map<String,Expr>;
	
	static var logger:ILogger;

	public static macro function build():Array<Field>
	{
		if (logger == null)
		{
			logger = LogManager.getLoggerByClass(AnnotationReplaceBuilder);
		}
		
		var fields = Context.getBuildFields();
		fields.map(function (f)
		{
			f.meta.map(processMetadata);
		});
		
		return fields;
	}
	
	static function processMetadata(m:MetadataEntry):Void
	{
		m.params = m.params.flatMap(function(p){
			switch(p.expr)
			{
				case EArrayDecl(arr):
					return arr.map(processParam);
				case _:
					return [processParam(p)];
			}
		}).array();
	}
	
	public static function processParam(e:Expr):Expr
	{
		switch(e.expr)
		{
			case EField(_.expr => EConst(CIdent(i)), str):
				return processConst(getId(i, str), processForeignConst.bind(i, str, e.pos), e.pos);
			case EConst(CIdent(i)) if (i != "null"):
				return processConst(getLocalId(i), processLocalConst.bind(i, e.pos), e.pos);
			case EConst(c):
				return e;
			case _:
				logger.debug(e);
				logger.debug(e.expr);
				Context.error('Unsupported metadata statement: ${e.expr}', e.pos);
				return null;
		}
	}
	
	static inline function getLocalId(field:String):String
	{
		return getId(Context.getLocalClass().get().name, field);
	}
	
	static inline function getId(clss:String, field:String)
	{
		return '$clss.$field';
	}
	
	static function processConst(id:String, findFunc:Void->Expr, pos:Position):Expr
	{
		if (staticsCache == null)
		{
			staticsCache = new Map<String, Expr>();
		}
		if (!staticsCache.exists(id))
		{
			var e = findFunc();
			if(e != null)
			{
				staticsCache.set(id, e);
			}
			else
			{
				Context.error('Constant "$id" not found', pos);
			}
		}
		return staticsCache.get(id);
	}
	
	static function processLocalConst(field:String, pos:Position):Expr
	{
		var matchingFields = Context.getBuildFields().filter(function (f) return f.access.indexOf(AStatic) != -1 && f.name == field );
		if(matchingFields.length == 1)
		{
			return switch(matchingFields[0].kind)
			{
				case FieldType.FVar(ct, e): macro $v{e.getValue()};
				case _: null;
			}
		}
		return null;
	}
	
	static function processForeignConst(clss:String, field:String, pos:Position):Expr
	{
		var statics = Context.getType(clss).getClass().statics.get();
		for (stat in statics)
		{
			if (stat.isPublic && stat.name == field)
			{
				return switch(stat.expr().expr)
				{
					case TConst(TString(v)):
						macro $v{v};
					case TConst(TInt(v)):
						macro $v{v};
					case TConst(TBool(v)):
						macro $v{v};
					case _:
						logger.debug(stat);
						Context.error('Unhandled constant type: ${stat}', pos);
						null;
				}
			}
		}
		return null;
	}
	
}
#end