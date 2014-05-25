module ('mock')

-- TEXTURE_ASYNC_LOAD = true
TEXTURE_ASYNC_LOAD = false

--------------------------------------------------------------------
local texturePlaceHolder = false
local texturePlaceHolderImage = false
function getTexturePlaceHolderImage()
	if not texturePlaceHolderImage then
		texturePlaceHolderImage = MOAIImage.new()
		texturePlaceHolderImage:init( w, h )
		texturePlaceHolderImage:fillRect( 0,0, w, h, 0, 1, 0, 1 )
	end
	return texturePlaceHolderImage
end

function getTexturePlaceHolder()
	if not texturePlaceHolder then
		texturePlaceHolder = MOAITexture.new()
		texturePlaceHolder:load( getTexturePlaceHolderImage() )		
	end
	return texturePlaceHolder
end


--------------------------------------------------------------------
CLASS: ThreadTextureLoadTask ( ThreadImageLoadTask )
	:MODEL{}

function ThreadTextureLoadTask:setTargetTexture( tex )
	self.texture = tex
end

function ThreadTextureLoadTask:setDebugName( name )
	self.debugName = name
end

function ThreadTextureLoadTask:onComplete( img )
	self.texture:load ( img, self.imageTransform, self.debugName or self.filename )
	self.texture:affirm()	
end

function ThreadTextureLoadTask:onFail()
	_warn( 'failed load texture file:', filePath )
	self.texture:load( getTexturePlaceHolderImage(), self.imageTransform, self.debugName or self.filename )
end


--------------------------------------------------------------------
local function loadTextureAsync( texture, filePath, transform, debugName )
	local task = ThreadTextureLoadTask( filePath, transform )
	task:setTargetTexture( texture )
	task:setDebugName( debugName )
	task:start()	
	return true	
end

--------------------------------------------------------------------
CLASS: TextureLibrary ()
CLASS: TextureGroup ()
CLASS: Texture ()
--------------------------------------------------------------------
Texture	:MODEL{
		Field 'path' :asset('texture') :readonly();
		Field 'u0' :no_edit();
		Field 'v0' :no_edit();
		Field 'u1' :no_edit();
		Field 'v1' :no_edit();
		Field 'w' :readonly();
		Field 'h' :readonly();
		Field 'processor' :asset('texture_processor');

		Field 'parent' :type( TextureGroup ) :no_edit();
	}

function Texture:__init( path )
	self.path = path
	self.u0 = 0
	self.v0 = 1
	self.u1 = 1
	self.v1 = 0
	self.w  = 100
	self.h  = 100
end

function Texture:getMoaiTexture()
	return self._texture
end

function Texture:getSize()
	return self.w, self.h
end

function Texture:getPixmapRect()
	return 0, 0, self.w, self.h
end

function Texture:getUVRect()
	return 0,1,1,0
end

--------------------------------------------------------------------
CLASS: SubTexture ( Texture )
	:MODEL{
		Field ''
	}

--------------------------------------------------------------------
TextureGroup :MODEL{
		Field 'name'           :string()  :no_edit();
		Field 'default'        :boolean() :no_edit();

		Field 'filter'         :enum( EnumTextureFilter );
		Field 'premultiplyAlpha' :boolean();
		Field 'mipmap'         :boolean();
		Field 'wrap'           :boolean();
		Field 'compression'   :enum( EnumTextureCompression );
		'----';
		Field 'atlasMode'      :enum( EnumTextureAtlasMode );
		Field 'maxAtlasWidth'  :enum( EnumTextureSize );
		Field 'maxAtlasHeight' :enum( EnumTextureSize );
		'----';
		Field 'processor'      :asset('texture_processor');

		Field 'cache'          :string() :no_edit();
		Field 'textures'       :array( Texture ) :no_edit();
		Field 'parent'         :type( TextureLibrary ) :no_edit();
		Field 'expanded'       :boolean() :no_edit();
	}

function TextureGroup:__init()
	self.name           = 'TextureGroup'
	self.filter         = 'linear'
	self.mipmap         = false
	self.wrap           = false
	self.atlasMode      = false
	self.maxAtlasWidth  = 1024
	self.maxAtlasHeight = 1024
	self.default        = false
	self.expanded       = true
	self.cache          = false
	self.compression    = false
	self.premultiplyAlpha = true
	self.textures  = {}
end

function TextureGroup:addTextureFromPath( path )
	local t = Texture()
	t.path = path
	return self:addTexture( t )
end

function TextureGroup:addTexture( t )
	local pg = t.parent
	if pg == self then return end
	if pg then pg:removeTexture( t ) end
	table.insert( self.textures, t )
	t.parent = self
	return t
end

function TextureGroup:removeTexture( t )
	for i, t1 in ipairs( self.textures ) do
		if t1 == t then 
			table.remove( self.textures, i )
			t.parent = false
			return
		end
	end
end

function TextureGroup:findTexture( path )
	for i, t in ipairs( self.textures ) do
		if t.path == path then
			return t
		end
	end
	return nil
end

function TextureGroup:findAndRemoveTexture( path )
	for i, t in ipairs( self.textures ) do
		if t.path == path then
			table.remove( self.textures, i )
			t.parent = false
			return t
		end
	end
	return false
end
--------------------------------------------------------------------
TextureLibrary :MODEL{
		Field 'groups' :array( TextureGroup ) :no_edit();
	}

function TextureLibrary:__init()
	self.groups = {}	
end

function TextureLibrary:getDefaultGroup()
	return self.defaultGroup
end

function TextureLibrary:getGroup( name )
	for i, g in ipairs( self.groups ) do
		if g.name == name then return g end
	end
	return nil
end

function TextureLibrary:addGroup()
	local g = TextureGroup()
	g.parent = self
	table.insert( self.groups, g )
	return g
end

function TextureLibrary:removeGroup( g, moveItemsToDefault )
	for i, g1 in ipairs( self.groups ) do
		if g1 == g then 
			table.remove( self.groups, i )
			g.parent = false
			if moveItemsToDefault then
				local default = self.defaultGroup
				for i, t in ipairs( g.textures ) do
					t.parent = false
					default:addTexture( t )
				end
			end
			return
		end
	end
end

function TextureLibrary:addTexture( path )
	local t = Texture( path )
	self.defaultGroup:addTexture( t )
	return t
end

function TextureLibrary:findTexture( path )
	for i, g in ipairs( self.groups ) do
		local t = g:findTexture( path )
		if t then return t end
	end
	return nil
end

function TextureLibrary:affirmTexture( path )
	local t = self:findTexture( path )
	if not t then
		t = self:addTexture( path )
	end
	return t
end

function TextureLibrary:removeTexture( path )
	for i, g in ipairs( self.groups ) do
		local t =g:findAndRemoveTexture( path )
		if t then return t end
	end
	return false
end

--------------------------------------------------------------------
local defaultTextureConfig = {
	filter             = 'nearest',
	wrapmode           = 'clamp',
	mipmap             = false,
	premultiplyAalpha  = true,
}


--------------------------------------------------------------------
local function loadSingleTexture( pixmapPath, group, debugName )
	_stat( 'loading texture from pixmap:' , pixmapPath )

	local tex = MOAITexture.new()
	tex.pixmapPath = pixmapPath

	local transform = 0
	if group['premultiplyAalpha'] ~= false then
		transform = transform + MOAIImage.PREMULTIPLY_ALPHA
	end
	-- transform = transform + MOAIImage.QUANTIZE
	local filter
	if group.filter == 'linear' then
		if group.mipmap then
			filter = MOAITexture.GL_LINEAR_MIPMAP_LINEAR
		else
			filter = MOAITexture.GL_LINEAR
		end
	else  --if group.filter == 'nearest' then
		if group.mipmap then
			filter = MOAITexture.GL_NEAREST_MIPMAP_NEAREST
		else
			filter = MOAITexture.GL_NEAREST
		end
	end	

	tex:setFilter( filter )
	tex:setWrap( group.wrap )

	local filePath = absProjectPath( pixmapPath )	
	if TEXTURE_ASYNC_LOAD then
		loadTextureAsync( tex, filePath, transform, debugName or pixmapPath )
	else
		tex:load( filePath, transform, debugName )
		if tex:getSize() <= 0 then
			_warn( 'failed load texture file:', path )
			tex:load( getTexturePlaceHolderImage() )
		end
	end
	tex.type = 'texture'
	return tex

end


--------texpack
local function loadTexPack( config )	
	local base = config[ 'cache' ]
	local configPath = base .. '/atlas.json'
	local f = io.open( configPath, 'r' )
	if not f then 
		error( 'file not found:' .. configPath, 2 )   --TODO: proper exception handle
		return nil
	end
	local text = f:read( '*a' )
	f:close()
	local data = MOAIJsonParser.decode( text )

	if not data then 
		error('atlas config file not parsable') --TODO: proper exception handle
		return nil
	end
	local atlases  = {}
	local textures = {}
	for i, atlasInfo in pairs( data[ 'atlases' ] ) do
		local texpath = atlasInfo['name']
		local tex = loadSingleTexture( 
			base .. '/' .. texpath,
			config,
			config['name']..'/'..texpath
		)
		if not tex then
			error( 'error loading texture:' .. texpath )
		end
		atlases[i] = {
			path    = texpath,
			size    = atlasInfo['size'],
			texture = tex
		}
	end

	for i,item in pairs( data[ 'items' ] ) do
		local x, y, w, h = unpack( item.rect )
		local tw, th
		local atlas = atlases[ item.atlas + 1 ]
		local tex  = atlas.texture
		local name = item.name		
		if atlas.size then
			tw, th = unpack( atlas.size )
		else
			tw,th = tex:getSize()
		end
		local u0, v0, u1, v1 = x/tw, y/th, (x+w)/tw, (y+h)/th
		textures[ name ] = SubTexture:rawInstance{
			type   = 'sub_texture',
			name   = name,
			atlas  = tex,
			rect   = item.rect,
			uv     = { u0, v1, u1, v0 },
			w      = w,
			h      = h,
			x      = x,
			y      = y,
			source = item.source
		}
	end
	local pack ={
		atlases  = atlases,
		textures = textures
	}

	return pack
end

-----
local loadedTexPack = {}

local function getTexPack( config )
	local pack = loadedTexPack[ config.cache ]
	if pack then return pack end
	pack = loadTexPack( config )
	loadedTexPack[ config.cache ] = pack
	return pack
end

--------texpack
local function loadSubTexture( path, config )
	local pack = getTexPack( config )	
	assert( pack, 'texpack not loaded correctly.')
	local sub = pack.textures[ path ]
	return sub
end

-------main
local function loadTexture( node )
	local configPath = node:getAbsObjectFile( 'config' )
	
	local config = loadAssetDataTable( configPath ) or defaultTextureConfig
	if not config[ 'atlas_mode' ] then
		local pixmapPath = node.objectFiles[ 'pixmap' ]
		return loadSingleTexture( pixmapPath, config, node:getNodePath() )
	else
		return loadSubTexture( node.path, config )
	end
	
end

function releaseTexPack( cachePath )
	loadedTexPack[ cachePath ] = nil
end

registerAssetLoader( 'texture',     loadTexture )

-- registerAssetLoader( 'texpack',     loadTexPack )
-- registerAssetLoader( 'sub_texture', loadTexture )
