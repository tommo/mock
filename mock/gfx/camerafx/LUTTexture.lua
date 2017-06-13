module 'mock'

local _textures = table.weak()

function getLoadedLUTTexture( path )
	return _textures[ path ]
end

local function LUTTextureLoader( node )
	local image  = node:getObjectFile('texture')
	local filter = node:getProperty( 'filter' )
	local path = node:getPath()
	local tex = _textures[ path ]
	if not tex then
		tex = MOAITexture.new()
		_textures[ path ] = tex
	else
		print( 'reloading texture', path )
	end
	tex:load( image, MOAIImage.TRUECOLOR )
	if filter == 'nearest' then
		tex:setFilter( MOAITexture.GL_NEAREST )
	else
		tex:setFilter( MOAITexture.GL_LINEAR )
	end
	return tex
end

registerAssetLoader ( 'lut_texture', LUTTextureLoader )
