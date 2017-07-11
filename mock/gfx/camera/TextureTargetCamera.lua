module 'mock'

--------------------------------------------------------------------
CLASS: TextureTargetCamera ( Camera )
	:MODEL{}

function TextureTargetCamera:__init( w, h )
	self.targetSize = { w or 128, h or 128 }
	self.targetFormat = MOAITexture.GL_RGBA8
	-- self.targetDepthFormat = MOAITexture.GL_RGBA8
	self.useDepthBuffer = true
	self.useStencilBuffer = false
	self.renderTargetReady = false
	self.passReady = false
	self.targetTexture = RenderTargetTexture()
	self:setClearColor( 0,0,0,0 )
end

function TextureTargetCamera:setTargetFormat( fmt )
	self.targetFormat = fmt or MOAITexture.GL_RGBA8 
	self.renderTargetReady = false
end

function TextureTargetCamera:setTargetSize( w, h )
	self.targetSize = { w, h }
	self.renderTargetReady = false
end

function TextureTargetCamera:getTargetSize()
	return unpack( self.targetSize )
end

function TextureTargetCamera:getMoaiFrameBuffer()
	return self.targetTexture:getMoaiFrameBuffer()
end

function TextureTargetCamera:updateRenderTarget()
	
	local w, h = unpack( self.targetSize )
	self.targetTexture:init( w, h, 'linear', self.targetFormat, self.useDepthBuffer, self.useStencilBuffer )
	self:setOutputRenderTarget( self.targetTexture:getRenderTarget() )
end

function TextureTargetCamera:prepare()
	if not self.renderTargetReady then
		self:updateRenderTarget()
		self.renderTargetReady = true
	end
	if not self.passReady then
		self:loadPasses()
		self.passReady = true
	end
end

function TextureTargetCamera:manualRender()
	self:prepare()
	self._camera:setScl( 1, -1, 1 )
	local renderCommandTable = self:buildRenderCommandTable()
	MOAINodeMgr.update()
	MOAIRenderMgr.renderTable( renderCommandTable )
end

function TextureTargetCamera:getTexture()
	return self.targetTexture
end

