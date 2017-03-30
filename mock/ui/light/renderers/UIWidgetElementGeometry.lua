module 'mock'

--------------------------------------------------------------------
CLASS: UIWidgetElementGeometryRect ( UIWidgetElement )
	:MODEL{}

function UIWidgetElementGeometryRect:__init()
end

function UIWidgetElementGeometryRect:onInit( widget )
	local geom = widget:attachInternal( GeometryRect() )
	self.geom = geom
end

function UIWidgetElementGeometryRect:onDestroy( widget )
	widget:detach( self.geom )
end

function UIWidgetElementGeometryRect:onUpdateStyle( widget, style )
	local geom = self.geom
	local filled = { style:getBoolean( self:makeStyleName( 'filled' ), true ) }
	local color = { style:getColor( self:makeStyleName( 'color' ), { 1,1,1,1 } ) }
	geom:setColor( unpack( color ) )
	geom:setFilled( filled )
end

function UIWidgetElementGeometryRect:onUpdateSize( widget, style )
	local geom = self.geom
	local ox, oy = self:getOffset()
	local x0, y0, x1, y1 = self:getRect()
	-- geom:setRect( x0 + ox, y0 + oy, x1 + ox, y1 + oy )
	local w, h = x1-x0, y1-y0
	geom:setLoc( x0 + ox + w/2, y0 + oy + h/2, self:getZOrder() )
	geom:setSize( w, h )
end
