module ('mock')

registerSignals{
	'asset_library.loaded',
}


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

--asset index library
local AssetLibrary = {}
local AssetSearchCache = {}

--asset loaders
local AssetLoaders   = {}
local AssetUnloaders = {}

---env
local AssetBasePath   = false
local ProjectBasePath = false
local AssetLibraryIndex = false

function absAssetPath( path )
	if AssetBasePath then
		return AssetBasePath .. '/' .. ( path or '' )
	else
		return path
	end
end

function absProjectPath( path )
	if ProjectBasePath then
		return ProjectBasePath .. '/' .. ( path or '' )
	else
		return path
	end
end

function setBasePaths( prjBase, assetBase )
	ProjectBasePath = prjBase
	AssetBasePath   = assetBase
end

function getAssetLibraryIndex()
	return AssetLibraryIndex
end

function getAssetLibrary()
	return AssetLibrary
end

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
		return absProjectPath( path )
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
	return absProjectPath( self.filePath )
end

function registerAssetNode( path, data )
	ppath = splitPath(path)
	local node = setmetatable(
		{
			path        = path,
			deploy      = data['deploy'] == true,
			filePath    = data['filePath'],
			properties  = data['properties'],
			objectFiles = data['objectFiles'],
			type        = data['type'],
			parent      = ppath,			
			fileTime    = data['fileTime'],
			dependency  = data['dependency'],
		}, 
		AssetNode
		)

	node.cached = {}
	node.cached.asset = data['type'] == 'folder' and true or false

	AssetLibrary[ path ] = node
	return node
end

function unregisterAssetNode( path )
	AssetLibrary[ path ] = nil
end


function getAssetNode( path )
	return AssetLibrary[ path ]
end

function getAssetType( path )
	local node = getAssetNode( path )
	return node and node:getType()
end

--------------------------------------------------------------------
--loader: func( assetType, filePath )
function registerAssetLoader( assetType, loader, unloader )
	AssetLoaders[ assetType ]   = loader
	AssetUnloaders[ assetType ] = unloader
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
			if not assetType or node.type == assetType then
				if k == path then
					result = node
					break
				elseif k:endWith( path ) then
					result = node
					break
				elseif stripExt( k ):endWith( path ) then
					result = node
					break
				end
			end
		end
		AssetSearchCache[ tag ] = result or false
	end
	return result or nil
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
function loadAsset( path, option )
	if path == '' then return nil end
	if not path   then return nil end
	option = option or {}
	loadPolicy   = option.loadPolicy or 'auto'
	local node   = getAssetNode( path )
	if not node then 
		_warn ( 'no asset found', path or '???' )
		return nil
	end

	if loadPolicy ~= 'force' then
		local asset  = node.cached.asset
		if asset then
			return asset, node
		end
	end

	_stat( 'loading asset from:', path )
	if loadPolicy ~= 'auto' and loadPolicy ~='force' then return nil end

	if node.parent then
		loadAsset( node.parent )
		if node.cached.asset then return node.cached.asset end --already preloaded		
	end

	--load from file
	local atype  = node.type
	local loader = AssetLoaders[ atype ]
	if not loader then return false end
	local asset, cached  = loader( node, option )	
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

--------------------------------------------------------------------
function releaseAsset( path )
	-- 	
	node = getAssetNode( path )
	if node then
		local atype  = node.type
		local unloader = AssetUnloaders[ atype ]
		if unloader then
			unloader( asset, node )
		end
		node.cached = {}
		_stat( 'released node asset', path )
	end

end

