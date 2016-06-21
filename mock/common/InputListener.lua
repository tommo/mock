module 'mock'
--[[
	each InputScript will hold a listener to responding input sensor
	filter [ mouse, keyboard, touch, joystick ]
]]

---------------------------------------------------------------------
CLASS: InputListenerCategory ()

function InputListenerCategory:__init()
	self.active = true
	self.id = false
end

function InputListenerCategory:getId()
	return self.id
end

function InputListenerCategory:isActive()
	return self.active
end

function InputListenerCategory:setActive( act )
	self.active = act ~= false
end


--------------------------------------------------------------------
local inputListenerCategories = {}

function affirmInputListenerCategory( id )
	local category = inputListenerCategories[ id ]
	if category == nil then
		category = InputListenerCategory()
		category.id = id
		inputListenerCategories[ id ] = category
	end
	return category
end

function getInputListenerCategory( id )
	return inputListenerCategories[ id ]
end

function setInputListenerCategoryActive( id, active )
	local cat = getInputListenerCategory( id )
	if cat then return cat:setActive( active ) end
end

function isInputListenerCategoryActive( id )
	local cat = getInputListenerCategory( id )
	if cat then return cat:isActive() end
	return nil
end

--------------------------------------------------------------------
function installInputListener( owner, option )
	uninstallInputListener( owner )
	option = option or {}
	local inputDevice       = option['device'] or mock.getDefaultInputDevice()
	local refuseMockUpInput = option['no_mockup'] == true
	local categoryId        = option['category'] or 'main'

	local category = affirmInputListenerCategory( categoryId )

	----link callbacks
	local mouseCallback    = false
	local keyboardCallback = false
	local touchCallback    = false
	local joystickCallback = false
	
	local sensors = option['sensors'] or false
	if not sensors or table.index( sensors, 'mouse' ) then
		----MouseEvent
		local onMouseEvent  = owner.onMouseEvent
		local onMouseDown   = owner.onMouseDown
		local onMouseUp     = owner.onMouseUp
		local onMouseMove   = owner.onMouseMove
		local onMouseEnter  = owner.onMouseEnter
		local onMouseLeave  = owner.onMouseLeave
		local onMouseScroll = owner.onMouseScroll

		if 
			onMouseDown or onMouseUp or onMouseMove or onMouseScroll or
			onMouseLeave or onMouseEnter or
			onMouseEvent
		then
			mouseCallback = function( ev, x, y, btn, mock )
				if not category.active then return end
				if mock and refuseMockUpInput then return end
				if ev == 'move' then
					if onMouseMove then onMouseMove( owner, x, y, mock ) end
				elseif ev == 'down' then
					if onMouseDown then onMouseDown( owner, btn, x, y, mock ) end
				elseif ev == 'up'   then
					if onMouseUp  then onMouseUp  ( owner, btn, x, y, mock ) end
				elseif ev == 'scroll' then
					if onMouseScroll   then onMouseScroll ( owner, x, y, mock ) end
				elseif ev == 'enter'  then
					if onMouseEnter   then onMouseEnter ( owner, mock ) end
				elseif ev == 'leave'  then
					if onMouseLeave   then onMouseLeave ( owner, mock ) end
				end
				if onMouseEvent then
					return onMouseEvent( owner, ev, x, y, btn, mock )
				end
			end
			inputDevice:addMouseListener( mouseCallback )
		end
	end

	if not sensors or table.index( sensors, 'touch' ) then
		----TouchEvent
		local onTouchEvent  = owner.onTouchEvent  
		local onTouchDown   = owner.onTouchDown
		local onTouchUp     = owner.onTouchUp
		local onTouchMove   = owner.onTouchMove
		local onTouchCancel = owner.onTouchCancel
		if onTouchDown or onTouchUp or onTouchMove or onTouchEvent then
			touchCallback = function( ev, id, x, y, mock )
				if not category.active then return end
				if mock and refuseMockUpInput then return end
				if ev == 'move' then
					if onTouchMove   then onTouchMove( owner, id, x, y, mock ) end
				elseif ev == 'down' then
					if onTouchDown   then onTouchDown( owner, id, x, y, mock ) end
				elseif ev == 'up' then
					if onTouchUp     then onTouchUp  ( owner, id, x, y, mock ) end
				elseif ev == 'cancel' then
					if onTouchCancel then onTouchCancel( owner ) end
				end
				if onTouchEvent then
					return onTouchEvent( owner, ev, id, x, y, mock )
				end
			end
			inputDevice:addTouchListener( touchCallback )
		end
	end

	----KeyEvent
	if not sensors or table.index( sensors, 'keyboard' ) then
		local onKeyEvent = owner.onKeyEvent
		local onKeyDown  = owner.onKeyDown
		local onKeyUp    = owner.onKeyUp
		if onKeyDown or onKeyUp or onKeyEvent then
			keyboardCallback = function( key, down, mock )
				if not category.active then return end
				if mock and refuseMockUpInput then return end
				if down then
					if onKeyDown then onKeyDown( owner, key, mock ) end
				else
					if onKeyUp   then onKeyUp  ( owner, key, mock ) end
				end
				if onKeyEvent then
					return onKeyEvent( owner, key, down, mock )
				end
			end
			inputDevice:addKeyboardListener( keyboardCallback )
		end
	end

	---JOYSTICK EVNET
	if not sensors or table.index( sensors, 'joystick' ) then
		local onJoyButtonDown = owner.onJoyButtonDown
		local onJoyButtonUp   = owner.onJoyButtonUp
		local onJoyButtonEvent = owner.onJoyButtonEvent
		local onJoyAxisMove   = owner.onJoyAxisMove
		if onJoyButtonDown or onJoyButtonUp or onJoyAxisMove or onJoyButtonEvent then
			joystickCallback = function( ev, joyId, btnId, axisId, value, mock )
				-- print( ev, joyid, btnId, axisId, value )
				if not category.active then return end
				if mock and refuseMockUpInput then return end
				if ev == 'down' then
					if onJoyButtonDown then onJoyButtonDown( owner, joyId, btnId, mock ) end
					if onJoyButtonEvent then onJoyButtonEvent( owner, joyId, btnId, true, mock ) end
				elseif ev == 'up' then
					if onJoyButtonUp then onJoyButtonUp( owner, joyId, btnId, mock ) end
					if onJoyButtonEvent then onJoyButtonEvent( owner, joyId, btnId, false, mock ) end
				elseif ev == 'axis' then
					if onJoyAxisMove then onJoyAxisMove( owner, joyId, axisId, value ) end
				end
			end
			joystickManager:addJoystickListener( joystickCallback )
		end
	end

	--MOTION Callbakcs
	
	owner.__inputListenerData = {
		mouseCallback    = mouseCallback,
		keyboardCallback = keyboardCallback,
		touchCallback    = touchCallback,
		joystickCallback = joystickCallback,
		inputDevice      = inputDevice,
		category         = category
	}

end

function uninstallInputListener( owner )
	local data = owner.__inputListenerData
	if not data then return end	
	local inputDevice = data.inputDevice
	print( 'removing input listener', owner:getClassName() )
	for k, d in pairs( data ) do
		print( k, d )
	end
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
		joystickManager:removeJoystickListener( data.joystickCallback )
	end

end


affirmInputListenerCategory( 'main' )
affirmInputListenerCategory( 'ui' )

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
