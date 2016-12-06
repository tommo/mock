module 'mock'

--------------------------------------------------------------------
local texturePlaceHolder      = false
local texturePlaceHolderImage = false

function getTexturePlaceHolderImage( w, h )
	if not texturePlaceHolderImage then
		w, h = w or 32, h or 32
		texturePlaceHolderImage = MOAIImage.new()
		texturePlaceHolderImage:init( w, h )
		texturePlaceHolderImage:fillRect( 0,0, w, h, 0, 1, 0, 1 )
	end
	return texturePlaceHolderImage
end

function getTexturePlaceHolder()
	if not texturePlaceHolder then
		texturePlaceHolder = MOAITexture.new()
		texturePlaceHolder:load( getTexturePlaceHolderImage( 32, 32 ) )		
	end
	return texturePlaceHolder
end

--------------------------------------------------------------------
local textureLibrary = false
local textureLibraryIndex = false
function getTextureLibrary()
	return textureLibrary
end

function preloadTextureGroup( groupName )
	local group = textureLibrary:getGroup( groupName )
	return group:_preloadAll()
end

function loadTextureLibrary( indexPath )
	if not indexPath then return end
	_stat 'init texture library'
	textureLibraryIndex = indexPath
	textureLibrary = TextureLibrary()	
	if MOAIFileSystem.checkFileExists( indexPath ) then
		-- textureLibrary:loadCache( indexPath )
		textureLibrary:load( indexPath )
	else
		textureLibrary:initDefault()
	end
	return textureLibrary
end

--------------------------------------------------------------------
CLASS: TextureLibrary ()
CLASS: TextureGroup ()
CLASS: Texture ()

--------------------------------------------------------------------
--Texture
--------------------------------------------------------------------
Texture	:MODEL{
		Field 'path' :asset('texture') :readonly() :no_edit(); --view only	
		Field 'w'    :readonly();
		Field 'h'    :readonly();

		----
		Field 'ow' :readonly() :no_edit(); -- for cropped texture
		Field 'oh' :readonly() :no_edit();
		
		Field 'rotated' :boolean() :no_edit();

		Field 'x' :readonly() :no_edit(); --for atlas
		Field 'y' :readonly() :no_edit();
		
		Field 'parent' :type( TextureGroup ) :no_edit();
		Field 'u0' :no_edit();
		Field 'v0' :no_edit();
		Field 'u1' :no_edit();
		Field 'v1' :no_edit();
		
		'----';
		Field 'atlasId' :int() :no_edit();
		Field 'prebuiltAtlasPath' :string() :no_edit();

		'----';		
		Field 'scale'     ;
		Field 'processor' :asset('texture_processor');
		Field 'allowPacked' :boolean();
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
	self.atlasId       = false
	self.scale         = -1
	self.allowPacked   = true
end

function Texture:saveCacheData()
	local data = self:saveMetaData()
	data['w']                 = self.w
	data['h']                 = self.h
	data['ow']                = self.ow
	data['oh']                = self.oh
	data['rotated']           = self.rotated
	data['x']                 = self.x
	data['y']                 = self.y
	data['u0']                = self.u0
	data['v0']                = self.v0
	data['u1']                = self.u1
	data['v1']                = self.v1
	data['atlasId']           = self.atlasId
	data['prebuiltAtlasPath'] = self.prebuiltAtlasPath
	return data
end

function Texture:loadCacheData( data )
	self.scale             = data[ 'scale' ]
	self.w                 = data[ 'w' ]
	self.h                 = data[ 'h' ]
	self.ow                = data[ 'ow' ]
	self.oh                = data[ 'oh' ]
	self.rotated           = data[ 'rotated' ]
	self.x                 = data[ 'x' ]
	self.y                 = data[ 'y' ]
	self.u0                = data[ 'u0' ]
	self.v0                = data[ 'v0' ]
	self.u1                = data[ 'u1' ]
	self.v1                = data[ 'v1' ]
	self.atlasId           = data[ 'atlasId' ]
	self.prebuiltAtlasPath = data[ 'prebuiltAtlasPath' ]
end

function Texture:loadMetaData( data )
	self.scale       = data[ 'scale' ]
	self.processor   = data[ 'processor' ]
	self.allowPacked = data[ 'allowPacked' ]
end

function Texture:saveMetaData()
	local data = {}
	data[ 'group' ]       = self.parent:getName()
	data[ 'scale' ]       = self.scale
	data[ 'processor' ]   = self.processor
	data[ 'allowPacked' ] = self.allowPacked
	return data
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

function Texture:buildInstance()
	return TextureInstance( self )
end

function Texture:getScale()
	local scl = self.scale
	if scl <= 0 then
		return self.parent:getScale()
	end
	return scl
end

--------------------------------------------------------------------
CLASS: TextureInstance ()
	:MODEL{}

function TextureInstance:__init( src )
	self._src = src
	self._texture = false
	self._prebuiltAtlas = false
end

function TextureInstance:getSource()
	return self._src
end

function TextureInstance:getPath()
	return self._src.path
end

function TextureInstance:load()	
	local group = self._src.parent
	group:loadTexture( self )
end

function TextureInstance:unload()
	self._texture = false
	self._prebuiltAtlas = false
end

function TextureInstance:getMoaiTexture()
	return self._texture
end

function TextureInstance:getMoaiTextureUV()
	return self._texture, { self:getUVRect() }
end

function TextureInstance:getSize()
	return self._src:getSize()
end

function TextureInstance:getCroppedSize()
	return self._src:getCroppedSize()
end

function TextureInstance:getPixmapRect()
	return self._src:getPixmapRect()
end

function TextureInstance:getUVRect()
	return self._src:getUVRect()
end

function TextureInstance:getScale()
	return self._src:getScale()
end

function TextureInstance:isPrebuiltAtlas()
	return self._src:isPrebuiltAtlas()
end

function TextureInstance:getPrebuiltAtlas()
	return self._prebuiltAtlas
end


--------------------------------------------------------------------
--Texture Group
--------------------------------------------------------------------

local _loadedTextureTable = table.weak()
function reportLoadedMoaiTextures()
	local output = {}
	for tex in pairs( _loadedTextureTable ) do
		local w, h = tex:getSize()
		table.insert( output, { tex.debugName or '<unknown>', w*h*4 } )
	end
	local function _sortFunc( i1, i2 )
		return i1[1] < i2[1]
	end
	table.sort( output, _sortFunc )
	for i , item in ipairs( output ) do
		printf( '%10d\t%s', item[2], item[1] )
	end
end


TextureGroup :MODEL{
		Field 'name'           :string()  :no_edit();
		Field 'default'        :boolean() :no_edit();

		Field 'format'         :enum( EnumTextureFormat );
		'----';
		Field 'filter'         :enum( EnumTextureFilter );
		Field 'premultiplyAlpha' :boolean();
		Field 'mipmap'         :boolean();
		Field 'wrap'           :boolean();
		Field 'pow2'           :boolean();
		-- Field 'compression'    :enum( EnumTextureCompression );
		'----';
		Field 'atlasMode'      :enum( EnumTextureAtlasMode );
		Field 'maxAtlasWidth'  :enum( EnumTextureSize );
		Field 'maxAtlasHeight' :enum( EnumTextureSize );
		'----';
		Field 'repackPrebuiltAtlas' :boolean();

		'----';
		Field 'scale'          :range( 0.1 );
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
	self.pow2                = false
	self.textures            = {}

	self.scale               = 1

	self._atlasTexturesCache  = makeAssetCacheTable()
end

function TextureGroup:getName()
	return self.name
end

function TextureGroup:saveCacheData()
	local cacheData = {}
	local data = self:saveMetaData()
	data[ 'atlasCachePath' ] = self.atlasCachePath
	return data
end

function TextureGroup:loadCacheData( data )
	self.atlasCachePath = data[ 'atlasCachePath' ]
end

function TextureGroup:saveMetaData()
	local data = {}
	data['name']                = self.name
	data['default']             = self.default
	data['format']              = self.format
	data['filter']              = self.filter
	data['premultiplyAlpha']    = self.premultiplyAlpha
	data['mipmap']              = self.mipmap
	data['wrap']                = self.wrap
	data['pow2']                = self.pow2
	data['compression']         = self.compression
	data['atlasMode']           = self.atlasMode
	data['maxAtlasWidth']       = self.maxAtlasWidth
	data['maxAtlasHeight']      = self.maxAtlasHeight
	data['repackPrebuiltAtlas'] = self.repackPrebuiltAtlas
	data['scale']               = self.scale
	data['processor']           = self.processor
	return data
end

function TextureGroup:loadMetaData( data )
	self.name                = data['name']
	self.default             = data['default']
	self.format              = data['format']
	self.filter              = data['filter']
	self.premultiplyAlpha    = data['premultiplyAlpha']
	self.mipmap              = data['mipmap']
	self.wrap                = data['wrap']
	self.pow2                = data['pow2']
	self.compression         = data['compression']
	self.atlasMode           = data['atlasMode']
	self.maxAtlasWidth       = data['maxAtlasWidth']
	self.maxAtlasHeight      = data['maxAtlasHeight']
	self.repackPrebuiltAtlas = data['repackPrebuiltAtlas']
	self.scale               = data['scale']
	self.processor           = data['processor']
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
	_stat( 'removing texture from library', t.path )
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

function TextureGroup:getScale()
	return self.scale
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
	_stat( 'loading atlas for texture group', self.name )
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

	local prevTex
	for i, atlasInfo in pairs( data[ 'atlases' ] ) do
		local texpath = atlasInfo['name']
		local tex = self:_loadSingleTexture( 
			base .. '/' .. texpath,
			self:getAssetPath() .. '/' .. texpath
		)
		if not tex then
			error( 'error loading texture:' .. texpath )
		end
		tex._previous = prevTex -- make a ref-ring to avoid partial collection
		self._atlasTexturesCache[ i ] = tex
		prevTex = tex
	end
	prevTex._previous = self._atlasTexturesCache[ 1 ]
	
end

function TextureGroup:unloadAtlas()
	self._atlasTexturesCache = {}
	-- self.atlasLoaded = false
end

function TextureGroup:isAtlasLoaded()
	return next( self._atlasTexturesCache ) ~= nil
end

function TextureGroup:loadTexture( instance )
	if instance:isPrebuiltAtlas() then	return self:loadPrebuiltAtlas( instance ) end
	local node = getAssetNode( instance:getPath() )
	if self:isAtlas() then
		if not self:isAtlasLoaded() then
			self:loadAtlas()
		end
		local atlasId = instance:getSource().atlasId
		local tex = self._atlasTexturesCache[ atlasId ]
		if not tex then
			_error( 'texture atlas not in cache', atlasId, self.name )
		end
		instance._texture = tex
	else
		local pixmapPath = node:getObjectFile( 'pixmap' )
		local tex = self:_loadSingleTexture( pixmapPath, instance:getPath() )
		instance._texture = tex
		tex._ownerObject = instance
	end
end

function TextureGroup:loadPrebuiltAtlas( instance )
	local node = getAssetNode( instance:getPath() )
	if self:isAtlas() then --TODO
		if not self:isAtlasLoaded() then
			self:loadAtlas()
		end
	end
	local prebuiltAtlasPath = node:getObjectFile( 'atlas' )
	local prebuiltAtlas = PrebuiltAtlas()
	prebuiltAtlas:load( prebuiltAtlasPath )
	if self:isAtlas() then
		for i, page in ipairs( prebuiltAtlas.pages ) do
			if page.textureAtlasId > 0 then
				local tex = self._atlasTexturesCache[ page.textureAtlasId ]
				if not tex then
					_warn( 'atlas cache not loaded', page.textureAtlasId )				
				end
				page._texture = tex
			end
		end
	else
		for i, page in ipairs( prebuiltAtlas.pages ) do
			local pixmapName = 'pixmap_'..i
			local pixmapPath = node:getObjectFile( pixmapName )
			local debugName  = node:getNodePath() .. '@' .. pixmapName
			local tex = self:_loadSingleTexture( pixmapPath, debugName )
			page._texture = tex
			tex._ownerObject = page
		end
	end
	instance._prebuiltAtlas = prebuiltAtlas
end

function TextureGroup:_loadSingleTexture( pixmapPath, debugName )
	_stat( 'loading single texture from pixmap:' , pixmapPath, debugName )
	local tex = MOAITexture.new()
	tex.pixmapPath = pixmapPath

	local transform = 0
	if self.premultiplyAlpha then
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

	local filePath = getProjectPath( pixmapPath )	
	if not filePath then
		_warn( 'nil imagepath specified', self.debugName )
		tex:load( getTexturePlaceHolderImage() )
		return tex
	end
	
	local async = TEXTURE_ASYNC_LOAD
	if self.format == 'PVR-4' or self.format == 'PVR-2' then
		--todo: use async raw data loading routine
		async = false
	end

	if async then
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
	tex.debugName = debugName
	_loadedTextureTable[ tex ] = true
	return tex
end

function TextureGroup:_preloadAll()
	local instances = {}
	for path, texture in pairs( self.textures ) do
		local instance = texture:buildInstance()
		instance:load()
		instances[ instance ] = true
	end
	return instances
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
	-- local defaultGroup = self:addGroup()
	-- defaultGroup.name = 'DEFAULT'
	-- defaultGroup.default = true
	-- self.defaultGroup = defaultGroup
end

function TextureLibrary:save( path )
	_stat( 'saving texture library', path )
	return serializeToFile( self, path )
end

function TextureLibrary:saveCacheData()
	local cacheData = {}
	local groupCacheData   = {}
	local textureCacheData = {}
	for i, group in ipairs( self.groups ) do
		groupCacheData[ group.name ] = group:saveCacheData()
		for j, texture in ipairs( group.textures ) do
			textureCacheData[ texture.path ] = texture:saveCacheData()
		end
	end
	cacheData[ 'groups' ]   = groupCacheData
	cacheData[ 'textures' ] = textureCacheData
	return cacheData
end

function TextureLibrary:loadCacheData( data )
	local groups = {}
	local defaultGroup = false
	for name, groupCacheData in pairs( data[ 'groups' ] ) do
		local group = TextureGroup()
		group.parent = self
		table.insert( groups, group )
		group:loadCacheData( groupCacheData )
		if group.default then
			defaultGroup = group
		end
	end
	self.groups = groups
	self.defaultGroup = defaultGroup
end

function TextureLibrary:saveGroupData()
	local output = {}
	for i, group in ipairs( self.groups ) do
		local data = group:saveMetaData()
		local name = group.name
		output[ name ] = data
	end
	return output
end

function TextureLibrary:loadGroupData( data )
	local groups = {}
	local defaultGroup = false
	for i, entry in ipairs( data ) do
		local group = TextureGroup()
		group.parent = self
		groups[ i ] = group
		group:loadMetaData( entry )
		if group.default then
			if defaultGroup then
				_warn( 'multiple default texture group', defaultGroup.name, group.name )
			end
			defaultGroup = group
		end
	end
	self.groups = groups
	self.defaultGroup = defaultGroup
end

function TextureLibrary:collectTextureMetaData()
	local result = {}
	for i, group in ipairs( self.groups ) do
		for _, tex in ipairs( group.textures ) do
			result[ tex.path ] = tex:saveMetaData()
		end
	end
	return result
end

function TextureLibrary:initDefault()
	_stat( 'initializing texture library' )
	self.groups = {}
	local defaultGroup = self:addGroup()
	defaultGroup.name = 'DEFAULT'
	defaultGroup.default = true
	self.defaultGroup = defaultGroup
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
end

function TextureLibrary:loadCache( path )
	self.defaultGroup = nil
	self.groups = {}
	local cacheData = tryLoadJSONFile( path )
	if not cacheData then error( 'invalid texture cache data' ) end
	self:loadCacheData( cacheData )
end

function TextureLibrary:saveGroupDataToFile( path )
	local data = self:saveGroupData()
	saveJSONFile( data, path )
end

function TextureLibrary:saveCacheDataToFile( path )
	local data = self:saveCacheData()
	saveJSONFile( data, path )
end

function TextureLibrary:clearEmptyNodes()
	local getAssetNode = getAssetNode
	for i, group in ipairs( self.groups ) do
		local newTextures = {}
		for i, tex in ipairs( group.textures ) do --clear removed textures
			if getAssetNode( tex.path ) then
				table.insert( newTextures, tex )
				self.lookupDict[ tex.path ] = tex
			else
				_warn( 'texture node removed', tex.path )
			end
		end
		group.textures = newTextures
	end
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

function TextureLibrary:addTexture( path, groupName )
	local group = groupName and self:getGroup( groupName )
	if not group then
		group = self:getDefaultGroup()
	end
	local t = Texture( path )
	group:addTexture( t )
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

--------------------------------------------------------------------
function releaseTexPack( cachePath )
end


--------------------------------------------------------------------
--Asset Loaders
--------------------------------------------------------------------
local function loadTexture( node )
	local texNode = textureLibrary:findTexture( node:getNodePath() )
	if not texNode then return nil end
	local instance = texNode:buildInstance()
	instance:load()
	return instance
end

local function unloadTexture( node, textureInstance )
-- 	local texNode = textureLibrary:findTexture( node:getNodePath() )
-- 	if not texNode then return nil end
-- 	textureInstance:unload()
end


registerAssetLoader( 'texture',         loadTexture, unloadTexture )
registerAssetLoader( 'prebuilt_atlas',  loadTexture, unloadTexture )
