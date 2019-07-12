package mockatoo.internal;

import mockatoo.Mockatoo;

/**
	Dynamic class that is created for stubbing a method.
	Each dynamic method calls to a specific MockMethod.
*/
@:forward
abstract Stubber(Dynamic) from Dynamic to Dynamic
{
	public function new()
	{
		this = {};
	}
}
