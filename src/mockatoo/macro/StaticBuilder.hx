package mockatoo.macro;

import haxe.macro.Expr;
import azunit.input.Args;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.Function;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Printer;
import haxe.macro.ExprTools;
import haxe.ds.StringMap;

using Lambda;
using haxe.macro.Tools;
using haxe.macro.MacroStringTools;
using mockatoo.macro.Tools;


class StaticBuilder
{
	#if macro
	public static function build():Array<Field>
	{
		var fields = Context.getBuildFields();

		#if (cs || hxcs)
		fields = CSFix.apply(fields);
		#end

		return fields;
	}
	#end
}