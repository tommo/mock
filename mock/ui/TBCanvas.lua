module 'mock'

--------------------------------------------------------------------
CLASS: TBCanvas ( Entity )
	:MODEL{
		Field 'skin' :asset( 'tb_skin' );
		'----';
		Field "size" :type( 'vec2' ) :getset( 'Size' );

}

function TBCanvas:__init()
	self.mousePos = { false, false }
	self.width  = 400
	self.height = 300

	self.skin = false
	self.canvas = MOAITBCanvas.new()
	self.canvas:setBlendMode( MOAIProp.GL_SRC_ALPHA, MOAIProp.GL_ONE_MINUS_SRC_ALPHA ) 

end

function TBCanvas:onLoad()
	self:_attachProp( self.canvas )
end

function TBCanvas:onDestroy()
	self:_detachProp( self.canvas )
end

function TBCanvas:onStart()
	installInputListener( self )
	self.canvas:start()
end

--
function TBCanvas:getSize()
	return self.width, self.height
end

function TBCanvas:refresh()
	self.canvas:doStep( 0, 0 )
end

function TBCanvas:setSize( w, h )
	self.width = w
	self.height = h
	return self.canvas:setSize( w, h )
end

function TBCanvas:getRootInternalWidget()
	return self.canvas:getRootWidget()
end

--hook input
function TBCanvas:onKeyEvent( key, down )
	self.canvas:sendKeyEvent( string.byte(key), down )
end

function TBCanvas:onMouseEvent( ev, x, y, btn, mockup )
	local mx, my = unpack( self.mousePos )
	if ev == 'down' then
		if btn == 'left' then
			return self.canvas:sendMouseButtonEvent( 1, true )
		end
	elseif ev == 'up' then
		if btn == 'left' then
			return self.canvas:sendMouseButtonEvent( 1, false )
		end
	elseif ev == 'move' then
		x, y = self:wndToModel( x, y )
		y = -y
		local dx, dy
		if mx and my then
			dx = x - mx
			dy = y - my
		else
			dx, dy = 0,0
		end
		self.mousePos = { x, y }
		return self.canvas:sendMouseMoveEvent( x, y, dx, dy )
	elseif ev == 'scroll' then
		local dx, dy = x, y
		return self.canvas:sendMouseScrollEvent( mx, my, dx, dy )
	end
end

function TBCanvas:_attachChildEntity( ent )
	if ent.__TBWIDGET then
		return self:attachWidgetEntity( ent )
	end
	return TBCanvas.__super._attachChildEntity( ent )
end

function TBCanvas:attachWidgetEntity( widget )
	local rootTBWidget = self:getRootInternalWidget()
	rootTBWidget:addChild( widget:affirmInternalWidget() )
	self:_attachLoc( widget:getProp() )
	self:refresh()
end

mock.registerEntity( 'TBCanvas', TBCanvas )

