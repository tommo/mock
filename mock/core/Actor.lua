--[[
* MOCK framework for Moai

* Copyright (C) 2012 Tommo Zhou(tommo.zhou@gmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local pairs,ipairs,setmetatable,unpack=pairs,ipairs,setmetatable,unpack
local insert,remove=table.insert, table.remove
local yield=coroutine.yield
local select = select
local block=MOAICoroutine.blockOnAction

module 'mock'

CLASS: Actor ()


function Actor:__init()
	self.msgListeners = {}
	self.state  = 'normal'
	self.coroutines = false
end

--------SIGNAL
function Actor:connect( sig, methodName )
	return self:connectForObject( self, sig, methodName )
end

function Actor:connectForObject( obj, sig, methodName )
	local connectedSignals = self.connectedSignals
	if not connectedSignals then
		connectedSignals = {}
		self.connectedSignals = connectedSignals
	end
	if type( obj[methodName] )~='function' then
		error( 'Method not found:'..methodName, 2 )
	end
	local signal = connectSignalMethod( sig, obj, methodName )
	connectedSignals[ signal ] = obj
end

function Actor:emit( sig, ... )
	return emitSignal( sig, ... )
end

function Actor:disconnectAll()
	local connectedSignals = self.connectedSignals
	if not connectedSignals then return end
	for sig, obj in pairs(connectedSignals) do
		sig[ obj ]=nil
	end
end

---- msgbox?
function Actor:addMsgListener( listener )
	table.insert( self.msgListeners, listener )
	return listener
end

function Actor:removeMsgListener( listener )
	if not listener then return end
	local msgListeners = self.msgListeners
	for i, v in ipairs( msgListeners ) do
		if v == listener then 
			table.remove( msgListeners, i )
			return
		end
	end
end

function Actor:clearMsgListeners()
	self.msgListeners = {}
end

function Actor:tell( msg, data, source )
	for i, listener in pairs( self.msgListeners ) do
		local r = listener( msg, data, source )
		if r == 'cancel' then break	end
	end
end

---- Subscribe & Broadcast
function Actor:subscribe(target, msgTransform)
	local subs = target._subscribers
	if not subs then
		subs = {}
		target._subscribers=subs
	end
	subs[self]=msgTransform or false
	local subed=self._subscribed
	if not subed then
		subed = {}
		self._subscribed = subed
	end
	subed[target]=true
end

function Actor:unsubscribe(target)
	local subs=target._subscribers
	if subs then 
		subs[self]=nil
		if self._subscribed then
			self._subscribed[target]=nil
		end
	end
end

function Actor:unsubscribeAll()
	local subed = self._subscribed
	if subed then
		for t in pairs(subed) do
			local subs = t._subscribers
			if subs then t[self] = nil end
		end
	end
	self._subscribed = nil
end

function Actor:broadcast( msg, data, source )
	local subs = self._subscribers
	if not subs then return end
	for obj, transform in pairs( subs ) do
		if transform then
			local m1 = transform[msg]			
			local tt=type(m1)
			if tt == 'function' then
				m1( obj, msg, data, source or self )
			elseif tt == 'string' then
				obj:tell( m1, data, source or self )
			elseif tt ~= false then
				obj:tell( msg, data, source or self )
			end
		else
			obj:tell( msg, data, source or self )
		end
	end
end

---------coroutine control
local function _coroutineWrapperFunc( coroutines, coro, func, ...)
	func( ... )
	coroutines[ coro ] = nil  --automatically remove self from thread list
end

function setActorCoroutineWrapper( f )
	_coroutineWrapperFunc = f
end

function Actor:addCoroutine( func, ... )
	
	local coro = MOAICoroutine.new()
	
	local coroutines = self.coroutines
	if not coroutines then
		coroutines = {}
		self.coroutines = coroutines
	end
	local tt = type( func )
	if tt == 'string' then --method name
		local _func = self[ func ]
		assert( type(_func) == 'function' , 'method not found:'..func )
		coro:run( _coroutineWrapperFunc,
			coroutines, coro, _func, self,
			...)
	elseif tt=='function' then --function
		coro:run( _coroutineWrapperFunc,
			coroutines, coro, func,
			...)
	else
		error('unknown coroutine func type:'..tt)
	end

	coroutines[coro] = true
	return coro
end

function Actor:clearCoroutines()
	if not self.coroutines  then return end
	for coro in pairs( self.coroutines ) do
		coro:stop()
	end
end

----------state control

function Actor:setState(s)
	--TODO: add acceptable state table
	local ps   = self.state
	self.state = s
	local onStateChange = self.onStateChange
	if onStateChange then return onStateChange( self, s, ps ) end
end

function Actor:getState()
	return self.state
end


function Actor:inState(...)
	for i = 1, select( '#', ... ) do
		local s = select( i , ... )
		if s == self.state then return s end
	end
	return false
end

local stringfind=string.find
local function  _isStartWith(a,b,b1,...)
	if stringfind(a,b)==1 then return true end --a:startWith(b)
	if b1 then return _isStartWith(a,b1,...) end
	return false
end

function Actor:inStateGroup(s1,...)
	return _isStartWith(self.state,s1,...)
end

------------wait controls
function Actor:waitStateEnter(...)
	local count = select( '#', ... ) 
	if count == 1 then
		local s = select( 1, ... )
		while true do
			local ss = self.state
			if ss == s then return ss end			
			yield()
		end
	else
		while true do
			local ss = self.state
			for i = 1, count do
				if ss == select(i,...) then
					return ss
				end
			end
			yield()
		end
	end
end

function Actor:waitStateExit(s)
	while self.state == s do
		yield()
	end
	return self.state
end

function Actor:waitStateChange()
	local s = self.state
	while s == self.state do
		yield()
	end
	return self.state
end

function Actor:waitFieldEqual( name, v )
	while true do
		if self[name]==v then return true end
		yield()
	end
end

function Actor:waitFieldNotEqual( name, v )
	while true do
		if self[name]~=v then return true end
		yield()
	end
end

function Actor:waitFieldTrue( name )
	while true do
		if self[name] then return true end
		yield()
	end
end

function Actor:waitFieldFalse( name )
	while true do
		if not self[name] then return true end
		yield()
	end
end

function Actor:waitSignal(sig)
	local result=nil
	local f=function(...)
		result={...}
	end
	connectSignalFunc(sig,f)
	while not result do yield() end
	disconnectSignal(sig,f)
	return unpack(result)
end

function Actor:waitFrames(f)
	for i=1,f do
		yield()
	end
end



function Actor:waitTime(t)
	if t > 1000 then
		error('??? wrong wait time ???'..t)
	end
	local timer = MOAITimer.new()
	timer:setSpan(t)
	timer:start()
	return block(timer)
end

function Actor:timeoutSignal( sig, t )
	local result=nil
	local f=function(...)
		result={...}
	end
	connectSignalFunc(sig,f)
	local t0=self:getTime()
	while not result do 
		if self:getTime()-t0>=t then break end
		yield() 
	end
	disconnectSignal(sig,f)
	if result then 
		return true,unpack(result)
	else
		return false
	end
end

local currentThread=MOAICoroutine.currentThread
function Actor:pauseThisThread( noyield )
	local th = currentThread()
	if th then
		th:pause() 
		if not noyield then	return yield() end
	else 
		error("no thread to pause")
	end
end

function Actor:wait(a)
	if type(a)     == 'number' then
		return self:waitTime(a)
	elseif type(a) == 'table'  then
		return self:waitActionBoth(a)
	elseif type(a) == 'string' then
		return self:waitSignal(a)
	elseif a then
		return block(a)
	end
end
----------MOAIAction control

