module 'mock'

CLASS: RenderTarget ( Viewport )
	:MODEL{}

function RenderTarget:__init()
	self.mode = 'relative'
	self.frameBuffer = false
end

function RenderTarget:getFrameBuffer()
	return self.frameBuffer
end

function RenderTarget:setFrameBuffer( buffer )
	self.frameBuffer = buffer
end

function RenderTarget:setClearColor( r,g,b,a ) --todo:remove this
	if not self.frameBuffer then return end
	self:getFrameBuffer():setClearColor( r,g,b,a )
end

function RenderTarget:setClearDepth( clear )
	if not self.frameBuffer then return end
	self:getFrameBuffer():setClearDepth( clear )
end

--------------------------------------------------------------------
CLASS: DeviceRenderTarget ( RenderTarget )
	:MODEL{}

function DeviceRenderTarget:__init( frameBuffer, w, h )
	self.frameBuffer = assert( frameBuffer )
	self.mode = 'fixed'
	self:setPixelSize( w, h )
end

function DeviceRenderTarget:setMode( m )
	_error( 'device rendertarget is fixed' )
end


--------------------------------------------------------------------
local DefaultFrameBufferOptions = {
	filter      = MOAITexture.GL_LINEAR,
	clearDepth  = true,
	colorFormat = false,
	scale       = 1,
	size        = 'relative',
	autoResize  = true
}

--------------------------------------------------------------------

CLASS: TextureRenderTarget ( RenderTarget )
	:MODEL{}


function TextureRenderTarget:__init()
	self.mode = 'relative'
	self.keepAspect = false
	self.previousTextureSize = false
end

function TextureRenderTarget:onUpdateSize()
	local w, h = self:getPixelSize()
	w = w * ( self.scale or 1 )
	h = h * ( self.scale or 1 )
	--remove offset
	self.absPixelRect = { 0,0,w,h }

	local needResize = false
	if self.previousTextureSize then
		--TODO:smarter framebuffer resizing
		if self.previousTextureSize[1] ~= w or self.previousTextureSize[2] ~= h then
			needResize = true
		end
	else
		needResize = true
	end

	if not needResize then return end 

	self.frameBuffer:init( w, h, self.colorFormat, self.depthFormat )
	self.previousTextureSize = { w, h }
end

function TextureRenderTarget:onUpdateScale()
end

function TextureRenderTarget:initFrameBuffer( option )
	option = table.extend( table.simplecopy( DefaultFrameBufferOptions ), option or {} )
	local frameBuffer = MOAIFrameBufferTexture.new()
	self.frameBuffer = frameBuffer

	frameBuffer:setClearColor()
	frameBuffer:setClearDepth( option.clearDpeth or false )

	local depthFormat = MOAITexture.GL_DEPTH_COMPONENT16
	local colorFormat = option.colorFormat or nil
	local filter      = option.filter or MOAITexture.GL_LINEAR
	local scale       = option.scale or 1
	
	self.colorFormat = colorFormat
	self.depthFormat = depthFormat
	self.scale       = scale

	frameBuffer:setFilter( filter )
end

function TextureRenderTarget:clear()
	if self.frameBuffer then
		self.frameBuffer:release()
	end
	TextureRenderTarget.__super.clear( self )
end

