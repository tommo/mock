module ('mock')

registerGlobalSignals{
	'asset_library.loaded',
}

--------------------------------------------------------------------
local __ASSET_CACHE_MT = { 
	-- __mode = 'kv'
}

local __ASSET_CACHE_LOCKED_MT = { 	
}

local __ASSET_CACHE_WEAK_MODE = 'kv'

function makeAssetCacheTable()
	return setmetatable( {}, __ASSET_CACHE_MT )
end

function _allowAssetCacheWeakMode( allowed )
	__ASSET_CACHE_WEAK_MODE = allowed and 'v' or false
end

function setAssetCacheWeak()
	__ASSET_CACHE_MT.__mode = __ASSET_CACHE_WEAK_MODE
end

function setAssetCacheStrong()
	__ASSET_CACHE_MT.__mode = false
end

--------------------------------------------------------------------
local _retainedAssetTable = {}
function retainAsset( assetPath ) --keep asset during one collection cycle
	local node = getAssetNode( assetPath )
	if not node then return _warn( 'no asset to hold', assetPath ) end
	_retainedAssetTable[ node ] = true
	setmetatable( node.cached, __ASSET_CACHE_LOCKED_MT )
end

function releaseRetainAssets()
	for node in pairs( _retainedAssetTable ) do
		setmetatable( node.cached, __ASSET_CACHE_MT )
	end
	_retainedAssetTable = {}
end


local pendingAssetGarbageCollection = false
local _assetCollectionPreGC

function _doAssetCollection()
	setAssetCacheWeak()
	MOAISim.forceGC()
	setAssetCacheStrong()
	releaseRetainAssets()
end

function _assetCollectionPreGC()
	_doAssetCollection()
	MOAISim.setListener( MOAISim.EVENT_PRE_GC, nil ) --stop
			-- reportLoadedMoaiTextures()
			-- reportAssetInCache()
			-- reportHistogram()
			-- reportTracingObject()
end

--------------------------------------------------------------------
function collectAssetGarbage()
	local collectThread = MOAICoroutine.new()
	collectThread:run( function()
			while true do
				if not isAssetThreadTaskBusy() then break end
				coroutine.yield()
			end
			MOAISim.setListener( MOAISim.EVENT_PRE_GC, _assetCollectionPreGC )
		end
	)
	collectThread:attach( game:getActionRoot() )
	return collectThread
end


--------------------------------------------------------------------

--tool functions
local function fixpath(p)
	p=string.gsub(p,'\\','/')
	return p
end

local function splitPath( path )
	path = fixpath( path )
	return string.match( path, "(.-)[\\/]-([^\\/]-%.?([^%.\\/]*))$" )
end

local function stripExt(p)
	return string.gsub( p, '%..*$', '' )
end

local function stripDir(p)
	p=fixpath(p)
	return string.match(p, "[^\\/]+$")
end

--------------------------------------------------------------------
--asset index library
local AssetLibrary = {}
local AssetSearchCache = {}

--asset loaders
local AssetLoaderConfigs = {}

---env
local AssetLibraryIndex = false

function getAssetLibraryIndex()
	return AssetLibraryIndex
end

function getAssetLibrary()
	return AssetLibrary
end

--------------------------------------------------------------------
function loadAssetLibrary( indexPath )
	if not indexPath then
		_stat( 'asset library not specified, skip.' )
		return
	end
	_stat( 'loading library from', indexPath )
	
	--json assetnode
	local fp = io.open( indexPath, 'r' )
	if not fp then 
		_error( 'can not open asset library index file', indexPath )
		return
	end
	local indexString = fp:read( '*a' )
	fp:close()
	local data = MOAIJsonParser.decode( indexString )
	if not data then
		_error( 'can not parse asset library index file', indexPath )
		return
	end
	
	AssetLibrary = {}
	AssetSearchCache = {}
	for path, value in pairs( data ) do
		--we don't need all the information from python
		registerAssetNode( path, value )		
	end
	AssetLibraryIndex = indexPath
	emitSignal( 'asset_library.loaded' )
end

--------------------------------------------------------------------
-- Asset Node
--------------------------------------------------------------------
CLASS: AssetNode ()
function AssetNode:getName()
	return stripDir( self.path )
end

function AssetNode:getBaseName()
	return stripExt( self:getName() )
end

function AssetNode:getType()
	return self.type
end

function AssetNode:getSiblingPath( name )
	local parent = self.parent
	if parent=='' then return name end
	return self.parent..'/'..name
end

function AssetNode:getChildPath( name )
	return self.path..'/'..name
end

function AssetNode:getObjectFile( name )
	local objectFiles = self.objectFiles
	if not objectFiles then return false end
	return objectFiles[ name ]
end

function AssetNode:getProperty( name )
	local properties = self.properties
	return properties and properties[ name ]
end

function AssetNode:getPath()
	return self.path
end

function AssetNode:getNodePath()
	return self.path
end

function AssetNode:getFilePath( )
	return self.filePath
end

function AssetNode:getAbsObjectFile( name )
	local objectFiles = self.objectFiles
	if not objectFiles then return false end
	local path = objectFiles[ name ]
	if path then
		return getProjectPath( path )
	else
		return false
	end
end

function AssetNode:getDependency( name )
	local dependency = self.dependency
	if not dependency then return false end
	return dependency[name]
end

function AssetNode:getAbsFilePath()
	return getProjectPath( self.filePath )
end

function AssetNode:getParentNode()
	if not self.parent then return nil end
	return AssetLibrary[ self.parent ]
end

function AssetNode:getCache()
	return self.cached
end

function AssetNode:getCachedAsset()
	return self.cached and self.cached.asset
end

function AssetNode:load()
	return loadAsset( self:getNodePath() )
end

function registerAssetNode( path, data )
	local ppath = splitPath(path)
	local node = AssetNode()
	node.path        = path
	node.filePath    = data['filePath']
	node.parent      = ppath			
	node.cached = makeAssetCacheTable()
	node.cached.asset = data['type'] == 'folder' and true or false
	updateAssetNode( node, data )
	AssetLibrary[ path ] = node
	return node
end

function updateAssetNode( node, data ) --dynamic attributes
	node.deploy      = data['deploy'] == true
	node.properties  = data['properties']
	node.objectFiles = data['objectFiles']
	node.type        = data['type']
	node.fileTime    = data['fileTime']
	node.dependency  = data['dependency']
end

function unregisterAssetNode( path )
	AssetLibrary[ path ] = nil
end

function getAssetNode( path )
	return AssetLibrary[ path ]
end

function checkAsset( path )
	return AssetLibrary[ path ] ~= nil
end

function getAssetType( path )
	local node = getAssetNode( path )
	return node and node:getType()
end

--------------------------------------------------------------------
--loader: func( assetType, filePath )
function registerAssetLoader( assetType, loader, unloader, option )
	assert( loader )
	option = option or {}
	AssetLoaderConfigs[ assetType ] = {
		loader      = loader,
		unloader    = unloader or false,
		skip_parent = option['skip_parent'] or false,
		option      = option
	}
end

--------------------------------------------------------------------
--put preloaded asset into AssetNode of according path
function preloadIntoAssetNode( path, asset )
	local node = getAssetNode( path )
	if node then
		node.cached.asset = asset 
		return asset
	end
	return false
end

--------------------------------------------------------------------


function findAssetNode( path, assetType )
	local tag = path..'@'..( assetType or '' )	
	local result = AssetSearchCache[ tag ]
	if result == nil then
		for k, node in pairs( AssetLibrary ) do
			local typeMatched = false
			if not assetType then
				typeMatched = true
			else
				if string.match( node:getType(), assetType ) then
					typeMatched = true
				end
			end
			if typeMatched then
				if k == path then
					result = node
					break
				elseif k:endwith( path ) then
					result = node
					break
				elseif stripExt( k ):endwith( path ) then
					result = node
					break
				end
			end
		end
		AssetSearchCache[ tag ] = result or false
	end
	return result or nil
end	

function affirmAsset( pattern, assetType )
	local path = findAsset( pattern, assetType )
	if not path then
		_error( 'asset not found', pattern, assetType or '<?>' )
	end
	return path
end

function findAsset( path, assetType )
	local node = findAssetNode( path, assetType )
	return node and node.path or nil
end

function findAndLoadAsset( path, assetType )
	local node = findAssetNode( path, assetType )
	if node then
		return loadAsset( node.path )
	end
	return nil
end


--------------------------------------------------------------------
--load asset of node
--------------------------------------------------------------------
local loadingAsset = table.weak_k() --TODO: a loading list avoid cyclic loading?

function hasAsset( path )
	local node = getAssetNode( path )
	return node and true or false 
end

function canPreload( path ) --TODO:use a generic method for arbitary asset types
	local node = getAssetNode( path )
	if not node then return false end
	if node.type == 'scene' then return false end
	return true
end

function loadAsset( path, option )
	if path == '' then return nil end
	if not path   then return nil end
	option = option or {}
	local policy   = option.policy or 'auto'
	local node   = getAssetNode( path )
	if not node then 
		_warn ( 'no asset found', path or '???' )
		print( debug.traceback(2) )
		return nil
	end

	if policy ~= 'force' then
		local asset  = node.cached.asset
		if asset then
			-- _stat( 'get asset from cache:', path, node )
			return asset, node
		end
	end

	_stat( 'loading asset from:', path )
	if policy ~= 'auto' and policy ~='force' then return nil end
	
	local atype  = node.type
	local loaderConfig = AssetLoaderConfigs[ atype ]
	if not loaderConfig then
		_warn( 'no loader config for asset', atype, path )
		return false
	end
	if node.parent and ( not loaderConfig.skip_parent or option['skip_parent'] ) then
		if not loadingAsset[ node.parent ] then
			loadAsset( node.parent, option )
		end
		if node.cached.asset then return node.cached.asset end --already preloaded		
	end

	--load from file
	local loader = loaderConfig.loader
	if not loader then
		_warn( 'no loader for asset:', atype, path )
		return false
	end
	loadingAsset[ path ] = true
	local asset, cached  = loader( node, option )	
	loadingAsset[ path ] = nil
	if asset then
		if cached ~= false then
			node.cached.asset = asset
		end
		return asset, node
	else
		_stat( 'failed to load asset:', path )
		return nil
	end
end

function forceLoadAsset( path ) --no cache
	return loadAsset( path, { policy = 'force' } )
end

function getCachedAsset( path )
	if path == '' then return nil end
	if not path   then return nil end
	option = option or {}
	policy   = option.policy or 'auto'
	local node   = getAssetNode( path )
	if not node then 
		_warn ( 'no asset found', path or '???' )
		return nil
	end
	return node.cached.asset
end


--------------------------------------------------------------------
function releaseAsset( path )
	local node = getAssetNode( path )
	if node then
		local atype  = node.type
		local assetLoaderConfig =  AssetLoaderConfigs[ atype ]
		local unloader = assetLoaderConfig and assetLoaderConfig.unloader
		local newCacheTable = makeAssetCacheTable()
		if unloader then
			unloader( node, asset, newCacheTable )
		end
		node.cached = newCacheTable
		_stat( 'released node asset', path, node )
	end
end


--------------------------------------------------------------------
function reportAssetInCache( typeFilter )
	local output = {}
	if type( typeFilter ) == 'string' then
		typeFilter = { typeFilter }
	elseif type ( typeFilter ) == 'table' then
		typeFilter = typeFilter
	else
		typeFilter = false
	end
	for path, node in pairs( AssetLibrary ) do
		local atype = node:getType()
		if atype ~= 'folder' and node.cached.asset then
			local matched
			if typeFilter then
				matched = false
				for i, t in ipairs( typeFilter ) do
					if t == atype then
						matched = true
						break
					end
				end
			else
				matched = true
			end
			if matched then
				table.insert( output, { path, atype, node.cached.asset } )
			end
		end
	end
	local function _sortFunc( i1, i2 )
		if i1[2] == i2[2] then
			return i1[1] < i2[1]
		else
			return i1[2] < i2[2]
		end
	end
	table.sort( output, _sortFunc )
	for i, item in ipairs( output ) do
		printf( '%s \t %s', item[2], item[1]  )
	end
end

--------------------------------------------------------------------
function loadAssetFolder( path )
	local node = getAssetNode( path )
	if not ( node and node:getAssetType() == 'folder' ) then 
		return _warn( 'folder path expected:', path )
	end
	
end

function isAssetThreadTaskBusy()
	return isTextureThreadTaskBusy() --TODO: other thread?
end