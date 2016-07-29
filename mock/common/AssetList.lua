module 'mock'

CLASS: AssetList ()
	:MODEL{
		Field 'assets' :asset_array( '.' )
	}

function AssetList:__init()
	self.assets = {}
end

function AssetList:getAssetPath( idx )
	return self.assets[ idx ]
end

function AssetList:getAsset( idx )
	local path = self.assets[ idx ]
	if not path then return nil end
	return loadAsset( path )
end

function AssetList:getCount()
	return #self.assets
end

function AssetList:ipairs()
	return ipairs( self.assets )
end

function AssetList:getPaths()
	return self.assets
end

function AssetList:loadData( data )
	self.data = data
	local paths = {}
	for i, entry in ipairs( data[ 'assets' ] ) do
		local 
	end
end

--------------------------------------------------------------------
function loadAssetList( node )
	local data = loadAssetDataTable( node:getObjectFile('data') )
	local list = AssetList()
	list:loadData( data )
	return list
end

mock.registerAssetLoader( 'asset_list', loadAssetList )
