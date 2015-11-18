module 'mock'

CLASS: RenderMaterial ()
	:MODEL{
		Field 'tag'              :string();
		'----';
		Field 'blend'            :enum( EnumBlendMode );
		Field 'shader'           :asset( 'shader' );
		'----';
		Field 'depthMask'        :boolean();
		Field 'depthTest'        :enum( EnumDepthTestMode ) ;
		'----';
		Field 'billboard'        :enum( EnumBillboard );
		Field 'culling'          :enum( EnumCullingMode );
		'----';
		Field 'stencilTest'      :enum( EnumStencilTestMode );
		Field 'stencilTestRef'   :int() :range(0,255);
		Field 'stencilTestMask'  :int() :range(0,255);
		Field 'stencilMask'      :int() :range(0,255);
		Field 'stencilOpSFail'   :enum( EnumStencilOp );
		Field 'stencilOpDPFail'  :enum( EnumStencilOp );
		Field 'stencilOpDPPass'  :enum( EnumStencilOp );

	}

--------------------------------------------------------------------
local CULL_NONE            = MOAIProp. CULL_NONE
local DEPTH_TEST_DISABLE   = MOAIProp. DEPTH_TEST_DISABLE
local STENCIL_TEST_DISABLE = MOAIProp. STENCIL_TEST_DISABLE
local STENCIL_OP_KEEP      = MOAIProp. STENCIL_OP_KEEP
local STENCIL_OP_KEEP      = MOAIProp. STENCIL_OP_KEEP
local STENCIL_OP_REPLACE   = MOAIProp. STENCIL_OP_REPLACE
local BILLBOARD_NONE       = MOAIProp. BILLBOARD_NONE

function RenderMaterial:__init()
	self.tag       = ''
	self.blend     = 'normal'
	self.shader    = false
	
	--
	self.billboard = BILLBOARD_NONE
	self.culling   = CULL_NONE
	
	--depth test
	self.depthMask = false
	self.depthTest = DEPTH_TEST_DISABLE
	
	--stencil
	self.stencilTest = STENCIL_TEST_DISABLE
	self.stencilTestRef   = 0
	self.stencilTestMask  = 0xff
	self.stencilOpSFail   = STENCIL_OP_KEEP
	self.stencilOpDPFail  = STENCIL_OP_KEEP
	self.stencilOpDPPass  = STENCIL_OP_REPLACE
	self.stencilMask      = 0xff

end

function RenderMaterial:applyToMoaiProp( prop )
	self:applyStencilMode( prop )
	self:applyCullMode( prop )
	self:applyBillboard( prop )
	self:applyBlendMode( prop )
	self:applyDepthMode( prop )
	self:applyShader( prop )
end

function RenderMaterial:applyStencilMode( prop )
	prop:setStencilTest( self.stencilTest )
	prop:setStencilOp( self.stencilOpSFail, self.stencilOpDPFail, self.stencilOpDPPass )
	prop:setStencilMask( self.stencilMask )
end

function RenderMaterial:applyCullMode( prop )
	prop:setCullMode( self.culling )	
end

function RenderMaterial:applyBillboard( prop )
	prop:setBillboard( self.billboard )	
end

function RenderMaterial:applyBlendMode( prop )
	setPropBlend( prop, self.blend )
end

function RenderMaterial:applyDepthMode( prop )
	-- prop:setDepthTest( self.depthTest )
	local test = MOAIProp. DEPTH_TEST_LESS_EQUAL
	prop:setDepthTest( test )
	prop:setDepthMask( self.depthMask )
end

function RenderMaterial:applyShader( prop, defaultShader )
	local shaderPath = self.shader
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return prop:setShader( moaiShader )
		end
	end

	if defaultShader then 
		return prop:setShader( defaultShader )
	end

	return prop:setShader( nil )

end


--------------------------------------------------------------------
local DefaultMaterial = RenderMaterial()
DefaultMaterial.tag = '__DEFAULT'

function getDefaultRenderMaterial()
	return DefaultMaterial
	-- return table.simplecopy(DefaultMaterial)
end

--------------------------------------------------------------------
local function loadRenderMaterial( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('def') )
	local config = mock.deserialize( nil, data )	
	return config
end

registerAssetLoader( 'material', loadRenderMaterial )
