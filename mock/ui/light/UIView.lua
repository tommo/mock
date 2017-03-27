module 'mock'

local insert,remove = table.insert,table.remove

--------------------------------------------------------------------
CLASS: UIView ( UIWidgetBase )
	:MODEL{
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

function UIView:onLoad()
	self.pointers = {}
	installInputListener( self, {
			category = 'ui',
			sensors  = false --all sensors
		}
	)
end

function UIView:scheduleUpdate()
	self._updateNode:scheduleUpdate()
end

function UIView:flushUpdate()
	self._updateNode:flushUpdate()
end

function UIView:onUpdate()
	self._updateNode:flushUpdate()
end

function UIView:doUpdate()
	--update visual
	self:dispatchEvents()
	self:flushLayoutUpdate()
	self:flushVisualUpdate()
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

function UIView:getFocusedWidget()
	return self.focusedWidget
end

function UIView:setFocusedWidget( widget, reason )
	local previous = self.focusedWidget
	if previous == widget then return true end
	if previous then
		self:postEvent( previous, UIEvent( UIEvent.FOCUS_OUT ) )
	end
	if widget then
		self:postEvent( widget, UIEvent( UIEvent.FOCUS_IN, { reason = reason } ) )
	end
	self.focusedWidget = widget or false
	return true
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
		if child:isVisible() and child:isActive() and child.inputEnabled then 
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
	return _findTopWidget( start, x, y, pad )
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
	if not self.inputEnabled then return end

end

function UIView:onMouseEvent( ev, x, y, btn )
	x, y = self:wndToWorld( x, y )
	local pointer = self:getMousePointer()
	if ev == 'move' then
		pointer:onMove( self, x, y )
	end
end

function UIView:onTouchEvent( ev, touch, x, y )
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
