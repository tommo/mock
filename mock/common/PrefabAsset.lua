module 'mock'

--------------------------------------------------------------------
CLASS: Prefab ()

function Prefab:__init( data, id )
	self.data = data
	self.id = id

	local rootEntry = data.entities[ 1 ]
	if rootEntry then 
		self.rootId    = rootEntry['id']
		local rootData = data.map[ self.rootId ]
		self.rootName  = rootData['body']['name']
	end
end

function Prefab:getRootName()
	return self.rootName
end

function Prefab:createInstance()
	local instance
	local data = self.data
	if not ( data and next( data.entities ) ) then
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
	local _internal = entity.FLAG_INTERNAL
	local _editorObject = entity.FLAG_EDITOR_OBJECT
	entity.FLAG_INTERNAL = nil
	entity.FLAG_EDITOR_OBJECT = nil
	local data = serializeEntity( entity )
	entity.FLAG_INTERNAL = _internal 
	entity.FLAG_EDITOR_OBJECT = _editorObject 
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
	if not data then return false end
	if not data.entities then return false end
	return Prefab( data, node:getNodePath() )
end

registerAssetLoader( 'prefab',  PrefabLoader )
