module 'mock'

CLASS: RenderComponent( Component )
	:MODEL{
		Field 'material' :asset_pre( 'material' ) :getset( 'Material' );
	}
	:META{
		category = 'graphics'
	}

--------------------------------------------------------------------
local DEPTH_TEST_DISABLE = MOAIProp.DEPTH_TEST_DISABLE
function RenderComponent:__init()
	self.materialPath     = false
	self.material         = false

	self.blend            = 'normal'
	self.shader           = false
	self.billboard        = false
	self.depthMask        = false
	self.depthTest        = DEPTH_TEST_DISABLE

end

function RenderComponent:getMaterial()
	return self.materialPath
end

function RenderComponent:setMaterial( path )
	self.materialPath = path
	self.material = loadAsset( path )
	local material = self.material or getDefaultRenderMaterial()
	return self:applyMaterial( material )
end

function RenderComponent:getMaterialObject()
	return self.material or getDefaultRenderMaterial()
end

function RenderComponent:getEntity()
	return self._entity
end

function RenderComponent:getBlend()
	return self.blend
end

function RenderComponent:setBlend( b )
	self.blend = b	
end

function RenderComponent:setShader( s )
	self.shader = s
end

function RenderComponent:getShader( s )
	return self.shader
end

function RenderComponent:resetMaterial()
	if self.material then
		self:applyMaterial( self.material or getDefaultRenderMaterial() )
	end
end

function RenderComponent:setVisible( f )
end

function RenderComponent:isVisible()
	return true
end

function RenderComponent:setDepthMask( enabled )
	self.depthMask = enabled
end

function RenderComponent:setDepthTest( mode )
	self.depthTest = mode
end

function RenderComponent:setBillboard( billboard )
	self.billboard = billboard
end

function RenderComponent:applyMaterial( material )
end
