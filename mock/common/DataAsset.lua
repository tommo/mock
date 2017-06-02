module 'mock'

--------------------------------------------------------------------
local function JSONDataLoader( node )
	local path = node:getObjectFile( 'data' )
	local metaPath = node:getObjectFile( 'meta_data' )
	local data = loadJSONFile( path, true )
	if metaPath then
		local metaData = loadJSONFile( metaPath, true )
		node.cached.meta = metaData
	end
	return data
end

registerAssetLoader( 'data_json',   JSONDataLoader )
registerAssetLoader( 'data_yaml',   JSONDataLoader )
registerAssetLoader( 'data_csv',    JSONDataLoader )

