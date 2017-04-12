module 'mock'

CLASS: JoystickState ()
	:MODEL{}

function JoystickState:__init( mgr, instance )
	self._mgr = mgr
	self._instance = instance
	self.mapping = false
	self.axisValues = {}
	self.buttonState = {}
	local device = self:getInputDevice()
	self.FFB = device.FFB
	device.buttons:setCallback(
		function( btn, down )
			return self:onButtonEvent( btn, down )
		end
	)
	for axisId = 0, instance:getAxeCount()-1 do
		self.axisValues[ axisId ] = 0
		local axisSensor = device[ 'a'..axisId ]
		axisSensor:setCallback(
			function( value )
				return self:onAxisMove( axisId, value )
			end
		)
	end
end

function JoystickState:setMapping( mapping )
	self.mapping = mapping
end

function JoystickState:onButtonEvent( btn, down )
	if self.mapping then
		local ev, cmd, value = self.mapping:mapButtonEvent( btn, down )
		if ev == 'button' then
			self.buttonState[ cmd ] = value
			self._mgr:dispatchButtonEvent( self, cmd, value )
		end
	end
	self._mgr:dispatchRawButtonEvent( self, btn, down )
end

function JoystickState:updateAxisArrowButton( axisId, v, pv )
	-- gate = gate or 0.5
	local gate = 0.7
	local i1 = ( v >gate and 1 ) or ( v < -gate and -1 ) or 0
	local i0 = ( pv >gate and 1 ) or ( pv < -gate and -1 ) or 0
	local btnHigh, btnLow

	if i0 == i1 then return false end
	--simulate axis->arrow
	if axisId == 'LX' then
		btnLow = 'L-left'
		btnHigh = 'L-right'
	elseif axisId == 'LY' then
		btnLow = 'L-up'
		btnHigh = 'L-down'
	elseif axisId == 'RX' then
		btnLow = 'R-left'
		btnHigh = 'R-right'
	elseif axisId == 'RY' then
		btnLow = 'R-up'
		btnHigh = 'R-down'
	end
	local downHigh, downLow = i1 == 1, i1 == - 1
	local bs = self.buttonState
	local downLow0 = bs[ btnLow ] or false
	local downHigh0 = bs[ btnHigh ] or false
	if downLow0 ~= downLow then
		self.buttonState[ btnLow ] = downLow
		self._mgr:dispatchButtonEvent( self, btnLow, downLow )
	end
	if downHigh0 ~= downHigh then
		self.buttonState[ btnHigh ] = downHigh
		self._mgr:dispatchButtonEvent( self, btnHigh, downHigh )
	end
end

function JoystickState:onAxisMove( axisId, value )
	local prevValue = self.axisValues[ axisId ]
	self.axisValues[ axisId ] = value
	if self.mapping then
		local ev, cmd, value = self.mapping:mapAxisEvent( axisId, value, prevValue )
		if ev == 'button' then
			self.buttonState[ cmd ] = value
			self._mgr:dispatchButtonEvent( self, cmd, value )
		elseif ev == 'axis' then
			self._mgr:dispatchAxisEvent( self, cmd, value )			
			if cmd == 'LX' or cmd == 'LY' or cmd == 'RX' or cmd == 'RY' then
				self:updateAxisArrowButton( cmd, value, prevValue or 0 )
			end
		end
	end
	self._mgr:dispatchRawAxisEvent( self, axisId, value )
end

function JoystickState:onHatEvent( hat, value )
	--TODO
end

function JoystickState:getFFBSensor()
	return self.FFB
end

function JoystickState:getInputDevice()
	return self._instance:getInputDevice()
end

--------------------------------------------------------------------
CLASS: JoystickManager ( GlobalManager )
	:MODEL{}

function JoystickManager:getKey()
	return 'JoystickManager'
end

function JoystickManager:__init()
	self.joystickStates = {}
	self.joystickListeners = {}
	self.mode = 'SDL'
end

function JoystickManager:onInit()
	if _G.MOAIJoystickManagerSDL then
		self:initSDL()
	else --TODO: other platform support
	end
end

function JoystickManager:onJoystickAdd( instance )
	local joystickState = JoystickState( self, instance )
	table.insert( self.joystickStates, joystickState )
	if self.mode == 'SDL' then
		local mapping = mock.getSDLJoystickMapping( instance:getGUID() )
		if mapping then
			joystickState:setMapping( mapping )
		else
			_warn( 'no joystick mapping found:', instance:getGUID() )
		end
	end
end

function JoystickManager:onJoystickRemove( instance )
	for i, state in ipairs( self.joystickStates ) do
		if state._instance == instance then
			table.remove( self.joystickStates, i )
			break
		end
	end
end

function JoystickManager:addJoystickListener( func )
	self.joystickListeners[ func ] = true
end

function JoystickManager:removeJoystickListener( func )
	self.joystickListeners[ func ] = nil
end

function JoystickManager:dispatchButtonEvent( joystickState, button, down, mock )
	for listener in pairs( self.joystickListeners ) do
		if down then
			listener( 'down', joystickState, button, nil, nil, mock )
		else
			listener( 'up', joystickState, button, nil, nil, mock )
		end
	end
end

function JoystickManager:dispatchAxisEvent( joystickState, axisId, value, mock )
	for listener in pairs( self.joystickListeners ) do
		listener( 'axis', joystickState, nil, axisId, value, mock )
	end
end

function JoystickManager:dispatchRawButtonEvent( joystickState, button, down, mock )
	for listener in pairs( self.joystickListeners ) do
		if down then
			listener( 'down-raw', joystickState, button, nil, nil, mock )
		else
			listener( 'up-raw', joystickState, button, nil, nil, mock )
		end
	end
end

function JoystickManager:dispatchRawAxisEvent( joystickState, axisId, value, mock )
	for listener in pairs( self.joystickListeners ) do
		listener( 'axis-raw', joystickState, nil, axisId, value, mock )
	end
end

function JoystickManager:initSDL()
	self.mode = 'SDL'
	MOAIJoystickManagerSDL.setJoystickDeviceCallback(
		function( ev, instance )
			if ev == 'add' then
				self:onJoystickAdd( instance )
			elseif ev == 'remove' then
				self:onJoystickRemove( instance )
			end
		end
	)
end

--------------------------------------------------------------------
joystickManager = JoystickManager()
