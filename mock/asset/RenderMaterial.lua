module 'mock'

CLASS: RenderMaterial ()
	:MODEL{
		Field 'blend'            :enum( EnumBlendMode );
		Field 'shader'           :asset( 'shader' );
		'----';
		Field 'depthMask'        :boolean();
		Field 'depthTest'        :enum( EnumDepthTestMode ) ;
		'----';
		Field 'billboard'        :enum( EnumBillboard );
		Field 'culling'          :enum( EnumCullingMode );
		'----';
		Field 'stencilMask'      :int() :range(0,255);
		Field 'stencilTest'      :enum( EnumStencilTestMode );
		Field 'stencilTestRef'   :int() :range(0,255);
		Field 'stencilTestMask'  :int() :range(0,255);
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

function RenderMaterial:appyToMoaiProp( prop )
	prop:setDepthTest( self.depthMask )
	prop:setDepthTest( self.depthTest )
	prop:setStencilTest( self.stencilTest )
	prop:setStencilOp( self.stencilOpSFail, self.stencilOpDPFail, self.stencilOpDPPass )
	prop:setStencilMask( self.stencilMask )
	prop:setBillboard( self.billboard )	
end


--------------------------------------------------------------------
local DefaultMaterial = RenderMaterial()

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
