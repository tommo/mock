module 'mock'

--------------------------------------------------------------------
CLASS: DataSheetAccessor ()
	:MODEL{}

function DataSheetAccessor:__init( data, meta, assetPath )
	self._data = data or {}
	self._meta = meta or {}
	self.assetPath = assetPath
end

function DataSheetAccessor:getData()
	return self.data
end

function DataSheetAccessor:translate( source )
	return translateForAsset( self.assetPath, source )
end


--------------------------------------------------------------------
CLASS: DataSheetDictAccessor ( DataSheetAccessor )
	:MODEL{}
	
function DataSheetDictAccessor:get( k, default )
	local v = self._data[ k ]
	if v == nil then return default end
	return v
end

--------------------------------------------------------------------
CLASS: DataSheetListAccessor ( DataSheetAccessor )
	:MODEL{}

function DataSheetListAccessor:__init()
	self._idMap = false
end

function DataSheetListAccessor:_affirmIdMap()
	local map = self._idMap
	if not map then
		map = {}
		self._idMap = map
		local keys = self._meta[ 'keys' ]
		if table.index( keys, 'id' ) then
			for i, row in self:rows() do
				local id = row[ 'id' ]
				if id then
					map[ id ] = row
				end
			end
		end
	end
	return map
end

function DataSheetListAccessor:getKey( idx )
	local keys = self._meta[ 'keys' ]
	return keys[ idx ]
end

function DataSheetListAccessor:getRow( idx )
	return self._data[ idx ]
end

function DataSheetListAccessor:getRowById( id )
	local map = self:_affirmIdMap()
	return map[ id ]
end

function DataSheetListAccessor:getByIndex( idx, key, default )
	local row = self:getRow( idx )
	local v = row and row[ key ]
	if v == nil then return default end
	return v
end


function DataSheetListAccessor:getById( id, key, default )
	local row = self:getRowById( id )
	local v = row and row[ key ]
	if v == nil then return default end
	return v
end

function DataSheetListAccessor:getByIndexTranslated( idx, key, default )
	local v = self:getByIndex( idx, key, default )
	if not v then return v end
	return self:translate( v )
end

function DataSheetListAccessor:getByIdTranslated( id, key, default )
	local v = self:getById( id, key, default )
	if not v then return v end
	return self:translate( v )
end

function DataSheetListAccessor:findRow( key, value )
	for i, row in self:rows() do
		local v = row[ key ]
		if v~=nil and v == value then
			return row
		end
	end
	return nil
end

function DataSheetListAccessor:rows()
	return ipairs( self._data )
end


--------------------------------------------------------------------
local function XLSDataLoader( node )
	local path = node:getObjectFile( 'data' )
	local metaPath = node:getObjectFile( 'meta_data' )
	local data = loadJSONFile( path, true )
	if metaPath then
		local metaData = loadJSONFile( metaPath, true )
		node.cached.meta = metaData
	end
	return data
end

local function DataSheetLoader( node )
	local data, pnode = loadAsset( node.parent )
	local meta = pnode.cached.meta
	local name = node:getName()
	local sheetData = data[ name ]
	local sheetMetaData = meta and meta[ name ] or {}
	local t = sheetMetaData[ 'type' ] or 'raw'
	if t == 'list' then
		local acc = DataSheetListAccessor( sheetData, sheetMetaData, node:getPath() )
		return acc
	elseif t == 'dict' then
		local acc = DataSheetDictAccessor( sheetData, sheetMetaData, node:getPath() )
		return acc
	else
		_warn( 'deprecated data sheet type')
		return sheetData
	end
end

registerAssetLoader( 'data_xls',    XLSDataLoader )
registerAssetLoader( 'data_sheet',  DataSheetLoader )
