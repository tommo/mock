module 'mock'

--------------------------------------------------------------------
local TBInited = false
local function _affirmTBMgr()
	if not TBInited then
		MOAITBMgr.init()
		MOAITBMgr.loadSkin( 
			'resources/default_skin/skin.tb.txt',
			'skin/skin.tb.txt'
		)
		TBInited = true
	end
end

CLASS: TBCanvas ( mock.RenderComponent )
	:MODEL{
		Field "size" :type( 'vec2' ) :getset( 'Size' ) 
}

function TBCanvas:__init()
	self.x0 = false
	self.y0 = false
	self.width  = 400
	self.height = 300
	self.canvas = MOAITBCanvas.new()
	self:setBlend( 'alpha' )
end

function TBCanvas:getMoaiTBCanvas()
	return self.canvas
end

function TBCanvas:onAttach( ent )
	_affirmTBMgr()
	ent:_attachTransform( self.canvas )
	ent:_insertPropToLayer( self.canvas )
	installInputListener( self )
end

function TBCanvas:onDetach( ent )
	ent:_detachProp( self.canvas )
	uninstallInputListener( self )
end

function TBCanvas:onStart()
	self.canvas:start()
end

function TBCanvas:onKeyEvent( key, down )
	self.canvas:sendKeyEvent( string.byte(key), down )
end

function TBCanvas:onMouseEvent( ev, x, y, btn, mockup )
	if ev == 'down' then
		if btn == 'left' then
			return self.canvas:sendMouseButtonEvent( 1, true )
		end
	elseif ev == 'up' then
		if btn == 'left' then
			return self.canvas:sendMouseButtonEvent( 1, false )
		end
	elseif ev == 'move' then
		x, y = self._entity:wndToModel( x, y )
		y = -y
		local dx, dy
		if self.x0 then
			dx = x - self.x0
			dy = y - self.y0
		else
			dx, dy = 0,0
		end
		self.x0, self.y0 = x, y
		return self.canvas:sendMouseMoveEvent( x, y, dx, dy )
	end
end

function TBCanvas:setBlend( b )
	self.blend = b
	setPropBlend( self.canvas, b )
end

function TBCanvas:setDepthMask( enabled )
	self.depthMask = enabled
	self.canvas:setDepthMask( enabled )
end

function TBCanvas:setDepthTest( mode )
	self.depthTest = mode
	self.canvas:setDepthTest( mode )
end

function TBCanvas:setBillboard( billboard )
	self.billboard = billboard
	self.canvas:setBillboard( billboard )
end

function TBCanvas:getSize()
	return self.width, self.height
end

function TBCanvas:setSize( w, h )
	self.width = w
	self.height = h
	return self.canvas:setSize( w, h )
end

function TBCanvas:getRootWidget()
	return self.canvas:getRootWidget()
end

------------------------------------------------------------------
local defaultShader = MOAIShaderMgr.getShader( MOAIShaderMgr.DECK2D_SHADER )

function TBCanvas:setShader( shaderPath )
	self.shader = shaderPath	
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return self.canvas:setShader( moaiShader )
		end
	end
	self.canvas:setShader( defaultShader )
end

mock.registerComponent( 'TBCanvas', TBCanvas )
mock.registerEntityWithComponent( 'TBCanvas', TBCanvas )

