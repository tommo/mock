module 'mock'

--------------------------------------------------------------------
CLASS: LUTGeneratorCameraPass ( CameraPass )

function LUTGeneratorCameraPass:onInit()
end


function LUTGeneratorCameraPass:onBuild()
	--OUPUT
	self:pushDefaultRenderTarget{clearColor = '#c7af3e'}
	local layer, prop, quad = self:buildSingleQuadRenderLayer( TextureHelper.buildBaseLUT() )
	self:pushCallback( function() print( 'render' ) end )
	self:pushRenderLayer( layer )
end


--------------------------------------------------------------------
CLASS: LUTGeneratorCamera ( Camera )
	:MODEL{}

function LUTGeneratorCamera:__init()
	self.targetTexture = RenderTargetTexture()
	self.targetTexture:init( 1024, 32, 'linear', MOAITexture.GL_RGBA16F )
	self:setOutputRenderTarget( self.targetTexture:getRenderTarget() )
end

function LUTGeneratorCamera:getLUT()
	return self.targetTexture
end

function LUTGeneratorCamera:getMoaiFrameBuffer()
	return self.targetTexture:getMoaiFrameBuffer()
end

function LUTGeneratorCamera:loadPasses()
	self:addPass( LUTGeneratorCameraPass() )
end

function LUTGeneratorCamera:manualRender()
	local renderCommandTable = self:buildRenderCommandTable()
	MOAINodeMgr.update()
	MOAIRenderMgr.renderTable( renderCommandTable )
end
