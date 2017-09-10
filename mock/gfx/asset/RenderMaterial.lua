module 'mock'

CLASS: RenderMaterial ()
	:MODEL{
		Field 'tag'              :string();
		'----';
		Field 'blend'            :enum( EnumBlendMode );
		Field 'shader'           :asset( 'shader;shader_script' );
		Field 'shaderContext'     :string();
		'----';
		Field 'depthMask'        :boolean();
		Field 'depthTest'        :enum( EnumDepthTestMode ) ;
		'----';
		Field 'billboard'        :enum( EnumBillboard );
		Field 'culling'          :enum( EnumCullingMode );
		'----';
		Field 'priority'         :int();

		'----';
		Field 'stencilTest'      :enum( EnumStencilTestMode );
		Field 'stencilTestRef'   :int() :range(0,255);
		Field 'stencilTestMask'  :int() :range(0,255) :widget( 'bitmask8' );
		Field 'stencilMask'      :int() :range(0,255) :widget( 'bitmask8' );
		Field 'stencilOpSFail'   :enum( EnumStencilOp );
		Field 'stencilOpDPFail'  :enum( EnumStencilOp );
		Field 'stencilOpDPPass'  :enum( EnumStencilOp );

		'----';
		Field 'colorMaskR'       :boolean();
		Field 'colorMaskG'       :boolean();
		Field 'colorMaskB'       :boolean();
		Field 'colorMaskA'       :boolean();

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
	self.blend     = 'alpha'
	self.shader    = false
	self.shaderContext = ''
	
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

	--priority
	self.priority = 0

	--colorMask
	self.colorMaskR = true
	self.colorMaskG = true
	self.colorMaskB = true
	self.colorMaskA = true

end

function RenderMaterial:applyToMoaiProp( prop )
	self:applyCullMode    ( prop )
	self:applyBillboard   ( prop )
	self:applyBlendMode   ( prop )
	self:applyDepthMode   ( prop )
	self:applyShader      ( prop )
	self:applyPriority    ( prop )
	self:applyColorMask   ( prop )
	self:applyStencilMode ( prop )
end

function RenderMaterial:applyColorMask( prop )
	prop:setColorMask( self.colorMaskR, self.colorMaskG, self.colorMaskB, self.colorMaskA )
end

function RenderMaterial:applyStencilMode( prop )
	prop:setStencilTest( self.stencilTest, self.stencilTestRef, self.stencilTestMask )
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
	prop:setDepthMask( self.depthMask )
	prop:setDepthTest( self.depthTest )
end

function RenderMaterial:applyPriority( prop )
	prop:setPriority( self.priority )
end

function RenderMaterial:affirmShader()
	local shader = self.builtShader
	if shader then return shader end
	if shader == false then return false end
	shader = false

	local shaderPath = self.shader
	if shaderPath then
		local parsedContext = parseSimpleValueList( self.shaderContext )
		parsedContext[ 'material' ] = self.assetPath
		shader = buildMasterShader( shaderPath, self, parsedContext )
	end
	self.builtShader = shader
	return shader
end

function RenderMaterial:applyShader( prop )
	local shader = self:affirmShader()
	if shader then
		local moaiShader = shader:getMoaiShader()
		return prop:setShader( moaiShader )
	else
		return prop:setShader( nil )
	end
end

function RenderMaterial:setColorMask( r, g, b, a )
	self.colorMaskR = r
	self.colorMaskG = g
	self.colorMaskB = b
	self.colorMaskA = a
end

function RenderMaterial:getColorMask()
	return self.colorMaskR, self.colorMaskG, self.colorMaskB, self.colorMaskA
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
	config.assetPath = node:getPath()
	return config
end

registerAssetLoader( 'material', loadRenderMaterial )
