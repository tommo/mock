module 'mock'

local insert,remove = table.insert,table.remove

--------------------------------------------------------------------
CLASS: UIView ( UIWidgetBase )
	:MODEL{
	}
	:SIGNAL{
		focus_in = 'onFocusIn';
		focus_out = 'onFocusOut';
	}

mock.registerEntity( 'UIView', UIView )

function UIView:__init()
	self._parentView = self
	self._UIPartition = MOAIPartition.new()

	self.inputEnabled = true
	self.modalWidget  = false

	self.eventQueue = {}
	self.pendingVisualUpdates = {}
	self.pendingLayoutUpdates = {}

	self._updateNode = MOAIScriptNode.new()
	self._updateNode:setCallback( function()
		return self:doUpdate()
	end)

	self.focusManager = UIFocusManager( self )

end


function UIView:_createEntityProp()
	return Entity._createEntityProp( self )
end

function UIView:onLoad()
	self.soundSource = self:attachInternal( SoundSource() )
	self.pointers = {}
	installInputListener( self, {
			category = 'ui',
			sensors  = false --all sensors
		}
	)
end

function UIView:onStart()
	self.threadUpdate = self:addCoroutine( 'actionUpdate' )
end

function UIView:onDestroy()
	self.focusManager:deactivate()
	uninstallInputListener( self )
end

function UIView:tryPlaySound( widget, eventName )
	self.soundSource:playEvent( eventName )
end

function UIView:scheduleUpdate()
	self._updateNode:scheduleUpdate()
end

function UIView:flushUpdate()
	self._updateNode:flushUpdate()
end

function UIView:actionUpdate()
	while true do
		self:flushUpdate()
		coroutine.yield()
	end
end

function UIView:doUpdate()
	--update visual
	self:dispatchEvents()
	self:flushLayoutUpdate()
	self:flushVisualUpdate()
end

function UIView:getUpdateThread()
	return self.threadUpdate
end

function UIView:onWidgetDestroyed( widget )
	self.pendingVisualUpdates[ widget ] = nil
	self.pendingLayoutUpdates[ widget ] = nil
end

function UIView:isRootWidget()
	return true
end

--------------------------------------------------------------------
--INPUT
function UIView:getPointer( touch, create )
	local p = self.pointers[ touch ]
	if (not p) and create then 
		p  =  UIPointer( self )
		p.touch = touch
		self.pointers[touch] = p
	end
	return p
end

function UIView:getMousePointer()
	return self:getPointer( 'mouse', true )
end

function UIView:setFocus()
	self.focusManager:activate()
end

function UIView:onFocusIn()
end

function UIView:onFocusOut()
end

function UIView:getFocusedWidget()
	return self.focusManager:getFocusedWidget()
end

function UIView:setFocusedWidget( widget, reason )
	return self.focusManager:setFocusedWidget( widget, reason )
end

function UIView:setModalWidget( w )
	if self.modalWidget and self.modalWidget ~= w then
		self.modalWidget.__modal = false
	end
	self.modalWidget = w
	if w then
		w.__modal = true
	end
end

function UIView:getModalWidget()
	return self.modalWidget
end

function UIView:postEvent( target, ev )
	assert( target, ev.type )
	insert( self.eventQueue, { target, ev } )
	self:scheduleUpdate()
	return ev
end

function UIView:dispatchEvents()
	local queue = self.eventQueue
	while true do
		local entry = remove( queue, 1 )
		if not entry then break end
		local target = entry[1]
		local event  = entry[2]
		target:sendEvent( event )
	end
end

function UIView:clearEvents()
	self.eventQueue = {}
end

local function _findTopWidget( parent, x, y, padding )	
	local childId = 0
	local children = parent.childWidgets
	local count = #children
	for k = count , 1, -1 do
		local child = children[ k ]
		if child:isInteractive() then
			local px,py,pz = child:getWorldLoc()
			local pad = padding or child:getTouchPadding()
			local inside = child:inside( x, y, pz, pad )
			if inside == 'group' then
				local found = _findTopWidget( child, x, y, padding )
				if found then	return found end
			elseif inside then
				local result = _findTopWidget( child, x, y, padding ) or child
				return result
			end
		end
	end
	return nil
end

function UIView:findTopWidget( x, y, pad )
	local start = self.modalWidget or self 
	local result = _findTopWidget( start, x, y, pad )
	return result
end


---------------------------------------------------------------------
--Visual control
function UIView:getStyleSheetObject()
	if self.localStyleSheet then
		return self.localStyleSheet
	else
		return getBaseStyleSheet()
	end
end

function UIView:onLocalStyleSheetChanged()
	self.pendingVisualUpdates = {}
	self.pendingLayoutUpdates = {}
	--update
end

function UIView:flushVisualUpdate()
	local updates = self.pendingVisualUpdates
	self.pendingVisualUpdates = {}
	for w in pairs( updates ) do
		w:updateVisual()
	end
end

local function _sortUIWidgetForLayout( a, b )

end

local insert = table.insert
function UIView:flushLayoutUpdate()
	while true do
		local updates = self.pendingLayoutUpdates
		if not next( updates ) then break end
		self.pendingLayoutUpdates = {}
		local queue = table.keys( updates )
		table.sort( queue, _sortUIWidgetForLayout )
		for _, w in ipairs( queue ) do
			w:updateLayout()
		end
	end
end

function UIView:scheduleVisualUpdate( widget )
	self.pendingVisualUpdates[ widget ] = true
	self:scheduleUpdate()
end

function UIView:scheduleLayoutUpdate( widget )
	self.pendingLayoutUpdates[ widget ] = true
	self:scheduleUpdate()
end

--------------------------------------------------------------------
--INPUT handling

function UIView:onKeyEvent( key, down )
	if not self:isInteractive() then return end
	local focused = self:getFocusedWidget()
	if not focused then return end
	if down then
		local ev = UIEvent( UIEvent.KEY_DOWN, { key = key, modifiers = getModifierKeyStates() } )
		return self:postEvent( focused, ev )
	else
		local ev = UIEvent( UIEvent.KEY_UP, { key = key, modifiers = getModifierKeyStates() } )
		return self:postEvent( focused, ev )
	end
end

function UIView:onJoyAxisMove( joy, axis, value )
	if not self:isInteractive() then return end
	local focused = self:getFocusedWidget()
	if not focused then return end
	local ev = UIEvent( UIEvent.JOYSTICK_AXIS_MOVE, { axis = axis, value = value, joystick = joy } )
	return self:postEvent( focused, ev )
end

function UIView:onJoyButtonEvent( joy, btn, down )
	if not self:isInteractive() then return end
	local focused = self:getFocusedWidget()
	if not focused then return end
	if down then
		local ev = UIEvent( UIEvent.JOYSTICK_BUTTON_DOWN, { button = btn, joystick = joy } )
		return self:postEvent( focused, ev )
	else
		local ev = UIEvent( UIEvent.JOYSTICK_BUTTON_UP, { button = btn, joystick = joy } )
		return self:postEvent( focused, ev )
	end
end

function UIView:onMouseEvent( ev, x, y, btn )
	if not self:isInteractive() then return end
	local pointer = self:getMousePointer()
	if ev == 'move' then
		x, y = self:wndToWorld( x, y )
		pointer:onMove( self, x, y )

	elseif ev == 'down' then
		x, y = self:wndToWorld( x, y )
		pointer:onDown( self, x, y, btn )

	elseif ev == 'up' then
		x, y = self:wndToWorld( x, y )
		pointer:onUp( self, x, y, btn )

	elseif ev == 'scroll' then
		pointer:onScroll( self, x, y )

	end
end

function UIView:onTouchEvent( ev, touch, x, y )
	if not self:isInteractive() then return end
	x, y = self:wndToWorld( x, y )
	local pointer = self:getPointer( touch, true )
	if ev == 'down' then
		pointer:onDown( self, x, y )

	elseif ev == 'up' then
		pointer:onUp( self, x, y )
		
	elseif ev == 'move' then
		pointer:onMove( self, x, y )

	end
end
