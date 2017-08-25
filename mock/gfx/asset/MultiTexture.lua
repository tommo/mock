module 'mock'

--------------------------------------------------------------------
CLASS: MultiTextureInstance ( TextureInstanceBase )
	:MODEL{}


function MultiTextureInstance:__init()
	self.moaiTexture = MOAIMultiTexture.new()
	self.subTextures = {}
	self.defaultSize = { 32, 32 }
	self.dirty = true
end

function MultiTextureInstance:setDefaultSize( w, h )
	self.defaultSize = { w, h }
end

function MultiTextureInstance:getMoaiTexture()
	self:update()
	return self.moaiTexture
end

function MultiTextureInstance:getSize()
	return unpack( self.defaultSize )
end

function MultiTextureInstance:getMoaiTextureUV()
	local tex = self:getMoaiTexture()
	local uvrect = { self:getUVRect() }
	return tex, uvrect
end


function MultiTextureInstance:getTextures()
	return self.subTextures
end

function MultiTextureInstance:setTextures( subTextures )
	self.subTextures = subTextures
	self:markDirty()
end

function MultiTextureInstance:getTexture( idx )
	return self.subTextures[ idx ]
end

function MultiTextureInstance:setTexture( idx, tex )
	self.subTextures[ idx ] = tex
	self:markDirty()
end

function MultiTextureInstance:markDirty()
	self.dirty = true
end

local function _affirmMoaiTextureInstance( tex )
	if tex:isPacked() then
		_warn( 'attempt to use packed texture in MultiTexture' )
		return false
	end
	return tex:getMoaiTexture()
end

local function _affirmMoaiTexture( src )
	local tt = type( src )
	if tt == 'string' then --asset
		local tex = loadAsset( src )
		if tex then
			return _affirmMoaiTextureInstance( tex )
		end

	elseif tt == 'table' and isInstance( src, TextureInstance ) then
		return _affirmMoaiTextureInstance( src )

	elseif tt == 'userdata' then
		local className = src:getClassName()
		if className == 'MOAITexture' or className == 'MOAIFrameBufferTexture' then
			return src
		end
	end
	return false
end


local function affrimInt( n )
	n = tonumber( n )
	if type( n ) ~= 'number' then return false end
	if math.floor( n ) ~= n then return false end
	return n
end

local MAX_TEX_COUNT = 12
function MultiTextureInstance:update( forced )
	if ( not self.dirty ) and ( not forced ) then return true end
	local count = 0
	local moaiTextures = {}
	for n, texture in pairs( self.subTextures ) do
		local idx = affrimInt( n )
		if idx then
			if idx > MAX_TEX_COUNT or idx <= 0 then
				_warn( 'texture index not in range', idx, texture )
			else
				moaiTextures [ idx ] = _affirmMoaiTexture( texture )
				count = math.max( idx, count )
			end
		else
			_warn( 'texture index must be integer', n, texture )
		end
	end

	local moaiTexture = self.moaiTexture
	self.moaiTexture:reserve( count )
	for i = 1, count do
		local t = moaiTextures[ i ] or nil
		self.moaiTexture:setTexture( i, t )
	end
	return true

end


--------------------------------------------------------------------
function createMultiTexture( textures )
	local tex = MultiTextureInstance()
	tex:setTextures( textures or {} )
	return tex
end

--------------------------------------------------------------------
function MultiTextureConfigLoader( node )
	local data = loadAssetDataTable( node:getObjectFile( 'data' ) )
	if not data then return false end
	return createMultiTexture( data and data[ 'textures' ] )
end

addSupportedTextureAssetType( 'multi_texture' )