module 'mock'

CLASS: GUIScrollArea ( GUIWidget )
	:MODEL{
		Field 'size'       :type('vec2') :getset('Size');
		Field 'scroll'     :type('vec2') :getset('Scroll');	
		Field 'scrollSize' :type('vec2') :getset('ScrollSize');	
	}

registerGUIWidget( 'ScrollArea', GUIScrollArea )

function GUIScrollArea:__init()
	self.innerTransform = MOAITransform.new()
	inheritTransform( self.innerTransform, self._prop )
	self.scrollW = -1
	self.scrollH = -1
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

function GUIScrollArea:setScroll( x, y )
	self.innerTransform:setLoc( x, y )
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

