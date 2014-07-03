--====================================================================--
-- lua_states.lua
--
--
-- by David McCuskey
-- Documentation: http://docs.davidmccuskey.com/display/docs/lua_states.lua
--====================================================================--

--[[

Copyright (C) 2013-2014 David McCuskey. All Rights Reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in the
Software without restriction, including without limitation the rights to use, copy,
modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
and to permit persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included in all copies
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

--]]



--====================================================================--
-- DMC Lua Library : Lua States
--====================================================================--

-- Semantic Versioning Specification: http://semver.org/

local VERSION = "1.1.0"


--====================================================================--
-- Support Functions


function outStr( msg )
	return "Lua States :: " .. tostring( msg )
end

function errStr( msg )
	return "\n\nERROR: Lua States :: " .. tostring( msg ) .. "\n\n"
end


--====================================================================--
-- States Container
--====================================================================--


local States = {}


--== State API Methods ==--


function States._getState( self )
	local vars = self.__lua_states
	return vars.curr_state_name
end

function States._setState( self, state_name )
	local vars = self.__lua_states

	assert( state_name, errStr("missing state name") )
	assert( type(state_name)=='string', errStr("state name must be string'" .. tostring( state_name ) ) )

	if vars.debug_on then
		print( outStr("setState: is now '" .. tostring( state_name ) .. "'" ) )
	end
	local f = self[ state_name ]

	assert( type(f)=='function', errStr("missing method for state name: '" .. tostring( state_name ) ) )

	vars.curr_state_func = f
	vars.curr_state_name = state_name
end

function States._gotoState( self, state_name, ... )
	local vars = self.__lua_states

	assert( state_name, errStr("no state name given") )
	assert( vars.curr_state_func, errStr("no initial state method") )

	if vars.debug_on then
		print( outStr( "gotoState: '" .. vars.curr_state_name .. "' >> '".. tostring( state_name ) .. "'" ) )
	end

	self:pushStateStack( vars.curr_state_name )
	vars.curr_state_func( self, state_name, ... )
end


function States._getPreviousState( self )
	local vars = self.__lua_states

	assert( #vars.state_stack > 0, errStr("state stack is empty") )

	return vars.state_stack[1]
end

function States._gotoPreviousState( self, ... )
	local vars = self.__lua_states
	local state_name = self:popStateStack()

	assert( state_name, errStr("no state name given") )
	assert( vars.curr_state_func, errStr("no initial state method") )

	if vars.debug_on then
		print( outStr( "gotoPreviousState: going to >> " .. tostring( state_name ) ) )
	end

	vars.curr_state_func( self, state_name, ... )
end


function States._pushStateStack( self, state_name )
	local vars = self.__lua_states

	assert( state_name, errStr("no state name given") )

	table.insert( vars.state_stack, 1, state_name )
end

function States._popStateStack( self )
	local vars = self.__lua_states

	assert( #vars.state_stack > 0, errStr("state stack is empty") )

	return table.remove( vars.state_stack, 1 )
end


function States._resetStates( self )
	local vars = self.__lua_states
	if vars and vars.debug_on then
		print( outStr("resetStates: resetting object states") )
	end
	self.__lua_states = {
		state_stack = {},
		curr_state_func = nil,
		curr_state_name = "",
		debug_on = false
	}
end


function States._setDebug( self, value )
	local vars = self.__lua_states
	vars.debug_on = value
end



-- private method, for testing
function States._stateStackSize( self )
	return #self.__lua_states.state_stack
end


--== Facade API Methods ==--

function States._mixin( obj )

	obj = obj or {}

	-- add variables
	States._resetStates( obj )

	-- add methods
	obj.getState = States._getState
	obj.setState = States._setState
	obj.gotoState = States._gotoState
	obj.getPreviousState = States._getPreviousState
	obj.gotoPreviousState = States._gotoPreviousState
	obj.pushStateStack = States._pushStateStack
	obj.popStateStack = States._popStateStack
	obj.resetStates = States._resetStates
	obj.setDebug = States._setDebug

	-- private method, for testing
	obj._stateStackSize = States._stateStackSize

	return obj
end




--====================================================================--
-- States Facade
--====================================================================--

return {
	mixin = States._mixin
}


