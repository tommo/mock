module 'mock'

local function JSONDataLoader( node )
	local path = node:getObjectFile( 'data' )
	return loadJSONFile( path, true )
end

local function DataSheetLoader( node )
	local data = loadAsset( node.parent )
	local name = node:getName()
	return data[ name ]
end

registerAssetLoader( 'data_json',  JSONDataLoader )
registerAssetLoader( 'data_xls',   JSONDataLoader )
registerAssetLoader( 'data_sheet',  DataSheetLoader )
