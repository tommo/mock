module 'mock'

CLASS: AssetList ()
	:MODEL{
	}

function AssetList:__init()
	self.assetPaths = {}
	self.assets = {}
end

function AssetList:loadAll()
	for i, path in ipairs( self.assetPaths ) do
		local asset = loadAsset( path )
		self.assets[ i ] = asset
	end
end

function AssetList:release()
	self.assets = {}
end

function AssetList:loadData( data )
	local paths = {}
	for i, entry in ipairs( data ) do
		local path = entry[ 'path' ]
		paths[ i ] = path
	end
	self.assetPaths = paths
	self.assets = {}
end

--------------------------------------------------------------------
function loadAssetList( node )
	local data = loadAssetDataTable( node:getObjectFile('data') )
	local list = AssetList()
	list:loadData( data )
	return list
end

mock.registerAssetLoader( 'asset_list', loadAssetList )
