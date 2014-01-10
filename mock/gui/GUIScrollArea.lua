module 'mock'

CLASS: GUIScrollArea ( GUIWidget )
	:MODEL{
		Field 'size'       :type('vec2') :getset('Size');
		Field 'scrollSize' :type('vec2') :getset('ScrollSize');	
		'----';
		Field 'scrollDamping';
		Field 'maxScrollSpeed';
		'----';
		Field 'scroll'     :type('vec2') :getset('Scroll');
	}

registerGUIWidget( 'ScrollArea', GUIScrollArea )

function GUIScrollArea:__init()
	self.innerTransform = MOAITransform.new()
	inheritTransform( self.innerTransform, self._prop )
	self.scrollW = -1
	self.scrollH = -1
	self.momentum      = true
	self.targetScrollX = 0
	self.targetScrollY = 0
	self.speedScrollX = 0
	self.speedScrollY = 0
	self.scrollDamping = 0.9
	self.maxScrollSpeed   = 50
	self.grabbed   = false	
end

function GUIScrollArea:getDefaultSize()
	return 100,100
end

function GUIScrollArea:_attachChildEntity( child )
	local inner  = self.innerTransform
	local p      = self._prop
	local pchild = child._prop
	inheritTransform( pchild, inner )
	inheritColor( pchild, p )
	inheritVisible( pchild, p )
end

--------------------------------------------------------------------
function GUIScrollArea:worldToScroll( x, y )
	return self.innerTransform:worldToModel( x, y )
end

function GUIScrollArea:modelToScroll( x, y )
	x,y = self:modelToWorld( x, y )
	return self.innerTransform:worldToModel( x, y )
end

function GUIScrollArea:scrollToWorld( x, y )
	return self.innerTransform:modelToWorld( x, y )
end

function GUIScrollArea:scrollToModel( x, y )
	return self:worldToModel( self:scrollToWorld( x, y ) )
end


--------------------------------------------------------------------
function GUIScrollArea:setScroll( x, y, updateTargetScroll )
	self.innerTransform:setLoc( x, y )
	if updateTargetScroll ~= false then
		self.targetScrollX = x
		self.targetScrollY = y
		self.speedScrollX = 0
		self.speedScrollY = 0
	end
end

function GUIScrollArea:getScroll()
	local x, y = self.innerTransform:getLoc()
	return x, y 
end

function GUIScrollArea:moveScroll( dx, dy, t, easeType )
	return self.innerTransform:moveLoc( dx, dy, 0, t, easeType )
end

function GUIScrollArea:seekScroll( x, y, t, easeType )
	return self.innerTransform:seekLoc( x, y, 0, t, easeType )
end


function GUIScrollArea:getScrollX()
	return getLocX( self.innerTransform )
end

function GUIScrollArea:setScrollX( x )
	return setLocX( self.innerTransform, x )
end

function GUIScrollArea:seekScrollX( x, t, easeType )
	return seekLocX( self.innerTransform, x, t, easeType )
end

function GUIScrollArea:addScrollX( dx )	
	return setLocX( self.innerTransform, dx + self:getScrollX() )
end

function GUIScrollArea:moveScrollX( dx, t, easeType )
	return moveLocX( self.innerTransform, dx, t, easeType )
end

function GUIScrollArea:getScrollY()
	return getLocY( self.innerTransform )
end

function GUIScrollArea:setScrollY( y )
	return setLocY( self.innerTransform, y )
end

function GUIScrollArea:addScrollY( dy )
	return setLocY( self.innerTransform, dy + self:getScrollY() )
end

function GUIScrollArea:seekScrollY( y, t, easeType )
	return seekLocY( self.innerTransform, y, t, easeType )
end

function GUIScrollArea:moveScrollY( dy, t, easeType )
	return moveLocY( self.innerTransform, dy, t, easeType )
end

--------------------------------------------------------------------
function GUIScrollArea:setSize( w, h )
	if not w then
		w, h = self:getDefaultSize()
	end
	self.width, self.height = w, h
	self:setScissorRect( 0, 0, w, h )
end

function GUIScrollArea:getScrollSize()
	return self.scrollW, self.scrollH	
end

function GUIScrollArea:setScrollSize( w, h )
	self.scrollW, self.scrollH = w, h
end

function GUIScrollArea:isScrolling()
	local vx, vy = self.speedScrollX, self.speedScrollY
	return vx*vx >= 1 or vy*vy >= 1
end

--------------------------------------------------------------------
function GUIScrollArea:setTargetScrollX( x )
	local x0,x1 = 0, self.scrollW
	if x0>x1 then x0,x1 = x1,x0 end
	self.targetScrollX = math.clamp( x, x0,x1 )
end

function GUIScrollArea:setTargetScrollY( y )
	local y0,y1 = 0, -self.scrollH
	if y0>y1 then y0,y1 = y1,y0 end
	self.targetScrollY = math.clamp( y, y0,y1 )
end

function GUIScrollArea:addTargetScrollX( dx )
	self:setTargetScrollX( self.targetScrollX + dx )	
end

function GUIScrollArea:addTargetScrollY( dy )
	self:setTargetScrollY( self.targetScrollY + dy )	
end

--------------------------------------------------------------------
function GUIScrollArea:grabScroll( grabbed )
	grabbed = grabbed ~= false
	if self.grabbed == grabbed then return end
	self.grabbed = grabbed
	if grabbed then 
		self.speedScrollX = 0
		self.speedScrollY = 0
		self.targetScrollX, self.targetScrollY = self:getScroll()	
	end
end

function GUIScrollArea:isScrollGrabbed()
	return self.grabbed
end

--------------------------------------------------------------------
function GUIScrollArea:onUpdate( dt )	
	self:updateTargetScrollX( dt )
	self:updateTargetScrollY( dt )
end

function GUIScrollArea:updateTargetScrollX( dt ) 
	local damping = self.scrollDamping
	local ms = self.maxScrollSpeed
	
	local x  = self:getScrollX()
	if self.grabbed then
		local vx0 = self.speedScrollX
		local vx1 = math.clamp( self.targetScrollX - x, -ms, ms )
		local k = 0.7
		self.speedScrollX =  vx0*(1-k) + vx1*k
	end
	local nx = x + self.speedScrollX
	local x0,x1 = 0, -self.scrollH
	if x0>x1 then
		x0,x1 = x1,x0
	end
	if nx <= x0 then
		nx = x0
		self.speedScrollX = 0
	elseif nx >= x1 then
		nx = x1
		self.speedScrollX = 0
	else
		self.speedScrollX = self.speedScrollX * damping
	end
	self:setScrollX( nx )
end

function GUIScrollArea:updateTargetScrollY( dt )
	local damping = self.scrollDamping
	local ms = self.maxScrollSpeed

	local y  = self:getScrollY()
	if self.grabbed then
		local vy0 = self.speedScrollY
		local dy = self.targetScrollY - y
		local vy1 = math.clamp( dy, -ms, ms )
		local k = 0.7
		self.speedScrollY =  vy0*(1-k) + vy1*k
	end
	local ny = y + self.speedScrollY
	local y0,y1 = 0, -self.scrollH
	if y0>y1 then
		y0,y1 = y1,y0
	end
	if ny <= y0 then
		ny = y0
		self.speedScrollY = 0
	elseif ny >= y1 then
		ny = y1
		self.speedScrollY = 0
	else
		self.speedScrollY = self.speedScrollY * damping
	end
	self:setScrollY( ny )
end

--------------------------------------------------------------------
function GUIScrollArea:onPress( pointer, x,y )
	self:grabScroll( true )
	self.dragX0 = x
	self.dragY0 = y
end

function GUIScrollArea:onDrag( pointer, x,y )
	self:grabScroll( true )
	local dx, dy = x-self.dragX0, y-self.dragY0
	self:addTargetScrollX( dx )
	self:addTargetScrollY( dy )
	self.dragX0 = x
	self.dragY0 = y
end

function GUIScrollArea:onRelease( pointer, x,y )
	self:grabScroll( false )
end

--------------------------------------------------------------------
function GUIScrollArea:drawBounds()
	GIIHelper.setVertexTransform( self:getProp() )
	MOAIDraw.drawRect( 0,0, self:getSize() )
end

