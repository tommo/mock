module 'character'

--------------------------------------------------------------------
CLASS: CharacterState ()
	:MODEL{}

local function _actionStateEventListener( timer, key, timesExecuted, time, value )
	local state  = timer.state
	local action = state.action
	local span   = action.spanList[ key ]
	local target = state.target
	local time   = timer:getTime()
	for i, ev in ipairs( span ) do
		ev:start( state, time )
		target:processActionEvent( 'event', ev, time, state )
	end
end

function CharacterState:__init( target, action )
	self.active = false
	self.action = action
	self.target = target
	
	local stateData = action:getStateData()

	local timer = MOAIManualTimer.new()
	self.timer  = timer
	timer:setCurve( stateData.keyCurve )
	timer:setListener( MOAITimer.EVENT_TIMER_KEYFRAME, _actionStateEventListener )
	timer.state = self
	if action.loop then
		timer:setMode( MOAITimer.LOOP )
	else
		timer:setMode( MOAITimer.NORMAL )
	end
	local length = action.length or 0
	if length<=0 then
		length = stateData.length
	end
	length = length/1000
	timer:setSpan( length )
	self.loop   = action.loop
	self.length = length	
	self.throttle = 1
end

--------------------------------------------------------------------
function CharacterState:start()
	local action = self.action
	if not action then return end
	if self.active then return end
	self.active = true
	for i, t in ipairs( action.tracks ) do
		t:start( self )
	end	
	self.timer:start()
	self.timer:throttle( self.throttle )
	self.target:processActionEvent( 'start', nil, 0, self )
end

function CharacterState:doStep( step )
	self.timer:doStep( step )
	local t1 = self.timer:getTime()
	local action = self.action
	if not action then return end
	for i, track in ipairs( action.tracks ) do
		track:apply( self, t1 )
	end	
end

function CharacterState:stop()
	local action = self.action
	if not action then return end
	if not self.active then return end
	self.active = false
	self.target:processActionEvent( 'stop', nil, self:getTime(), self )
	for i, t in ipairs( action.tracks ) do
		t:stop( self )
	end	
	self.timer:stop()
end

function CharacterState:pause( paused )
	local action = self.action
	if not action then return end
	if not self.active then return end
	self.timer:pause( paused )
	for i, t in ipairs( action.tracks ) do
		t:pause( self, paused )
	end	
end

function CharacterState:apply( a, b )
	if b then
		local t0, t1 = a, b
		-- self.timer:setTime( t1 )
		-- self.timer:apply( t0, t1 )
		local action = self.action
		if not action then return end
		for i, track in ipairs( action.tracks ) do
			track:apply2( self, t0, t1 )
		end
	else
		local t0, t1 = a, a
		-- self.timer:setTime( t1 )
		-- self.timer:apply( t1 )
		t1 = self.timer:getTime()
		local action = self.action
		if not action then return end
		for i, track in ipairs( action.tracks ) do
			track:apply( self, t1 )
		end
	end	
	self.timer:forceUpdate()
end

function CharacterState:isDone()
	return self.timer:isDone()
end

function CharacterState:isPaused()
	return self.timer:isPaused()
end

function CharacterState:getTime()
	return self.timer:getTime()
end

function CharacterState:getTimer()
	return self.timer
end

function CharacterState:setThrottle( th )
	local action = self.action
	if not action then return end

	th = th or 1
	self.throttle = th
	self.timer:throttle( th )
	for i, t in ipairs( action.tracks ) do
		t:setThrottle( self, th )
	end	
end

--------------------------------------------------------------------
function CharacterState:setTrackActive( track )
	--todo
end

--------------------------------------------------------------------
function CharacterState:findTrack( typeName )
	local action = self.action
	return action and  action:findTrack( typeName )
end
