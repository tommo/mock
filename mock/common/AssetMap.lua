module 'mock'

CLASS: AssetMap ()
	:MODEL{
	}

function AssetMap:__init()
	self.entryMap = {}
	self.pathMap  = {}
	self.assetCount = 0
end

function AssetMap:getEntry( id )
	return self.pathMap[ id ] 
end

function AssetMap:getPath( key )
	return self.pathMap[ idx ]
end

function AssetMap:getCount()
	return self.assetCount
end

function AssetMap:getPaths()
	return self.pathMap
end

function AssetMap:loadData( data )
	self.entryMap = data
	local paths = {}
	for k, entry in pairs( data ) do
		paths[ k ] = entry[ 'path' ]
	end
	self.pathMap = paths
end

--------------------------------------------------------------------
function loadAssetMap( node )
	local data = loadAssetDataTable( node:getObjectFile('data') )
	local map = AssetMap()
	map:loadData( data )
	return map
end

mock.registerAssetLoader( 'asset_map', loadAssetMap )
