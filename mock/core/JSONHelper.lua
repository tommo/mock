module 'mock'

local function clearNullUserdata( t )
	for k,v in pairs( t ) do
		local tt = type( v )
		if tt == 'table' then
			clearNullUserdata( v )
		elseif tt == 'userdata' then
			t[ k ] = nil
		end
	end	
end

function loadJSONText( text, clearNulls )
	local data =  MOAIJsonParser.decode(text)
	if not data then 
		_error( 'json file not parsed: '..path )
		return nil
	end
	if clearNulls then
		clearNullUserdata( data )
	end
	return data
end

function loadJSONFile( path, clearNulls )
	local f = io.open( path, 'r' )
	if not f then
		_error( 'data file not found:' .. tostring( path ),2  )
		return nil
	end
	local text=f:read('*a')
	f:close()

	return loadJSONText( text, clearNulls )
end


function tryLoadJSONFile( path, clearNulls )
	local succ, data = pcall( loadJSONFile, path, clearNulls )
	if succ then return data end
	return nil
end

function saveJSONFile( data, path, dataInfo )
	local output = encodeJSON( data )
	local file = io.open( path, 'w' )
	if file then
		file:write(output)
		file:close()
		_stat( dataInfo, 'saved to', path )
	else
		_error( 'can not save ', dataInfo , 'to' , path )
	end
end