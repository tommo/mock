module ('mock')

registerSignals{
	'asset_library.loaded',
}


--tool functions
local function fixpath(p)
	p=string.gsub(p,'\\','/')
	return p
end


function splitPath( path )
	path = fixpath( path )
	return string.match( path, "(.-)[\\/]-([^\\/]-%.?([^%.\\/]*))$" )
end

function stripExt(p)
	return string.gsub( p, '%..*$', '' )
end

function stripDir(p)
	p=fixpath(p)
	return string.match(p, "[%w_.%%]+$")
end

--asset index library
local AssetLibrary = {}

--asset loaders
local AssetLoaders = {}

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
	
	AssetLibrary={}
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
	return self.objectFiles[ name ]
end

function AssetNode:getFilePath( )
	return self.filePath
end

function AssetNode:getAbsObjectFile( name )
	local path = self.objectFiles[ name ]
	if path then
		return absProjectPath( path )
	else
		return false
	end
end

function AssetNode:getAbsFilePath()
	return absProjectPath( self.filePath )
end



function registerAssetNode( path, data )
	ppath=splitPath(path)
	local node = setmetatable(
		{
			path        = path,
			deploy      = data['deploy'] == true,
			filePath    = data['filePath'],
			properties  = data['properties'],
			objectFiles = data['objectFiles'],
			type        = data['type'],
			parent      = ppath,
			asset       = data['type'] == 'folder' and true or false
		}, 
		AssetNode
		)
	
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
function registerAssetLoader( assetType, loader )
	AssetLoaders[ assetType ] = loader
end

--------------------------------------------------------------------
--put preloaded asset into AssetNode of according path
function preloadIntoAssetNode( path, asset )
	local node = getAssetNode( path )
	if node then
		node.asset = asset 
		return asset
	end
	return false
end

--------------------------------------------------------------------
function findAsset( path )
	error('todo')	
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
		local asset  = node.asset
		if asset then
			return asset, node
		end
	end

	_stat( 'loading asset from:', path )
	if loadPolicy ~= 'auto' and loadPolicy ~='force' then return nil end

	if node.parent then
		loadAsset( node.parent )
		if node.asset then return node.asset end --already preloaded		
	end

	--load from file
	local atype  = node.type
	local loader = AssetLoaders[ atype ]
	if not loader then return false end
	local asset, cached  = loader( node, option )	
	if asset then
		if cached ~= false then
			node.asset = asset
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
		node.asset = nil
		_stat( 'released node asset', path )
	end

end

