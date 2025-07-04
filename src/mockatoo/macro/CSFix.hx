package mockatoo.macro;

import haxe.macro.Context;
import haxe.macro.Expr.Field;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Type;

using Lambda;
using haxe.macro.MacroStringTools;
using haxe.macro.Tools;
using mockatoo.macro.Tools;


/**
 * Various fixes for troubles on the C# target
 */
class CSFix
{
	#if macro
	private static var printer = new Printer();
	#end

	#if !macro
	/**
	 * Create an uninitialized instance to bypass calling constructors in C#
	 * 
	 * @param c 
	 * @param isSpy 
	 * @return T
	 */
	public static function instance<T>(c:Class<T>, params:Array<Class<Dynamic>>, isSpy:Bool):T
	{
		var t = cs.Lib.toNativeType(c);
		var i : T;

		if(false && t.IsGenericType)
		{
			var g = t.GetGenericTypeDefinition();
			var p = [];
			
			for(a in g.GetGenericArguments())
				p.push(cs.Syntax.code("typeof(object)"));

			t = g.MakeGenericType(cs.Lib.nativeArray(p, true));
		}
			
		i = cs.system.runtime.serialization.FormatterServices.GetUninitializedObject(t);
		Reflect.setField(i, "mockProxy", new mockatoo.internal.MockProxy(cast i, isSpy));

		return cast i;
	}
	#else

	public static function apply(fields:Array<Field>):Array<Field>
	{
		var cls = Context.getLocalClass();

		// Meta fix
		if(Std.string(cls) == "haxe.rtti.Meta")
			fields = fixMeta(fields);
		
		return fields;
	}

	/**
	 * On C# (at least as of Haxe 4.3) meta objects is initialized in the static constructor which is only called (mandated by Haxe) 
	 * for MyClass<Dynamic, Dynamic, ...> which makes accessing the meta from any concrete type impossible. 
	 * 
	 * So this patches the haxe.rtti.Meta.getMeta() function to also look in the MyClass<object, object,...> type in case meta is not found
	 * on whatever type it is passed and we're dealing with a generic type
	 * 
	 * @param fields 
	 * @return Array<Field>
	 */
	private static function fixMeta(fields:Array<Field>):Array<Field>
	{
		// Patch getMeta
		var field = fields.find(f -> f.name == "getMeta");

		function mapMeta(e:Expr):Expr
		{
			switch(e.expr)
			{
				case EReturn(r) : 
					return macro {
						// If meta is not found
						if($r == null)
						{
							var native = cs.Lib.toNativeType(t);
							
							// and we're dealing with a generic type
							if(native.IsGenericType)
							{
								var g = native.GetGenericTypeDefinition();
								var params : Array<Dynamic> = [];
								
								// Convert generic type to MyClass<object, object, ...>
								for(p in native.GetGenericArguments())
									params.push(cs.Syntax.code("typeof(object)"));

								var t = g.MakeGenericType(cs.Lib.nativeArray(params, true));
								
								// Access meta on the default generic class
								var meta = t.GetField("__meta__");
								
								if(meta != null)
									return meta.GetValue(null);
							}
						}

						return $r;
					}
				
				default: return ExprTools.map(e, mapMeta);
			}
			return e;
		}
		
		switch(field.kind)
		{
			case FFun(f) :
				f.expr = ExprTools.map(f.expr, mapMeta);
				// trace(printer.printExpr(f.expr));
			default: null;
		}

		return fields;
	}
	#end
}
