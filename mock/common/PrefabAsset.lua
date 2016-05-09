module 'mock'

--------------------------------------------------------------------
CLASS: Prefab ()

function Prefab:__init( data, id )
	self.data = data
	self.id = id
	self.rootId    = data.entities[1]['id']
	local rootData = data.map[ self.rootId ]
	self.rootName  = rootData['body']['name']
end

function Prefab:getRootName()
	return self.rootName
end

function Prefab:createInstance()
	local instance
	local data = self.data
	if not data.entities then
		_stat('loading empty prefab')
		instance = Entity()
	else
		instance = deserializeEntity( data )
	end
	instance.__prefabId = self.id or true
	return instance
end

--------------------------------------------------------------------
function createPrefabInstance( path )
	local prefab, node = loadAsset( path )
	if prefab and node:getType() == 'prefab' then
		return prefab:createInstance()
	else
		_warn( 'prefab not found:', path )
		return nil
	end
end

--------------------------------------------------------------------
function saveEntityToPrefab( entity, prefabFile )
	local data = serializeEntity( entity )
	data.guid = {}
	local str  = encodeJSON( data )
	local file = io.open( prefabFile, 'wb' )
	if file then
		file:write( str )
		file:close()
	else
		_error( 'can not write to scene file', prefabFile )
		return false
	end
	return true
end

--------------------------------------------------------------------
function PrefabLoader( node )
	local path = node:getObjectFile( 'def' )
	local data = loadAssetDataTable( path )

	return Prefab( data, node:getNodePath() )
end

registerAssetLoader( 'prefab',  PrefabLoader )
