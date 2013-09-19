module 'mock'
--[[
	each InputScript will hold a listener to responding input sensor
	filter [ mouse, keyboard, touch, joystick ]
]]

function enableInputListener( self, option )
	option = option or {}
	local inputDevice       = option['device'] or mock.getDefaultInputDevice()
	local refuseMockUpInput = option['no_mockup'] == true
	----link callbacks
	local mouseCallback    = false
	local keyboardCallback = false
	local touchCallback    = false
	local joystickCallback = false
	
	----MouseEvent
	local onMouseEvent = self.onMouseEvent
	local onMouseDown  = self.onMouseDown
	local onMouseUp    = self.onMouseUp
	local onMouseMove  = self.onMouseMove
	local onMouseEnter = self.onMouseEnter
	local onMouseLeave = self.onMouseLeave
	local onScroll     = self.onScroll

	if 
		onMouseDown or onMouseUp or onMouseMove or onScroll or
		onMouseLeave or onMouseEnter or
		onMouseEvent
	then
		mouseCallback = function( ev, x, y, btn, mock )
			if mock and refuseMockUpInput then return end
			if ev == 'move' then
				if onMouseMove then onMouseMove( self, x, y, mock ) end
			elseif ev == 'down' then
				if onMouseDown then onMouseDown( self, btn, x, y, mock ) end
			elseif ev == 'up'   then
				if onMouseUp  then onMouseUp  ( self, btn, x, y, mock ) end
			elseif ev == 'scroll' then
				if onScroll   then onScroll ( self, x, y, mock ) end
			elseif ev == 'enter'  then
				if onMouseEnter   then onMouseEnter ( self, mock ) end
			elseif ev == 'leave'  then
				if onMouseLeave   then onMouseLeave ( self, mock ) end
			end
			if onMouseEvent then
				return onMouseEvent( self, ev, x, y, btn, mock )
			end
		end
		inputDevice:addMouseListener( mouseCallback )
	end

	----TouchEvent
	local onTouchEvent  = self.onTouchEvent  
	local onTouchDown   = self.onTouchDown
	local onTouchUp     = self.onTouchUp
	local onTouchMove   = self.onTouchMove
	local onTouchCancel = self.onTouchCancel
	if onTouchDown or onTouchUp or onTouchMove or onTouchEvent then
		touchCallback = function( ev, id, x, y, mock )
			if mock and refuseMockUpInput then return end
			if ev == 'move' then
				if onTouchMove   then onTouchMove( self, id, x, y, mock ) end
			elseif ev == 'down' then
				if onTouchDown   then onTouchDown( self, id, x, y, mock ) end
			elseif ev == 'up' then
				if onTouchUp     then onTouchUp  ( self, id, x, y, mock ) end
			elseif ev == 'cancel' then
				if onTouchCancel then onTouchCancel( self ) end
			end
			if onTouchEvent then
				return onTouchEvent( self, ev, id, x, y, mock )
			end
		end
		inputDevice:addTouchListener( touchCallback )
	end

	----KeyEvent
	local onKeyEvent = self.onKeyEvent
	local onKeyDown  = self.onKeyDown
	local onKeyUp    = self.onKeyUp
	if onKeyDown or onKeyUp or onKeyEvent then
		keyboardCallback = function( key, down, mock )
			if mock and refuseMockUpInput then return end
			if down then
				if onKeyDown then onKeyDown( self, key, mock ) end
			else
				if onKeyUp   then onKeyUp  ( self, key, mock ) end
			end
			if onKeyEvent then
				return onKeyEvent( self, key, down, mock )
			end
		end
		inputDevice:addKeyboardListener( keyboardCallback )
	end
	
	self.__inputListenerData = {
		mouseCallback    = mouseCallback,
		keyboardCallback = keyboardCallback,
		touchCallback    = touchCallback,
		joystickCallback = joystickCallback,
		inputDevice      = inputDevice
	}

	---JOYSTICK EVNET
	--TODO:...	
end

function removeInputListener( self )
	local data = self.__inputListenerData
	if not data then return end	
	local inputDevice = data.inputDevice
	if data.mouseCallback then
		inputDevice:removeMouseListener( data.mouseCallback )
	end

	if data.keyboardCallback then
		inputDevice:removeKeyboardListener( data.keyboardCallback )
	end

	if data.touchCallback then
		inputDevice:removeTouchListener( data.touchCallback )
	end

	if data.joystickCallback then
		inputDevice:removeJoystickListener( data.joystickCallback )
	end

end


--[[
	input event format:
		KeyDown     ( keyname )
		KeyUp       ( keyname )

		MouseMove   ( x, y )
		MouseDown   ( btn, x, y )
		MouseUp     ( btn, x, y )

		RawMouseMove   ( id, x, y )        ---many mouse (??)
		RawMouseDown   ( id, btn, x, y )   ---many mouse (??)
		RawMouseUp     ( id, btn, x, y )   ---many mouse (??)
		
		TouchDown   ( id, x, y )
		TouchUp     ( id, x, y )
		TouchMove   ( id, x, y )
		TouchCancel (          )
		
		JoystickMove( id, x, y )
		JoystickDown( btn )
		JoystickUp  ( btn )

		LEVEL:   get from service
		COMPASS: get from service
]]
