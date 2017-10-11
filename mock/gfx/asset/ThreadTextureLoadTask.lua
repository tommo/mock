module 'mock'

TEXTURE_ASYNC_LOAD = false

TextureThreadTaskGroupID = 'texture_loading'

--------------------------------------------------------------------
CLASS: ThreadTextureLoadTask ( ThreadImageLoadTask )
	:MODEL{}

function ThreadTextureLoadTask:__init()
end

function ThreadTextureLoadTask:getDefaultGroupId()
	return TextureThreadTaskGroupID
end

function ThreadTextureLoadTask:setTargetTexture( tex )
	self.texture = tex
end

function ThreadTextureLoadTask:setDebugName( name )
	self.debugName = name
end

function ThreadTextureLoadTask:onComplete( img )
	local debugName = self.debugName or self.imagePath
	self.texture:load ( img, self.imageTransform, debugName )
	self.texture:affirm()	
	if MOCKHelper.setTextureDebugName then
		MOCKHelper.setTextureDebugName( self.texture, debugName )
	end
end

function ThreadTextureLoadTask:onFail()
	_warn( 'failed load texture file:', filePath )
	self.texture:load( getTexturePlaceHolderImage(), self.imageTransform, self.debugName or self.filename )
end

function ThreadTextureLoadTask:toString()
	return '<textureLoadTask>' .. self.imagePath .. '\t' .. ( self.debugName or '')
end

function isTextureThreadTaskBusy()
	return isThreadTaskBusy( TextureThreadTaskGroupID )
end

function setTextureThreadTaskGroupSize( size )
	getThreadTaskManager():setGroupSize( TextureThreadTaskGroupID, size )
end
