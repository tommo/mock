module 'mock'

local insert,remove=table.insert,table.remove

--------------------------------------------------------------------
CLASS: GUIPointer ()
function GUIPointer:__init()
	self.state        = 'up'
	self.activeWidget = false
	self.hoverWidget  = false
	self.touch        = false
end

function GUIPointer:getTouch()
	return self.touch
end

--------------------------------------------------------------------
CLASS: GUIRootWidget ( GUIWidget )
function GUIRootWidget:onLoad()
	self:attachInternal( mock.InputScript() )
	self.pointers = {}
end

function GUIRootWidget:getPointer( touch, create )
	local p = self.pointers[touch]
	if (not p) and create then 
		p  =  GUIPointer()
		p.touch = touch
		self.pointers[touch] = p
	end
	return p
end

local function _findTopWidget( w, x, y, radius )
	local childId = 0
	local children = w.childWidgets
	local count = #children
	for k = count , 1, -1 do
		child = children[ k ]
		local i = child:inside( x, y, radius )
		if i == 'group' then
			local found = _findTopWidget( child, x, y )
			if found then	return found end
		elseif i then
			return _findTopWidget( child, x, y ) or child
		end
	end
	return nil
end

function GUIRootWidget:findTopWidget( x, y, radius )
	return _findTopWidget( self, x, y, radius )
end

function GUIRootWidget:onTouchEvent( ev, touch, x, y )
	if ev == 'down' then
		local p = self:getPointer( touch, true )
		p.state = 'down'
		x, y    = self:wndToWorld(x,y)
		local w = self:findTopWidget(x,y)
		if w then 
			p.activeWidget = w
			w:onPress(touch,x,y)
			if not w.__multiTouch then
				if not w.__activeTouch then w.__activeTouch=touch end
			end
		end

	elseif ev == 'up' then
		local p = self.pointers[ touch ]
		if not p then return end
		p.state = 'up'
		if p.activeWidget then
			x, y = self:wndToWorld(x,y)
			local w = p.activeWidget
			w:onRelease( touch, x, y )
			if not w.__multiTouch then	w.__activeTouch=false		end
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
			p.activeWidget:onDrag( touch, x, y )
		end

	end
end
