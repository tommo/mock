module 'mock'

--------------------------------------------------------------------
CLASS: LUTGeneratorCameraPass ( CameraPass )

function LUTGeneratorCameraPass:onInit()
end


function LUTGeneratorCameraPass:onBuild()
	--OUPUT
	local size = self:getCamera().LUTSize
	self:pushDefaultRenderTarget()
	local layer, prop, quad = self:buildSingleQuadRenderLayer( 
		TextureHelper.buildBaseLUT( size )
	)
	prop:setScl( 1, -1, 1 )
	self:pushRenderLayer( layer )
end


--------------------------------------------------------------------
CLASS: LUTGeneratorCamera ( Camera )
	:MODEL{}

function LUTGeneratorCamera:__init( size )
	self.LUTSize = 32
	self.targetTexture = RenderTargetTexture()
end

function LUTGeneratorCamera:setLUTSize( size )
	self.LUTSize = size
end

function LUTGeneratorCamera:getMoaiFrameBuffer()
	return self.targetTexture:getMoaiFrameBuffer()
end

function LUTGeneratorCamera:loadPasses()
	local size = self.LUTSize
	self.targetTexture:init( size*size, size, 'linear', MOAITexture.GL_RGBA16F )
	self:setOutputRenderTarget( self.targetTexture:getRenderTarget() )
	self:addPass( LUTGeneratorCameraPass() )
end

function LUTGeneratorCamera:manualRender()
	local renderCommandTable = self:buildRenderCommandTable()
	MOAINodeMgr.update()
	MOAIRenderMgr.renderTable( renderCommandTable )
end

function LUTGeneratorCamera:getTexture()
	return self.targetTexture
end
