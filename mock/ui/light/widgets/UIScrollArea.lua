module 'mock'

CLASS: UIScrollArea ( UIWidget )
	:MODEL{
		Field 'scrollSize' :type('vec2') :getset('ScrollSize');	
		'----';
		Field 'scrollDamping';
		Field 'maxScrollSpeed';
		Field 'allowScrollX' :boolean();
		Field 'allowScrollY' :boolean();
		'----';
		Field 'scroll'     :type('vec2') :getset('Scroll');
	}

registerEntity( 'UIScrollArea', UIScrollArea )

function UIScrollArea:__init()
	self.innerTransform = MOAITransform.new()
	inheritTransform( self.innerTransform, self._prop )
	self.scrollDamping  = 0.9

	self.scrollW = -1
	self.scrollH = -1
	self.targetScrollX = 0
	self.targetScrollY = 0
	self.speedScrollX = 0
	self.speedScrollY = 0
	self.reactionSpeedX = 0
	self.reactionSpeedY = 0
	self.maxScrollSpeed = 50
	self.grabbed   = false	

	self.allowScrollX = true
	self.allowScrollY = true
end

function UIScrollArea:getDefaultSize()
	return 50, 50
end

function UIScrollArea:_attachChildEntity( child )
	UIScrollArea.__super._attachChildEntity( self, child )
	local inner  = self.innerTransform
	local p      = self._prop
	local pchild = child._prop
	inheritTransform( pchild, inner )
	inheritColor( pchild, p )
	inheritVisible( pchild, p )
end

function UIScrollArea:setSize( w, h, updateLayout, updateStyle )
	UIScrollArea.__super.setSize( self, w, h, updateLayout, updateStyle )
	self.innerTransform:setPiv( 0, -h )
end

--------------------------------------------------------------------
function UIScrollArea:worldToScroll( x, y )
	return self.innerTransform:worldToModel( x, y )
end

function UIScrollArea:modelToScroll( x, y )
	x,y = self:modelToWorld( x, y )
	return self.innerTransform:worldToModel( x, y )
end

function UIScrollArea:scrollToWorld( x, y )
	return self.innerTransform:modelToWorld( x, y )
end

function UIScrollArea:scrollToModel( x, y )
	return self:worldToModel( self:scrollToWorld( x, y ) )
end


--------------------------------------------------------------------
function UIScrollArea:setScroll( x, y, updateTargetScroll )
	self.innerTransform:setLoc( x, y )
	if updateTargetScroll ~= false then
		self.targetScrollX = x
		self.targetScrollY = y
		self.speedScrollX = 0
		self.speedScrollY = 0
	end
end

function UIScrollArea:getScroll()
	local x, y = self.innerTransform:getLoc()
	return x, y 
end

function UIScrollArea:getScrollSpeed()
	return self.speedScrollX, self.speedScrollY
end


function UIScrollArea:moveScroll( dx, dy, t, easeType )
	return self.innerTransform:moveLoc( dx, dy, 0, t, easeType )
end

function UIScrollArea:seekScroll( x, y, t, easeType )
	return self.innerTransform:seekLoc( x, y, 0, t, easeType )
end

function UIScrollArea:addScroll( dx, dy )	
	return self.innerTransform:addLoc( dx, dy, 0 )
end

function UIScrollArea:getScrollX()
	return getLocX( self.innerTransform )
end

function UIScrollArea:setScrollX( x )
	return setLocX( self.innerTransform, x )
end

function UIScrollArea:seekScrollX( x, t, easeType )
	return seekLocX( self.innerTransform, x, t, easeType )
end

function UIScrollArea:addScrollX( dx )	
	return setLocX( self.innerTransform, dx + self:getScrollX() )
end

function UIScrollArea:moveScrollX( dx, t, easeType )
	return moveLocX( self.innerTransform, dx, t, easeType )
end

function UIScrollArea:getScrollY()
	return getLocY( self.innerTransform )
end

function UIScrollArea:setScrollY( y )
	setLocY( self.innerTransform, y )
end

function UIScrollArea:addScrollY( dy )
	return setLocY( self.innerTransform, dy + self:getScrollY() )
end

function UIScrollArea:seekScrollY( y, t, easeType )
	return seekLocY( self.innerTransform, y, t, easeType )
end

function UIScrollArea:moveScrollY( dy, t, easeType )
	return moveLocY( self.innerTransform, dy, t, easeType )
end

function UIScrollArea:getScrollSize()
	return self.scrollW, self.scrollH	
end

function UIScrollArea:setScrollSize( w, h )
	self.scrollW, self.scrollH = w, h
end

function UIScrollArea:isScrolling()
	local vx, vy = self.speedScrollX, self.speedScrollY
	return vx*vx >= 1 or vy*vy >= 1
end

--------------------------------------------------------------------
function UIScrollArea:setTargetScrollX( x )
	self.targetScrollX = x
end

function UIScrollArea:setTargetScrollY( y )
	self.targetScrollY = y
end

function UIScrollArea:addTargetScrollX( dx )
	self:setTargetScrollX( self.targetScrollX + dx )	
end

function UIScrollArea:addTargetScrollY( dy )
	self:setTargetScrollY( self.targetScrollY + dy )	
end

function UIScrollArea:addTargetScroll( dx, dy )
	self:setTargetScrollX( self.targetScrollX + dx )	
	self:setTargetScrollY( self.targetScrollY + dy )	
end
--------------------------------------------------------------------
function UIScrollArea:grabScroll( grabbed )
	grabbed = grabbed ~= false
	if self.grabbed == grabbed then return end
	self.grabbed = grabbed
	if grabbed then 
		self.speedScrollX = 0
		self.speedScrollY = 0
		self.targetScrollX, self.targetScrollY = self:getScroll()	
		self:onGrabStart()
	else
		self:onGrabStop()
	end
end

function UIScrollArea:isScrollGrabbed()
	return self.grabbed
end

--------------------------------------------------------------------
function UIScrollArea:onUpdate( dt )
	local tx = self.targetScrollX
	local ty = self.targetScrollY
	local x, y = self:getScroll()
	x = lerp( x, tx, 0.5 )
	y = lerp( y, ty, 0.5 )
	self:setScroll( x, y, false )
	-- if self.allowScrollX then	self:updateTargetScrollX( dt ) end
	-- if self.allowScrollY then	self:updateTargetScrollY( dt ) end
end

function UIScrollArea:updateTargetScrollX( dt ) 
	local overDrag = 50
	if not self.grabbed 
		and math.abs( self.speedScrollX ) < 0.01
		and math.abs( self.reactionSpeedX ) < 0.01 then
		self.speedScrollX = 0
		self.reactionSpeedX = 0
		return
	end
	local x0,x1 = 0, self.scrollW
	if x0>x1 then
		x0,x1 = x1,x0
	end

	local damping = self.scrollDamping
	local ms = self.maxScrollSpeed
	local x  = self:getScrollX()
	
	if self.grabbed then
		local vx0 = self.speedScrollX
		local dx  = self.targetScrollX - x
		local vx1 = math.clamp( dx, -ms, ms )
		local k = 0.7
		self.speedScrollX = vx0*(1-k) + vx1*k
	else
		self.speedScrollX = self.speedScrollX * damping
	end

	if x < x0 then
		local k = ( x0 - x ) / overDrag
		self.reactionSpeedX = lerp( self.reactionSpeedX, ( k * ms ), 0.5 )
	elseif x >= x1 then
		local k = ( x - x1 ) / overDrag
		self.reactionSpeedX  = lerp( self.reactionSpeedX, - k * ms, 0.5 )
	else
		self.reactionSpeedX = 0
	end

	local nx = x + self.speedScrollX + self.reactionSpeedX
	self:setScrollX( nx )
end

function UIScrollArea:updateTargetScrollY( dt )
	local overDrag = 50
	if not self.grabbed 
		and math.abs( self.speedScrollY ) < 0.01
		and math.abs( self.reactionSpeedY ) < 0.01 then
		self.speedScrollY = 0
		self.reactionSpeedY = 0
		return
	end
	local y0,y1 = 0, -self.scrollH
	if y0>y1 then
		y0,y1 = y1,y0
	end

	local damping = self.scrollDamping
	local ms = self.maxScrollSpeed
	local y  = self:getScrollY()
	
	if self.grabbed then
		local vy0 = self.speedScrollY
		local dy  = self.targetScrollY - y
		local vy1 = math.clamp( dy, -ms, ms )
		local k = 0.7
		self.speedScrollY = vy0*(1-k) + vy1*k
	else
		self.speedScrollY = self.speedScrollY * damping
	end

	if y < y0 then
		local k = ( y0 - y ) / overDrag
		self.reactionSpeedY = lerp( self.reactionSpeedY, ( k * ms ), 0.5 )
	elseif y >= y1 then
		local k = ( y - y1 ) / overDrag
		self.reactionSpeedY  = lerp( self.reactionSpeedY, - k * ms, 0.5 )
	else
		self.reactionSpeedY = 0
	end

	local ny = y + self.speedScrollY + self.reactionSpeedY
	self:setScrollY( ny )
end

function UIScrollArea:procEvent( ev )
	local t = ev.type
	local d = ev.data
	if t == UIEvent.POINTER_SCROLL then
		local dx = d.x * 10
		local dy = d.y * 10
		self:addTargetScroll( dx, -dy )
	end
end
	

-- --------------------------------------------------------------------
-- function UIScrollArea:_onPress( pointer, x,y )
-- 	self:grabScroll( true )
-- 	self.dragX0 = x
-- 	self.dragY0 = y
-- end

-- function UIScrollArea:_onDrag( pointer, x,y )
-- 	self:grabScroll( true )
-- 	local dx, dy = x-self.dragX0, y-self.dragY0
-- 	self:addTargetScrollX( dx )
-- 	self:addTargetScrollY( dy )
-- 	self.dragX0 = x
-- 	self.dragY0 = y
-- end

-- function UIScrollArea:_onRelease( pointer, x,y )
-- 	self:grabScroll( false )
-- end

-- function UIScrollArea:onGrabStop()
-- end

-- function UIScrollArea:onGrabStart()
-- end
