module 'mock'

--------------------------------------------------------------------
CLASS: UIWidgetElement ()
	:MODEL{}

function UIWidgetElement:__init()
	self.owner = false
	self.rect = { 0,0,1,1 }
	self.offset = { 0, 0 }
	self.zOrder = 0
	self.styleNameCache = {}
end

function UIWidgetElement:setVisible( vis )
end

function UIWidgetElement:setStyleBaseName( n )
	self.styleBaseName = n
	self.styleNameCache = {}
end

function UIWidgetElement:makeStyleName( key )
	local base = self.styleBaseName
	if not key then return base end
	return base ..'_' .. key
	-- local cache = self.styleNameCache
	-- local v = cache[ key ]
	-- if not v then
	-- 	v = base ..'_' .. key
	-- 	cache[ key ] = v
	-- end
	-- return v
end

function UIWidgetElement:getRenderer()
	return self.owner
end

function UIWidgetElement:getWidget()
	return self.owner:getWidget()
end

function UIWidgetElement:getRect()
	return unpack( self.rect )
end

function UIWidgetElement:setRect( x, y, x1, y1 )
	self.rect = { x, y, x1, y1 }
end

function UIWidgetElement:getOffset()
	return unpack( self.offset )
end

function UIWidgetElement:setOffset( x, y )
	self.offset = { x, y }
end

function UIWidgetElement:setZOrder( z )
	self.zOrder = z
end

function UIWidgetElement:getZOrder()
	return self.zOrder
end

--------------------------------------------------------------------
function UIWidgetElement:onInit( widget )
end

function UIWidgetElement:onDestroy( widget )
end

function UIWidgetElement:onUpdateStyle( widget, style )
end

function UIWidgetElement:onUpdateContent( widget, style )
end

function UIWidgetElement:onUpdateSize( widget, style )
end