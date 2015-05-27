module 'mock'

local function JSONDataLoader( node )
	local path = node:getObjectFile( 'data' )
	return loadJSONFile( path, true )
end

registerAssetLoader( 'data_json',  JSONDataLoader )
registerAssetLoader( 'data_xls',   JSONDataLoader )
