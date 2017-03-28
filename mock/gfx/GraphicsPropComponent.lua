module 'mock'

CLASS: GraphicsPropComponent ( RenderComponent )
	:MODEL{
		Field 'index' :int() :range(0) :getset( 'Index' );
}

function GraphicsPropComponent:__init()
	self.billboard = false
	self.depthMask = false
	self.depthTest = false
	self.prop = self:_createMoaiProp()
	self:setBlend('normal')
end

function GraphicsPropComponent:_createMoaiProp()
	return MOAIProp.new()
end

function GraphicsPropComponent:setBlend( b )
	self.blend = b
	setPropBlend( self.prop, b )
end

function GraphicsPropComponent:setBillboard( billboard )
	self.billboard = billboard
	self.prop:setBillboard( billboard )
end

function GraphicsPropComponent:getMoaiDeck()
	return self.prop:getDeck()
end

function GraphicsPropComponent:setIndex( i )
	self.prop:setIndex( i )
end

function GraphicsPropComponent:getIndex()
	return self.prop:getIndex()
end

function GraphicsPropComponent:setShader( shaderPath )
	self.shader = shaderPath	
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return self.prop:setShader( moaiShader )
		end
	end
	local default = self:getDefaultShader()
	if default then 
		return self.prop:setShader( default )
	end
	return self.prop:setShader( nil )
end

function GraphicsPropComponent:getPickingProp()
	return self.prop
end

function GraphicsPropComponent:setVisible( f )
	self.prop:setVisible( f )
end

function GraphicsPropComponent:isVisible()
	return self.prop:getAttr( MOAIProp.ATTR_VISIBLE ) ~= 0
end

function GraphicsPropComponent:setScissorRect( s )
	self.prop:setScissorRect( s )
end

function GraphicsPropComponent:setLayer( layer )
	layer:insertProp( self.prop )
end

function GraphicsPropComponent:setGrid( grid )
	self.prop:setGrid( grid )
end

function GraphicsPropComponent:getSourceSize()
	return 1, 1, 1
end

function GraphicsPropComponent:sizeToScl( x, y, z )
	local sourceX, sourceY, sourceZ = self:getSourceSize()
	return
		sourceX ~= 0 and (x or sourceX)/sourceX or 0,
		sourceY ~= 0 and (y or sourceY)/sourceY or 0,
		sourceZ ~= 0 and (z or sourceZ)/sourceZ or 0
end

function GraphicsPropComponent:getSize()
	local sx, sy, sz = self:getScl()
	local sourceX, sourceY, sourceZ = self:getSourceSize()
	return sx * sourceX, sy * sourceY, sz * sourceZ 
end

function GraphicsPropComponent:setSize( x, y, z )
	local sx, sy, sz = self:sizeToScl( x, y, z )
	return self.prop:setScl( sx, sy, sz )
end

function GraphicsPropComponent:fitSize( x, y, z )
	local sourceX, sourceY, sourceZ = self:getSourceSize()
	local sx = math.max( ( x or sourceX ) / sourceX, 0 )
	local sy = math.max( ( y or sourceY ) / sourceY, 0 )
	local sz = math.max( ( z or sourceZ ) / sourceZ, 0 )
	local s = math.min( sx, sy, sz )
	self.prop:setScl( s, s, s )
end

function GraphicsPropComponent:seekSize( x, y, z, duration, ease )
	local sx, sy, sz = self:sizeToScl( x, y, z )
	return self.prop:seekScl( sx, sy, sz, duration, ease )
end

function GraphicsPropComponent:setRect( x0, y0, x1, y1 )
	local w = x1 - x0
	local h = y1 - y0
	self:setLoc( x0, y0 )
	self:setSize( w, h, nil )
end

function GraphicsPropComponent:fitRect( x0, y0, x1, y1 )
	local w = x1 - x0
	local h = y1 - y0
	self:setLoc( x0, y0 )
	return self:fitSize( w, h, nil )
end

--------------------------------------------------------------------
function GraphicsPropComponent:getMoaiProp()
	return self.prop
end

function GraphicsPropComponent:onAttach( entity )
	entity:_attachProp( self.prop, 'render' )
end

function GraphicsPropComponent:onDetach( entity )
	entity:_detachProp( self.prop, 'render' )
end


function GraphicsPropComponent:getDefaultShader()
	return nil
end

function GraphicsPropComponent:hide()
	return self.prop:setVisible( false )
end

function GraphicsPropComponent:show()
	return self.prop:setVisible( true )
end

function GraphicsPropComponent:getBounds()
	return self.prop:getBounds()
end

function GraphicsPropComponent:setBounds( x0,y0,z0, x1,y1,z1 )
	return self.prop:setBounds( x0,y0,z0, x1,y1,z1 )
end

function GraphicsPropComponent:inside( x, y, z, pad )
	local _,_,z1 = self.prop:getWorldLoc()
	return self.prop:inside( x,y,z1, pad )
end

function GraphicsPropComponent:getWorldBounds()
	return self.prop:getWorldBounds()
end

function GraphicsPropComponent:applyMaterial( material )
	material:applyToMoaiProp( self.prop )
end

function GraphicsPropComponent:setUVTransform( trans )
	print( 'setting uv transform', trans )
	return self.prop:setUVTransform( trans )
end

wrapWithMoaiPropMethods( GraphicsPropComponent, ':getMoaiProp()' )