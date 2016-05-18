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

function RenderTarget:setClearStencil( clear )
	if not self.frameBuffer then return end
	self:getFrameBuffer():setClearStencil( clear )
end

function RenderTarget:getRootRenderTarget()
	local r = self
	while true do
		local p = r.parent
		if not p then break end
		if not p:isInstance( RenderTarget ) then break end
		r = p
	end
	return r
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
	filter           = MOAITexture.GL_LINEAR,
	useStencilBuffer = false,
	useDepthBuffer   = false,
	clearDepth       = true,
	clearStencil     = true,
	colorFormat      = false,
	scale            = 1,
	size             = 'relative',
	autoResize       = true
}

--------------------------------------------------------------------

CLASS: TextureRenderTarget ( RenderTarget )
	:MODEL{}


function TextureRenderTarget:__init()
	self.mode = 'relative'
	self.keepAspect = false
	self.previousTextureSize = false
	self.colorFormat   = false
	self.depthFormat   = false
	self.stencilFormat = false
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

	self.frameBuffer:init( w, h, self.colorFormat, self.depthFormat, self.stencilFormat )
	self.previousTextureSize = { w, h }
end

function TextureRenderTarget:onUpdateScale()
end

function TextureRenderTarget:initFrameBuffer( option )
	option = table.extend( table.simplecopy( DefaultFrameBufferOptions ), option or {} )
	local frameBuffer = MOAIFrameBufferTexture.new()
	self.frameBuffer = frameBuffer
	
	local clearColor = false
	local clearDepth = option.clearDpeth or false   
	local clearStencil = option.clearStencil or false 
	frameBuffer:setClearColor   ( )
	frameBuffer:setClearDepth   ( clearDepth )
	frameBuffer:setClearStencil ( clearStencil )
	local useStencilBuffer  = option.useStencilBuffer or false
	local useDepthBuffer    = option.useDepthBuffer or false

	local colorFormat = option.colorFormat or nil
	local filter      = option.filter or MOAITexture.GL_LINEAR
	local scale       = option.scale or 1
	
	local depthFormat   = false
	local stencilFormat = false
	if useDepthBuffer and useStencilBuffer then
		depthFormat = MOAITexture.GL_DEPTH24_STENCIL8
	else
		depthFormat = useDepthBuffer and MOAITexture.GL_DEPTH_COMPONENT16 or false
		stencilFormat =	useStencilBuffer and MOAITexture.GL_STENCIL_INDEX8 or false
	end
	
	self.useDepthBuffer = useDepthBuffer
	self.useStencilBuffer = useStencilBuffer
	self.colorFormat   = colorFormat
	self.depthFormat   = depthFormat
	self.stencilFormat = stencilFormat
	self.scale         = scale

	frameBuffer:setFilter( filter )
end

function TextureRenderTarget:clear()
	if self.frameBuffer then
		self.frameBuffer:release()
	end
	TextureRenderTarget.__super.clear( self )
end

