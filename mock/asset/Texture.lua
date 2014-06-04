module 'mock'

local textureLibrary = false
local textureLibraryIndex = false
function getTextureLibrary()
	return textureLibrary
end

function loadTextureLibrary( indexPath )
	if not indexPath then return end
	textureLibraryIndex = indexPath
	textureLibrary = TextureLibrary()	
	textureLibrary:load( indexPath )
	return textureLibrary
end

local function onGameInit( option )
	loadTextureLibrary( option['texture_library'] )
end

local function onGameConfigSave( data )
	data[ 'texture_library' ] = textureLibraryIndex
end

connectSignalFunc( 'game_config.save', onGameConfigSave )
connectSignalFunc( 'game.init', onGameInit )

--------------------------------------------------------------------
CLASS: TextureLibrary ()
CLASS: TextureGroup ()
CLASS: Texture ()

--------------------------------------------------------------------
--Texture
--------------------------------------------------------------------
Texture	:MODEL{
		Field 'path' :asset('texture') :readonly() :no_edit(); --view only	
		Field 'w' :readonly();
		Field 'h' :readonly();

		Field 'ow' :readonly() :no_edit(); -- for cropped texture
		Field 'oh' :readonly() :no_edit();
		
		Field 'rotated' :boolean();

		Field 'x' :readonly(); --for atlas
		Field 'y' :readonly();
		
		Field 'parent' :type( TextureGroup ) :no_edit();
		Field 'u0' :no_edit();
		Field 'v0' :no_edit();
		Field 'u1' :no_edit();
		Field 'v1' :no_edit();
		
		'----';
		Field 'atlasId' :int();
		Field 'prebuiltAtlasPath' :string() :no_edit();

		'----';
		Field 'processor' :asset('texture_processor');
	}

function Texture:__init( path )
	self.path = path
	self.u0 = 0
	self.v0 = 1
	self.u1 = 1
	self.v1 = 0
	self.x  = 0
	self.y  = 0
	self.w  = 100
	self.h  = 100
	self.ow = 100
	self.oh = 100
	
	self.rotated       = false
	self.prebuiltAtlasPath = false
	self.loaded        = false
	self.atlasId       = false	

	self._texture      = false
	self._prebuiltAtlas = false	
end

function Texture:getMoaiTexture()
	return self._texture
end

function Texture:getMoaiTextureUV()
	return self._texture, { self:getUVRect() }
end

function Texture:getSize()
	return self.ow, self.oh
end

function Texture:getCroppedSize()
	return self.w, self.h
end

function Texture:getPixmapRect()
	return 0, 0, self.w, self.h
end

function Texture:getUVRect()
	return self.u0, self.v0, self.u1, self.v1	
end

function Texture:isPrebuiltAtlas()
	local node = getAssetNode( self.path )
	return node:getType() == 'prebuilt_atlas'
end

function Texture:load()	
	if self.loaded then return end
	self.parent:loadTexture( self )
	self.loaded = true
end

function Texture:unload()
end


--------------------------------------------------------------------
--Texture Group
--------------------------------------------------------------------
TextureGroup :MODEL{
		Field 'name'           :string()  :no_edit();
		Field 'default'        :boolean() :no_edit();

		Field 'format'         :enum( EnumTextureFormat );
		'----';
		Field 'filter'         :enum( EnumTextureFilter );
		Field 'premultiplyAlpha' :boolean();
		Field 'mipmap'         :boolean();
		Field 'wrap'           :boolean();
		-- Field 'compression'    :enum( EnumTextureCompression );
		'----';
		Field 'atlasMode'      :enum( EnumTextureAtlasMode );
		Field 'maxAtlasWidth'  :enum( EnumTextureSize );
		Field 'maxAtlasHeight' :enum( EnumTextureSize );
		'----';
		Field 'repackPrebuiltAtlas' :boolean();

		'----';
		Field 'processor'      :asset('texture_processor');

		Field 'atlasCachePath' :string() :no_edit();
		Field 'textures'       :array( Texture ) :no_edit();
		Field 'parent'         :type( TextureLibrary ) :no_edit();
		Field 'expanded'       :boolean() :no_edit();
	}

function TextureGroup:__init()
	self.name                = 'TextureGroup'
	self.format              = 'auto'
	self.filter              = 'linear'
	self.mipmap              = false
	self.wrap                = false
	self.atlasMode           = false
	self.maxAtlasWidth       = 1024
	self.maxAtlasHeight      = 1024
	self.default             = false
	self.expanded            = true
	self.atlasCachePath      = false
	self.compression         = false
	self.premultiplyAlpha    = true
	self.repackPrebuiltAtlas = false
	self.textures            = {}
	self.atlasTextures       = {}
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

function TextureGroup:findPrebuiltAtlas()
	local result = {}
	for i, t in ipairs( self.textures ) do
		if t:isPrebuiltAtlas() then
			table.insert( result, t )
		end
	end
	return result
end

function TextureGroup:getAssetPath()
	return '@texture_pack/'..self.name
end

function TextureGroup:isAtlas()
	return self.atlasMode
end

function TextureGroup:loadAtlas()
	local base = self.atlasCachePath
	if not base then return nil end
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
	for i, atlasInfo in pairs( data[ 'atlases' ] ) do
		local texpath = atlasInfo['name']
		local tex = self:_loadSingleTexture( 
			base .. '/' .. texpath,
			self:getAssetPath() .. '/' .. texpath
		)
		if not tex then
			error( 'error loading texture:' .. texpath )
		end
		self.atlasTextures[ i ] = tex
	end
	self.atlasLoaded = true
end

function TextureGroup:loadTexture( texture )
	if texture:isPrebuiltAtlas() then	return self:loadPrebuiltAtlas( texture ) end
	local node = getAssetNode( texture.path )
	if self:isAtlas() then
		if not self.atlasLoaded then
			self:loadAtlas()
		end
		local tex = self.atlasTextures[ texture.atlasId ]
		texture._texture = tex	
	else
		local pixmapPath = node:getObjectFile( 'pixmap' )
		texture._texture = self:_loadSingleTexture( pixmapPath, texture.path )
	end
end

function TextureGroup:loadPrebuiltAtlas( texture )
	local node = getAssetNode( texture.path )
	if self:isAtlas() then --TODO
		if not self.atlasLoaded then
			self:loadAtlas()
		end
	end
	local prebuiltAtlasPath = node:getObjectFile( 'atlas' )
	local prebuiltAtlas = PrebuiltAtlas()
	prebuiltAtlas:load( prebuiltAtlasPath )
	if self:isAtlas() then
		for i, page in ipairs( prebuiltAtlas.pages ) do
			local tex = self.atlasTextures[ page.textureAtlasId ]
			page._texture = tex
		end
	else
		for i, page in ipairs( prebuiltAtlas.pages ) do
			local pixmapName = 'pixmap_'..i
			local pixmapPath = node:getObjectFile( pixmapName )
			local debugName  = node:getNodePath() .. '@' .. pixmapName
			page._texture = self:_loadSingleTexture( pixmapPath, debugName )
		end
	end
	texture._prebuiltAtlas = prebuiltAtlas		
end

function TextureGroup:_loadSingleTexture( pixmapPath, debugName )
	_stat( 'loading single texture from pixmap:' , pixmapPath )

	local tex = MOAITexture.new()
	tex.pixmapPath = pixmapPath

	local transform = 0
	if self.premultiplyAalpha ~= false then
		transform = transform + MOAIImage.PREMULTIPLY_ALPHA
	end
	-- transform = transform + MOAIImage.QUANTIZE

	local filter
	if self.filter == 'linear' then
		if self.mipmap then
			filter = MOAITexture.GL_LINEAR_MIPMAP_LINEAR
		else
			filter = MOAITexture.GL_LINEAR
		end
	else  --if self.filter == 'nearest' then
		if self.mipmap then
			filter = MOAITexture.GL_NEAREST_MIPMAP_NEAREST
		else
			filter = MOAITexture.GL_NEAREST
		end
	end	

	tex:setFilter( filter )
	tex:setWrap( self.wrap )

	local filePath = absProjectPath( pixmapPath )	
	if TEXTURE_ASYNC_LOAD then
		local task = ThreadTextureLoadTask( filePath, transform )
		task:setTargetTexture( tex )
		task:setDebugName( debugName or filePath )
		task:start()	
	else
		tex:load( filePath, transform, debugName )
		if tex:getSize() <= 0 then
			_warn( 'failed load texture file:', filePath, debugName )
			tex:load( getTexturePlaceHolderImage() )
		end
	end
	return tex
end


--------------------------------------------------------------------
--Texture Library
--------------------------------------------------------------------
TextureLibrary :MODEL{
		Field 'groups' :array( TextureGroup ) :no_edit();
	}

function TextureLibrary:__init()
	self.groups = {}	
	self.lookupDict = {}
	local defaultGroup = self:addGroup()
	defaultGroup.name = 'DEFAULT'
	defaultGroup.default = true
	self.defaultGroup = defaultGroup
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
	self.lookupDict[ path ] = t
	return t
end

function TextureLibrary:findTexture( path )
	return self.lookupDict[ path ]	
end

function TextureLibrary:affirmTexture( path )
	local t = self:findTexture( path )
	if not t then
		t = self:addTexture( path )
	end
	return t
end

function TextureLibrary:removeTexture( path )
	local found
	for i, g in ipairs( self.groups ) do
		local t = g:findAndRemoveTexture( path )
		if t then
			found = t
			break
		end
	end
	if found then
		self.lookupDict[ path ] = nil
		return found
	else
		return false
	end
end

function TextureLibrary:getReport()
	local report = {}
	report[ 'count'  ] = 0
	report[ 'memory' ] = 0
	report[ 'count_peak'  ] = 0
	report[ 'memory_peak' ] = 0
	return report
end

function TextureLibrary:save( path )
	_stat( 'saving texture library', path )
	return serializeToFile( self, path )
end


function TextureLibrary:load( path )
	_stat( 'loading textureLibrary', path )
	self.defaultGroup = nil
	self.groups = {}
	deserializeFromFile( self, path )
	for i, group in ipairs( self.groups ) do
		if group.default then
			self.defaultGroup = group
			break
		end		
	end
	
	local getAssetNode = getAssetNode
	for i, group in ipairs( self.groups ) do
		local textures1 = {}
		for i, tex in ipairs( group.textures ) do --clear removed textures
			if getAssetNode( tex.path ) then
				table.insert( textures1, tex )
				self.lookupDict[ tex.path ] = tex
			end
		end
		group.textures = textures1
	end
end

--------------------------------------------------------------------
function releaseTexPack( cachePath )
end


--------------------------------------------------------------------
--Asset Loaders
--------------------------------------------------------------------
local function loadTexture( node )
	local texNode = textureLibrary:findTexture( node:getNodePath() )
	if texNode then
		texNode:load()
	end
	return texNode	
end

registerAssetLoader( 'texture',         loadTexture )
registerAssetLoader( 'prebuilt_atlas',  loadTexture )
