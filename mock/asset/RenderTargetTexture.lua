module 'mock'
CLASS: RenderTargetTexture ( Texture )
	:MODEL{
		Field 'width'  :int();
		Field 'height' :int();
		Field 'filter' :enum( EnumTextureFilter );
		Field 'depth'  :boolean();
	}

function RenderTargetTexture:__init()
	self.framebuffer = MOAIFrameBufferTexture.new()
	self.renderTarget = RenderTarget( self.framebuffer )
	self.depth  = false
	self.width  = 256
	self.height = 256

	self.filter = 'linear'
	self.type   = 'framebuffer'
end

function RenderTargetTexture:getSize()
	return self.width, self.height
end

function RenderTargetTexture:getMoaiTextureUV()
	return self.framebuffer, { 0,0,1,1 }
end

function RenderTargetTexture:getMoaiFrameBuffer()
	self:update()
	return self.framebuffer
end

local function _convertFilter( filter, mipmap )
	local output
	if filter == 'linear' then
		if mipmap then
			output = MOAITexture.GL_LINEAR_MIPMAP_LINEAR
		else
			output = MOAITexture.GL_LINEAR
		end
	else  --if fukter == 'nearest' then
		if mipmap then
			output = MOAITexture.GL_NEAREST_MIPMAP_NEAREST
		else
			output = MOAITexture.GL_NEAREST
		end
	end	
	return output
end

function RenderTargetTexture:update()
	local fb = self.framebuffer
	local gfx = game.gfx
	if self.depth and false then
		local depthFormat = MOAITexture.GL_DEPTH_COMPONENT16
		fb:init( 
			self.width, self.height, nil, depthFormat
		)
		fb:setClearDepth( self.depth )
	else
		fb:init( self.width, self.height )
	end
	fb:setClearColor( 0,0,0,0 )
	local output = _convertFilter( self.filter, false )
	fb:setFilter( output, output )
end


function RenderTargetTextureLoader( node )
	local data = loadAssetDataTable( node:getObjectFile( 'def' ) )
	return deserialize( nil, data )
end

registerAssetLoader( 'rendertarget',   RenderTargetTextureLoader )
