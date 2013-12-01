module 'mock'

local function JSONDataLoader( node )
	local path = node:getObjectFile( 'data' )
	local data = loadAssetDataTable( path )

	local f = io.open( path, 'r' )
	if not f then
		_error( 'data file not found:' .. tostring( path ),2  )
		return nil
	end
	local text=f:read('*a')
	f:close()
	
	local data =  MOAIJsonParser.decode(text)
	if not data then 
		_error( 'json file not parsed: '..path )
		return nil
	end
	return data
end

registerAssetLoader( 'data_json',  JSONDataLoader )
registerAssetLoader( 'data_xls',   JSONDataLoader )
