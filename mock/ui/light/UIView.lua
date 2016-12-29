module 'mock'

local insert,remove = table.insert,table.remove

--------------------------------------------------------------------
CLASS: UIView ( Entity )
	:MODEL{

	}
	:META{
		category = 'ui'
	}

mock.registerEntity( 'UIView', UIView )

function UIView:__init()
	self._UIPartition = MOAIPartition.new()

	self.inputEnabled = true
	self.modalWidget  = false

	self.skin        = false
	self.skinPath    = false

end

function UIView:onLoad()
	self.pointers = {}
	installInputListener( self, {
			category = 'ui',
			sensors  = false --all sensors
		}
	)
end

function UIView:onUpdate( dt )
	self:dispatchEvents()
end

function UIView:getPointer( touch, create )
	local p = self.pointers[touch]
	if (not p) and create then 
		p  =  UIPointer()
		p.touch = touch
		self.pointers[touch] = p
	end
	return p
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
	insert( self.eventQueue, { target, ev } )
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

local function _findTopWidget( parent, x, y, padding )	
	local childId = 0
	local children = parent.childWidgets
	local count = #children
	for k = count , 1, -1 do
		local child = children[ k ]
		if child:isVisible() and child:isActive() and child.inputEnabled then 
			local px,py,pz = child:getWorldLoc()
			local pad = padding or child:getPadding()
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


--------------------------------------------------------------------
--INPUT handling

function UIView:onTouchEvent( ev, touch, x, y )
	if ev == 'down' then
		if not self.inputEnabled then return end
		local p = self:getPointer( touch, true )
		p.state = 'down'
		x, y    = self:wndToWorld( x, y )
		local widget = self:findTopWidget( x, y )
		if widget then 
			p.activeWidget = widget
			widget:_onPress( touch, x,y )
			if not widget._allowMultiTouch then
				if not widget._activeTouch then widget._activeTouch = touch end
			end
		end

	elseif ev == 'up' then
		local p = self.pointers[ touch ]
		if not p then return end
		p.state = 'up'
		if p.activeWidget then
			x, y = self:wndToWorld(x,y)
			local widget = p.activeWidget
			widget:_onRelease( touch, x, y )
			if not widget._allowMultiTouch then	
				widget._activeTouch = false
			end
		end

		p.activeWidget = false
		p.touch = false
		self.pointers[ touch ] = nil
		
	elseif ev == 'move' then
		local p = self.pointers[touch]
		if not p then return end
		-- p.state='drag'
		if p.activeWidget then
			x, y = self:wndToWorld( x, y )
			p.activeWidget:_onDrag( touch, x, y )
		end

	end
end
