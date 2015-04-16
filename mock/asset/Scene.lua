module 'mock'

_SERIALIZER_VERSION = '2'

registerSignals{
	'scene.pre_serialize',
	'scene.pre_deserialize',
	'scene.post_serialize',
	'scene.post_deserialize',
}

--------------------------------------------------------------------
local function entitySortFunc( a, b )
	return  a._priority < b._priority
end

local function componentSortFunc( a, b )
	return ( a._componentID or 0 ) < ( b._componentID or 0 )
end

---------------------------------------------------------------------
---------------------------------------------------------------------
CLASS: SceneSerializer ()

function SceneSerializer:getProtoData( entity, objMap )
	local id = objMap:map( entity )
	local data = {
		id = id,
		components = {},
		children = {},
	}
	--don't scan component/children
	return data
end


function SceneSerializer:collectEntity( entity, objMap )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end
	if entity.FLAG_PROTO_INSTANCE then		
		return self:getProtoData( entity, objMap )
	end

	local components = {}
	local children = {}

	for i, com in ipairs( entity:getSortedComponentList() ) do
		if not com.FLAG_INTERNAL then
			table.insert( components, objMap:map( com ) )
		end
	end

	local childrenList = {}
	local i = 1
	for e in pairs( entity.children ) do
		childrenList[i] = e
		i = i + 1
	end
	
	table.sort( childrenList, entitySortFunc )
	
	for i, child in ipairs( childrenList ) do
		local childData = self:collectEntity( child, objMap )
		if childData then
			table.insert( children, childData )
		end
	end

	return {
		id = objMap:map( entity ),
		components = components,
		children   = children
	}
end

function SceneSerializer:serializeObject( obj, objMap )
	if obj.FLAG_PROTO_INSTANCE then
		return { 
			__PROTO_INSTANCE_INFO = obj.FLAG_PROTO_INSTANCE
		}
	else
		return _serializeObject( obj, objMap )
	end
end

function SceneSerializer:serializeScene( scene )
	emitSignal( 'scene.pre_serialize', scene )
	--make proto data
	local output = { _assetType  = 'scene' }
	local objMap = SerializeObjectMap()
	self:preSerializeScene( scene, output )
	
	self:serializeEntities( scene.entities, output, objMap, scene )

	output.meta  = scene.metaData or {}
	self:postSerialize( scene, output, objMap )
	emitSignal( 'scene.post_serialize', scene, output, objMap )
	return output
end

function SceneSerializer:preSerializeScene( scene, data )
end

function SceneSerializer:postSerialize( scene, data, objMap )
	--prefab
	local prefabIdMap = {}
	for obj, id in pairs( objMap.objects ) do
		local prefabId = obj.__prefabId
		if prefabId then
			prefabIdMap[ id ] = prefabId
		end
	end
	data.prefabId    = prefabIdMap
	
	--proto
	local protos = {}
	for obj, id in pairs( objMap.objects ) do
		if obj.FLAG_PROTO_SOURCE then
			local info = self:_serializeProto( obj, id )
			table.insert( protos, info )
		end			
	end
	data.protos = protos
	
	--dependency
	data.asset_dependency = collectSceneAssetDependency( scene )
end

function SceneSerializer:_serializeProto( ent, id )
	local protoData = self:serializeSingleEntity( ent )
	local output    = MOAIDataBuffer.base64Encode(
		encodeJSON( protoData )
	)
	local info = {
		id         = id,
		name       = ent:getName(),
		timestamp  = ent.PROTO_TIMESTAMP or 0,
		serialized = output
	}
	return info
end

function SceneSerializer:serializeSingleEntity( entity )
	local entities = { [entity] = true }
	local output, objMap = self:serializeEntities( entities )	
	output.__VERSION = _SERIALIZER_VERSION
	return output
end

function SceneSerializer:serializeEntities( entities, output, objMap, scene )
	output = output or {}
	objMap = objMap or SerializeObjectMap()

	local entityDatas = {}
	local entityList = {}
	local map = {}

	for e in pairs( entities ) do
		if not e.parent then --1st level entity
			table.insert( entityList, e )
		end
	end

	objMap:flush()

	table.sort( entityList, entitySortFunc )

	for i, e in ipairs( entityList ) do
		local data = self:collectEntity( e, objMap )
		if data then table.insert( entityDatas, data ) end
	end

	while true do
		local newObjects = objMap:flush()
		if next( newObjects ) then
			for obj, id in pairs( newObjects )  do
				map[ id ] = self:serializeObject( obj, objMap )
			end
		else
			break
		end
	end

	--guid
	local guidMap = {}
	for obj, id in pairs( objMap.objects ) do
		local guid = obj.__guid
		if guid then
			guidMap[ id ] = guid
		end
	end

	output.map         = map
	output.entities    = entityDatas
	output.guid        = guidMap

	return output, objMap
end

--------------------------------------------------------------------
---------------------------------------------------------------------
CLASS: SceneDeserializer ()

function SceneDeserializer:__init()
end

function SceneDeserializer:insertEntity( scene, parent, edata, objMap )
	local id = edata['id']
	local components = edata['components']
	local children   = edata['children']
	local entity = objMap[ id ][ 1 ]
	

	if scene then
		scene:addEntity( entity )
	elseif parent then
		parent:addChild( entity )
	end

	if components then
		--components
		for _, comId in ipairs( components ) do
			local com = objMap[ comId ][ 1 ]
			entity:attach( com )
		end
	end
	
	if children then
		--chilcren
		for i, childData in ipairs( children ) do
			self:insertEntity( nil, entity, childData, objMap )
		end
	end

	return entity
end

function SceneDeserializer:deserializeScene( data, scene )
	local objMap = {}
	
	if not scene then
		scene = Scene()
		scene:init()
	end

	emitSignal( 'scene.pre_deserialize', scene, data, objMap )
	self:preDeserializeScene( scene, data, objMap )

	self:deserializeEntities( data, objMap, scene )

	scene.metaData = data['meta'] or {}

	if data['guid'] then
		for id, guid in pairs( data['guid'] ) do
			local obj = objMap[ id ][ 1 ]
			obj.__guid = guid
		end
	end

	self:postDeserializeScene( scene, data, objMap )
	emitSignal( 'scene.post_deserialize', scene, data, objMap )
	return scene
end

function SceneDeserializer:deserializeEntities( data, objMap, scene )
	local map = data.map
	objMap = objMap or {}
	local protoInstances = {}
	for id, objData in pairs( map ) do
		local protoInfo = objData[ '__PROTO_INSTANCE_INFO' ]
		if protoInfo then
			protoInstances[ id ] = true
			local instance = createProtoInstance( protoInfo )
			objMap[ id ] = {
				instance, objData
			}
		end
	end

	_deserializeObjectMap( map, objMap, protoInstances ) --ignore protoInstances

	for i, edata in ipairs( data.entities ) do
		self:insertEntity( scene, nil, edata, objMap )
	end

	return objMap
end

function SceneDeserializer:preDeserializeScene( scene, data, objMap )
end

function SceneDeserializer:postDeserializeScene( scene, data, objMap )
	if data['prefabId'] then
		for id, prefabId in pairs( data['prefabId'] ) do
			local obj = objMap[ id ][ 1 ]
			obj.__prefabId = prefabId
		end
	end

	if data['protos'] then
		for i, info in ipairs( data['protos'] ) do
			id = info.id
			local obj = objMap[ id ][ 1 ]
			obj.FLAG_PROTO_SOURCE = true
			obj.PROTO_TIMESTAMP = info.timestamp
		end
	end
end

function SceneDeserializer:deserializeSingleEntity( data )
	local objMap = self:deserializeEntities( data, nil, nil )
	local rootId = data.entities[1]['id']
	local rootEntry = objMap[ rootId ]
	return rootEntry[ 1 ]
end

--------------------------------------------------------------------
--API
--------------------------------------------------------------------
local _sceneSerializer = SceneSerializer()
local _sceneDeserializer = SceneDeserializer()

function setSceneSerializer( serializer, deserializer )
	_sceneSerializer = serializer or _sceneSerializer
	_sceneDeserializer = deserializer or _sceneDeserializer
end
--------------------------------------------------------------------

function serializeScene( scene )
	return _sceneSerializer:serializeScene( scene )
end

function deserializeScene( data, scene )
	return _sceneDeserializer:deserializeScene( data, scene )	
end

function serializeSceneToFile( scene, path )
	local data = serializeScene( scene )
	local str  = encodeJSON( data )
	local file = io.open( path, 'wb' )
	if file then
		file:write( str )
		file:close()
	else
		_error( 'can not write to scene file', path )
		return false
	end
	return true
end



--------------------------------------------------------------------
function serializeEntity( ent )
	return _sceneSerializer:serializeSingleEntity( ent )
end

function deserializeEntity( data )
	return _sceneDeserializer:deserializeSingleEntity( data )
end

--------------------------------------------------------------------
function loadSceneData( path )
	local node = getAssetNode( path )
	local data = node.cached.data
	if not data then
		local path = node:getObjectFile( 'def' )
		data = loadAssetDataTable( path )
		node.cached.data = data
	end
	return data
end


-------------------------------------------------------------------
--Loader
---------------------------------------------------------------------
local function sceneLoader( node, option )
	local data = loadSceneData( node:getNodePath() )
	local scene  = option.scene or Scene()
	--configuration
	scene:init()
	scene.path = node:getNodePath()
	--entities
	deserializeScene( data, scene )
	local dep = data['asset_dependency']
	if dep then
		for assetPath in pairs( dep ) do
			mock.loadAsset( assetPath )
		end
	end

	return scene, false --no cache
end

local function sceneUnloader( node )
	
end


registerAssetLoader( 'scene', sceneLoader, sceneUnloader )
