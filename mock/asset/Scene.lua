module 'mock'

_SERIALIZER_VERSION = '2'

registerSignals{
	'scene.pre_serialize',
	'scene.pre_deserialize',
	'scene.post_serialize',
	'scene.post_deserialize',
}
--------------------------------------------------------------------
local function _printEntityId( ent, i )
	i = i or 0
	print( string.rep( '\t', i ) .. ent.__guid .. ':' .. ent:getName() )
	for com in pairs( ent.components ) do
		print( string.rep( '\t', i + 1 ) .. '>' .. com.__guid.. ':'..com:getClassName() )
	end

	for child in pairs( ent.children ) do
		_printEntityId( child, i + 1 )
	end
end

function printSceneId( scn )
	for ent in pairs( scn.entities) do
		_printEntityId( ent, 0 )
	end
end

printEntityId = _printEntityId

--------------------------------------------------------------------
local function entitySortFunc( a, b )
	return  a._priority < b._priority
end

local function componentSortFunc( a, b )
	return ( a._componentID or 0 ) < ( b._componentID or 0 )
end

local makeId     = makeNameSpacedId

---------------------------------------------------------------------
---------------------------------------------------------------------
CLASS: SceneSerializer ()

function SceneSerializer:getProtoData( entity, objMap )
	local id = objMap:map( entity )
	local data = {
		id = id,
		components = {},
		children = {},
		-- name = entity:getName(),
	}
	--don't scan component/children
	return data
end

function SceneSerializer:collectProtoEntity( entity, objMap, isRoot )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end

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
		local childData = self:collectEntity( child, objMap, keepProto )
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

function SceneSerializer:collectEntity( entity, objMap, keepProto )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end
	if keepProto and entity.PROTO_INSTANCE_STATE then 
		return self:collectProtoEntity( entity, objMap, true )		
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
		local childData = self:collectEntity( child, objMap, keepProto )
		if childData then
			table.insert( children, childData )
		end
	end

	return {
		id = objMap:map( entity ),
		-- name = entity:getName(),
		components = components,
		children   = children
	}
end

local function collectOverrideObjectData( objMap, obj, collected )
	local fields = obj.__overrided_fields
	if not ( fields and next( fields ) )  then return end
	local body = {}
	local id = obj.__guid
	local fieldList = {}
	for k in pairs( fields ) do
		table.insert( fieldList, k )
	end

	local partialData = _serializeObject( obj, objMap, true, fieldList )

	local data = {
		id   = id,
		body = partialData.body,
	}
	local body = partialData.body
	for i, k in ipairs( fieldList ) do
		if body[k] == nil then body[k] = false end --null reference
	end
	table.insert( collected, data )
end

local function collectOverrideEntityData( objMap, entity, collected )
	collectOverrideObjectData( objMap, entity, collected )
	if entity.components then
		for com in pairs( entity.components ) do
			collectOverrideObjectData( objMap, com, collected )
		end
	end
	if entity.children then
		for child in pairs( entity.children ) do
			collectOverrideEntityData( objMap, child, collected )
		end
	end
end

local function _collectDeletedSubEntityData( entity, protoEntry, deleted, namespace )
	local childrenIds = {}
	for child in pairs( entity.children ) do
		local guid = child.__guid
		if guid then
			childrenIds[ guid ] = child
		end
	end

	--find deleted entity
	for i, childEntry in ipairs( protoEntry.children ) do
		local id = childEntry.id
		local id2 = makeId( id, namespace )
		local child = childrenIds[ id2 ]
		if not child then
			table.insert( deleted, id2 )
		else
			_collectDeletedSubEntityData(  child, childEntry, deleted, namespace )
		end
	end

	--find new entity

	--find deleted components
	local comIds = {}
	for com in pairs( entity.components ) do
		local guid = com.__guid
		if guid then
			comIds[ guid ] = com
		end
	end
	for i, comEntry in ipairs( protoEntry.components ) do
		local id  = comEntry
		local id2 = makeId( id, namespace )
		if not comIds[ id2 ] then
			table.insert( deleted, id2 )
		end
	end
	--find new components
end

local function collectDeletedSubEntityData( objMap, entity, collected )
	local protoState = entity.PROTO_INSTANCE_STATE 
	local protoPath = protoState.proto
	local proto     = loadAsset( protoPath )
	local protoData = proto:getData()

	local namespace = entity.__guid

	-- local deleted = {}
	local deleted = collected
	local added   = {}
	local protoEntry = protoData.entities[1]

	_collectDeletedSubEntityData( entity, protoEntry, deleted, namespace )
	
end



function SceneSerializer:serializeScene( scene, keepProto )
	emitSignal( 'scene.pre_serialize', scene )
	--make proto data
	local output = { _assetType  = 'scene' }
	local objMap = SerializeObjectMap()
	self:preSerializeScene( scene, output, keepProto )
	
	local entityList = {}
	for e in pairs( scene.entities ) do
		if not e.parent then --1st level entity
			table.insert( entityList, e )
		end
	end
	table.sort( entityList, entitySortFunc )

	self:serializeEntities( entityList, output, objMap, scene, keepProto )

	output.meta  = scene.metaData or {}
	self:postSerialize( scene, output, objMap, keepProto )
	emitSignal( 'scene.post_serialize', scene, output, objMap, keepProto )
	output.__VERSION = _SERIALIZER_VERSION
	return output
end

function SceneSerializer:preSerializeScene( scene, data, keepProto )
end

function SceneSerializer:postSerialize( scene, data, objMap, keepProto )
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
	if keepProto then
		local protos = {}
		for obj, id in pairs( objMap.objects ) do
			if obj.FLAG_PROTO_SOURCE then
				local info = self:_serializeProto( obj, id )
				table.insert( protos, info )
			end			
		end
		data.protos = protos
	end
	
	--dependency
	data.asset_dependency = collectSceneAssetDependency( scene )
end

function SceneSerializer:_serializeProto( ent, id )
	local protoData = self:serializeSingleEntity( ent, 'keepProto' )
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


function SceneSerializer:serializeEntities( entityList, output, objMap, scene, keepProto )
	output = output or {}
	objMap = objMap or SerializeObjectMap()

	local entityDatas = {}
	local map = {}

	local protoInstances = {}

	--collect entity
	for i, e in ipairs( entityList ) do
		local data = self:collectEntity( e, objMap, keepProto )
		if data then table.insert( entityDatas, data ) end
	end

	--data
	if keepProto then --proto support
		while true do
			local newObjects = objMap:flush()
			if not next( newObjects ) then break end
			for obj, id in pairs( newObjects )  do
				local protoState = obj.PROTO_INSTANCE_STATE
				local protoPath = protoState.proto
				if protoPath then
					map[ id ] = { 
						["__PROTO"] = protoPath
					}
					protoInstances[ id ] = obj
				else
					map[ id ] = _serializeObject( obj, objMap )
				end
			end
		end

		--extract overrided data
		for id, obj in pairs( protoInstances ) do
			--find overrided fields
			local overridedData = {}
			collectOverrideEntityData( objMap, obj, overridedData )
			if next(overridedData) then
				local objData = map[id]
				objData[ 'override' ] = overridedData
			end
			--find removed sub object
			local deletedData = {}
			collectDeletedSubEntityData( objMap, obj, deletedData )
			if next( deletedData ) then
				local objData = map[id]
				objData[ 'delete' ] = deletedData
			end
			--find new added sub object
			-- collect
		end


	else --without proto support 
		while true do
			local newObjects = objMap:flush()
			if not next( newObjects ) then break end
			for obj, id in pairs( newObjects )  do
				map[ id ] = _serializeObject( obj, objMap )
			end
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


function SceneSerializer:serializeSingleEntity( entity, keepProto )
	local output, objMap = self:serializeEntities( {entity}, nil, nil, nil, keepProto )	
	output.__VERSION = _SERIALIZER_VERSION
	return output
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
	local entity     = objMap[ id ][ 1 ]
	
	assert( entity, 'entity invalid:'..id )
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

	self:postDeserializeScene( scene, data, objMap )
	emitSignal( 'scene.post_deserialize', scene, data, objMap )
	return scene
end

function SceneDeserializer:deserializeEntities( data, objMap, scene )
	local map = data.map
	objMap = objMap or {}
	
	-- pre-load proto instance
	local protoInstances = {}
	for id, objData in pairs( map ) do
		local protoPath = objData[ '__PROTO' ]
		if protoPath then
			protoInstances[ id ] = protoPath
		end
	end

	for id in pairs( protoInstances ) do
		mergeProtoData( data, id )
	end

	_deserializeObjectMap( map, objMap ) --ignore protoInstances
	
	for id, objData in pairs( map ) do
		local protoPath = objData[ '__PROTO' ]
		if protoPath then
			local entry = objMap[id]
			local obj = entry[1]
			obj.PROTO_INSTANCE_STATE = {
				proto = protoPath
			}
			local overrideList = objData[ 'override' ]
			if overrideList then
				for i, override in ipairs( overrideList ) do
					local id    = override['id']
					local entry = objMap[ id ]
					local obj   = entry[1]
					local overrideMarks = {}
					for k in pairs( override['body'] ) do
						overrideMarks[ k ] = true
					end
					obj.__overrided_fields = overrideMarks
				end
			end
		end
	end

	for i, edata in ipairs( data.entities ) do
		self:insertEntity( scene, nil, edata, objMap )
	end
	return objMap
end

function SceneDeserializer:preDeserializeScene( scene, data, objMap )
end

function SceneDeserializer:postDeserializeScene( scene, data, objMap )
	if data['guid'] then
		for id, guid in pairs( data['guid'] ) do
			local obj = objMap[ id ][ 1 ]
			if obj then
				obj.__guid = guid
			end
		end
	end

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

function SceneDeserializer:deserializeSingleEntity( data, option )
	local objMap = self:deserializeEntities( data, nil, nil )
	local rootId = data.entities[1]['id']
	local rootEntry = objMap[ rootId ]
	local skip_guid = option and option.skip_guid or false
	if (not skip_guid ) and data['guid'] then
		for id, guid in pairs( data['guid'] ) do
			local obj = objMap[ id ][ 1 ]
			obj.__guid = guid
		end
	end
	return rootEntry[ 1 ], objMap
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

function serializeScene( scene, keepProto )
	return _sceneSerializer:serializeScene( scene, keepProto )
end

function deserializeScene( data, scene )
	return _sceneDeserializer:deserializeScene( data, scene )	
end

function serializeSceneToFile( scene, path, keepProto )
	local data = serializeScene( scene, keepProto )
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
function serializeEntity( ent, keepProto )
	local data = _sceneSerializer:serializeSingleEntity( ent, keepProto )
	return data
end

function deserializeEntity( data, option )
	return _sceneDeserializer:deserializeSingleEntity( data, option )
end

--------------------------------------------------------------------
function loadSceneData( path )
	local node = getAssetNode( path )
	local data = node.cached.data
	if not data then
		local path = node:getObjectFile( 'def' )
		data = loadAssetDataTable( path )
		if not game.editorMode then --cache scene data
			node.cached.data = data
		end
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
