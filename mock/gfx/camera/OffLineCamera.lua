module 'mock'
--------------------------------------------------------------------
CLASS: OffLineCamera ( Camera )
	:MODEL{}

function OffLineCamera:__init( size )
	self.targetSize = { 32, 32 }
	self.targetFormat = MOAITexture.GL_RGBA8
	-- self.targetDepthFormat = MOAITexture.GL_RGBA8
	self.useDepthBuffer = true
	self.useStencilBuffer = false
	self.targetTexture = RenderTargetTexture()
	self:setClearColor( 0,0,0,0 )
end

function OffLineCamera:setTargetFormat( fmt )
	self.targetFormat = fmt or MOAITexture.GL_RGBA8 
end

function OffLineCamera:setTargetSize( w, h )
	self.targetSize = { w, h }
end

function OffLineCamera:getTargetSize()
	return unpack( self.targetSize )
end

function OffLineCamera:getMoaiFrameBuffer()
	return self.targetTexture:getMoaiFrameBuffer()
end

function OffLineCamera:updateRenderTarget()
	local w, h = unpack( self.targetSize )
	self.targetTexture:init( w, h, 'linear', self.targetFormat, self.useDepthBuffer, self.useStencilBuffer )
	self:setOutputRenderTarget( self.targetTexture:getRenderTarget() )
end

function OffLineCamera:manualRender()
	self._camera:setScl( 1, -1, 1 )
	local renderCommandTable = self:buildRenderCommandTable()
	MOAINodeMgr.update()
	MOAIRenderMgr.renderTable( renderCommandTable )
end

function OffLineCamera:getTexture()
	return self.targetTexture
end

function OffLineCamera:grabCurrentFrame( img )
	img = img or MOAIImage.new()
	self:getMoaiFrameBuffer():grabCurrentFrame( img )
	return img
end

