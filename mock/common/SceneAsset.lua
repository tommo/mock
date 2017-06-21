module 'mock'



local tinsert  = table.insert
local tremove  = table.remove
local tsort    = table.sort

local isInstance = isInstance

_SERIALIZER_VERSION = '2'
_SCENE_INDEX_NAME = 'scene_index.json'
_SCENE_GROUP_EXTENSION = '.scene_group'

registerGlobalSignals{
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
	local p0 = a._priority
	local p1 = b._priority
	if p0 == p1 then
		return a.__guid < b.__guid
	end
	return p0 < p1
end

local function componentSortFunc( a, b )
	return ( a._componentID or 0 ) < ( b._componentID or 0 )
end

local function idSortFunc( a, b )
	return ( a.id or '') < ( b.id or '' )
end


local function guidSortFunc( a, b )
	return ( a.__guid or '') < ( b.__guid or '' )
end

local makeId   = makeNameSpacedId

---------------------------------------------------------------------
---------------------------------------------------------------------
CLASS: SceneSerializer ()

local function collectOverrideObjectData( objMap, obj, collected, collectedExtra )
	local fields = obj.__overrided_fields
	local body = {}
	local id = obj.__guid
	local fieldList = {}
	if fields and next( fields ) then
		for k in pairs( fields ) do
			tinsert( fieldList, k )
		end
	end

	local partialData = _serializeObject( obj, objMap, true, fieldList )
	local body = partialData['body']
	if fields and next( fields ) then
		for i, k in ipairs( fieldList ) do
			if body[k] == nil then body[k] = false end --null reference
		end
		collected[ id ] = partialData['body']
	end
	local extraData = partialData['extra']
	if extraData ~= nil then
		collectedExtra[ id ] = extraData
	end
end

local function collectOverrideEntityData( objMap, entity, collected, collectedExtra )
	collectOverrideObjectData( objMap, entity, collected, collectedExtra )
	if entity.components then
		for MOAIFMODStudioMgr, com in ipairs( entity:getSortedComponentList() ) do
			collectOverrideObjectData( objMap, com, collected, collectedExtra )
		end
	end
	if entity.children then
		for child in pairs( entity.children ) do
			--proto instance data will get collected in another process
			if not child.PROTO_INSTANCE_STATE then 
				collectOverrideEntityData( objMap, child, collected, collectedExtra )
			end
		end
	end
end

function SceneSerializer:_collecteProtoEntity( entity, objMap, protoEntry, namespace, modification, protoInfo )
	
	local deleted   = modification.deleted
	local added     = modification.added

	local newComponents = {}
	local newChildren   = {}
	--find component variation
	local comIds = {}
	for i, comEntry in ipairs( protoEntry.components ) do
		local id  = comEntry
		comIds[ makeId( id, namespace ) ] = { false, comEntry }
	end
	for i, com in ipairs( entity:getSortedComponentList() ) do
		if not com.FLAG_INTERNAL then
			local guid = objMap:map( com )
			local c = comIds[ guid ]
			if c == nil then --new component
				tinsert( newComponents, guid )
			else
				c[ 1 ] = true
				objMap:makeInternal( com )
			end
		end
	end

	--find children modification
	local childrenIds = {}
	for i, childEntry in ipairs( protoEntry.children ) do
		local id = childEntry.id
		local newId = makeId( id, namespace )
		childrenIds[ newId ] = { false, childEntry }
	end

	local childrenList = {}
	for e in pairs( entity.children ) do
		tinsert( childrenList, e )
	end
	
	tsort( childrenList, entitySortFunc )
	
	for i, child in ipairs( childrenList ) do
		if not ( child.FLAG_INTERNAL or child.FLAG_EDITOR_OBJECT ) then
			local guid = objMap:map( child )
			local c = childrenIds[ guid ]
			if c == nil then
				--new object
				local data = self:collectEntityWithProto( child, objMap, protoInfo )
				if data then tinsert( newChildren, data ) end
			else
				--sub object
				c[1] = true
				local childEntry = c[2]
				objMap:makeInternal( child )
				self:_collecteProtoEntity( child, objMap, childEntry, namespace, modification, protoInfo )
			end
		end
	end

	--deleted
	for id, result in pairs( comIds ) do
		if not result[1] then
			tinsert( deleted, id )
		end
	end

	for id, result in pairs( childrenIds ) do
		if not result[1] then			
			tinsert( deleted, id )
		end
	end

	--new
	local localAdded = {}
	if next( newChildren ) then
		localAdded.children = newChildren
	end
	if next( newComponents ) then
		localAdded.components = newComponents
	end
	if next( localAdded ) then
		added[ entity.__guid ] = localAdded
	end
end

function SceneSerializer:collectEntityWithProto( entity, objMap, protoInfo )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end
	--proto instance
	local protoState = entity.PROTO_INSTANCE_STATE
	if protoState then
		local id = objMap:map( entity )

		local protoPath = protoState.proto
		local proto     = loadAsset( protoPath )
		local protoData = proto:getData()

		-- local deleted = {}
		local localModification = {
			deleted   = {},
			added     = {}
		}
		protoInfo[ id ] = {
			id    = id,
			obj   = entity,
			proto = protoPath,
			modification = localModification
		}
		local protoEntry = protoData[ 'entities' ][1]
		local namespace = entity.__guid
		self:_collecteProtoEntity( entity, objMap, protoEntry, namespace, localModification, protoInfo )

		return {
			id = id,
			components = {},
			children   = {}
		}
	end

	--normal entity
	local components = {}
	local children = {}

	for i, com in ipairs( entity:getSortedComponentList() ) do
		if not com.FLAG_INTERNAL then
			tinsert( components, objMap:map( com ) )
		end
	end

	local childrenList = {}
	local i = 1
	for e in pairs( entity.children ) do
		childrenList[i] = e
		i = i + 1
	end
	
	tsort( childrenList, entitySortFunc )
	
	for i, child in ipairs( childrenList ) do
		local childData = self:collectEntityWithProto( child, objMap, protoInfo )
		if childData then
			tinsert( children, childData )
		end
	end

	return {
		id = objMap:map( entity ),
		components = components,
		children   = children
	}
end

function SceneSerializer:collectEntity( entity, objMap )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end

	local components = {}
	local children = {}

	for i, com in ipairs( entity:getSortedComponentList() ) do
		if not com.FLAG_INTERNAL then
			tinsert( components, objMap:map( com ) )
		end
	end

	local childrenList = {}
	local i = 1
	for e in pairs( entity.children ) do
		childrenList[i] = e
		i = i + 1
	end
	
	tsort( childrenList, entitySortFunc )
	
	for i, child in ipairs( childrenList ) do
		local childData = self:collectEntity( child, objMap, keepProto )
		if childData then
			tinsert( children, childData )
		end
	end

	return {
		id = objMap:map( entity ),
		-- name = entity:getName(),
		components = components,
		children   = children
	}
end


local function collectGroup( group, entityList, objMap )
	local childGroupDatas = {}
	local entityIds = {}
	
	for childGroup in pairs( group.childGroups) do
		local childGroupData = collectGroup( childGroup, entityList, objMap )
		tinsert( childGroupDatas, childGroupData )
	end

	for e in pairs( group.entities ) do
		if not ( e.FLAG_INTERNAL or e.FLAG_EDITOR_OBJECT ) then
			tinsert( entityIds, objMap:map( e ) )
			tinsert( entityList, e )
		end
	end

	tsort( childGroupDatas, idSortFunc )
	tsort( entityIds )
	return {
		id       = objMap:map( group ),
		children = childGroupDatas,
		entities = entityIds,
		root     = group._isRoot
	}
end

function SceneSerializer:preSerializeScene( scene, data, keepProto )
end

function SceneSerializer:postSerializeScene( scene, data, objMap, keepProto )	
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

function SceneSerializer:_flushObjectMap( objMap )
	local map = {}
	--first pass
	local newObjects = objMap:flush()
	for obj, id in pairs( newObjects ) do
		map[ id ] = _serializeObject( obj, objMap )			
	end
	--dep member pass
	while true do
		local newObjects = objMap:flush()
		if not next( newObjects ) then break end
		for obj, id in pairs( newObjects ) do
			if id:startwith( '!' ) then --guid
				map[ id ] = _serializeObject( obj, objMap )
			end
		end
	end
	return map
end

function SceneSerializer:serializeEntities( entityList, output, objMap, keepProto )
	output = output or {}
	objMap = objMap or SerializeObjectMap()

	local entityDatas = {}
	local map = {}

	if keepProto then --proto support
		--collect entity	
		local protoInfo = {}
		for i, e in ipairs( entityList ) do
			local data = self:collectEntityWithProto( e, objMap, protoInfo )
			if data then tinsert( entityDatas, data ) end
		end

		--data
		map = self:_flushObjectMap( objMap )

		--proto structure altering
		for id, info in pairs( protoInfo ) do
			local objData = {
				["__PROTO"] = info.proto,
			}
			local modification = info.modification
			if next( modification.deleted) then
				objData['deleted']  = modification.deleted
			end
			if next( modification.added ) then
				objData['added']  = modification.added
			end
			map[ id ] = objData
		end

		--find overrided fields
		for id, info in pairs( protoInfo ) do
			local obj = info.obj
			local overridedData = {}
			local extraData = {}
			collectOverrideEntityData( objMap, obj, overridedData, extraData )
			local objData = map[id]
			if next(overridedData) then
				objData[ 'overrided' ] = overridedData
			end
			if next( extraData ) then
				objData[ 'extra' ] = extraData
			end
		end


	else --without proto support 
		--collect entity	
		for i, e in ipairs( entityList ) do
			local data = self:collectEntity( e, objMap )
			if data then tinsert( entityDatas, data ) end
		end

		--build data
		map = self:_flushObjectMap( objMap )

	end
	
	--guid
	local guidMap = {}
	local internalObjects = objMap.internalObjects
	for obj, id in pairs( objMap.objects ) do
		if not internalObjects[ obj ] then
			local guid = obj.__guid
			if guid then
				guidMap[ id ] = guid
			end
		end
	end

	output.map         = map
	output.entities    = entityDatas
	output.guid        = guidMap

	return output, objMap
end

function SceneSerializer:serializeSingleEntity( entity, keepProto )
	local output, objMap = self:serializeEntities( {entity}, nil, nil, keepProto )	
	output['__VERSION'] = _SERIALIZER_VERSION
	return output, objMap
end

function SceneSerializer:serializeScene( scene, keepProto )
	local output = {}
	local indexData = { _assetType = 'scene' }
	--pre
	emitSignal( 'scene.pre_serialize', scene )
	self:preSerializeScene( scene, indexData, keepProto )

	--groups
	local rootGroupDataList = {}
	for i, group in ipairs( scene:getRootGroups() ) do
		local groupData, objMap = self:serializeRootGroup( group, keepProto )
		local name = group.name
		rootGroupDataList[ name ] = groupData
	end
	
	--post
	emitSignal( 'scene.post_serialize', scene )
	self:postSerializeScene( scene, indexData, keepProto )

	indexData['config'] = scene:serializeConfig()
	indexData['__VERSION'] = _SERIALIZER_VERSION

	output['index'] = indexData
	output['roots'] = rootGroupDataList
	output['scene_type'] = 'multiple'
	return output
end

function SceneSerializer:serializeRootGroup( rootGroup, keepProto )
	local output = {}
	local objMap = SerializeObjectMap()
	local layers = game:getLayers()
	for i, layer in ipairs( layers ) do
		objMap:map( layer.name )
	end
	output['name']   = rootGroup.name
	output['default'] = rootGroup._isDefault or false

	local entityList = {}
	output[ 'groups' ] = {
		collectGroup( rootGroup, entityList, objMap )
	}
	tsort( entityList, entitySortFunc )
	self:serializeEntities( entityList, output, objMap, keepProto )

	--prefab
	local prefabIdMap = {}
	for obj, id in pairs( objMap.objects ) do
		local prefabId = obj.__prefabId
		if prefabId then
			prefabIdMap[ id ] = prefabId
		end
	end
	output['prefabId'] = prefabIdMap
	
	--proto
	if keepProto then
		local protos = {}
		for obj, id in pairs( objMap.objects ) do
			if obj.FLAG_PROTO_SOURCE then
				local info = self:_serializeProto( obj, id )
				tinsert( protos, info )
			end
		end
		tsort( protos, idSortFunc )
		output['protos'] = protos
	end

	output[ 'asset_dependency' ] = collectGroupAssetDependency( rootGroup )

	return output, objMap
end


local function affirmPath( path )
	MOAIFileSystem.affirmPath( path )
	if MOAIFileSystem.checkPathExists( path ) then
		return true
	end
	return false
end

local function writeJSON( data, path )
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

function SceneSerializer:serializeSceneToFile( scene, path, keepProto )
	local data = self:serializeScene( scene, keepProto )
	if not data then return false end

	if MOAIFileSystem.checkFileExists( path ) then
		--remove file
		_stat( 'overwrite legacy scene file', path )
		MOAIFileSystem.deleteFile( path )
	end

	if not affirmPath( path ) then
		_error( 'can not create folder for saving scene', path )
		return false
	end

	--clear files
	local files = MOAIFileSystem.listFiles( path )
	for i, filename in ipairs( files ) do
		if filename:endwith( _SCENE_GROUP_EXTENSION ) then
			MOAIFileSystem.deleteFile( path .. '/' .. filename )
		end
	end

	local indexData = data[ 'index' ]
	local indexDataPath = path .. '/' .. _SCENE_INDEX_NAME
	if not writeJSON( indexData, indexDataPath ) then
		return false
	end

	--index
	local groupListData = data[ 'roots' ]
	for id, groupData in pairs( groupListData ) do
		local fileName = id .. _SCENE_GROUP_EXTENSION
		local groupDataPath = path .. '/' .. fileName
		if not writeJSON( groupData, groupDataPath ) then
			return false
		end
	end

	return true

	--####legacy
	-- local data = self:serializeScene( scene, keepProto )
	-- local str  = encodeJSON( data )
	-- local file = io.open( path, 'wb' )
	-- if file then
	-- 	file:write( str )
	-- 	file:close()
	-- else
	-- 	_error( 'can not write to scene file', path )
	-- 	return false
	-- end
	-- return true
end

--------------------------------------------------------------------
---------------------------------------------------------------------
CLASS: SceneDeserializer ()

function SceneDeserializer:__init()
	self.currentRootGroup = false
	self.allowConditional = false
end

function SceneDeserializer:setAllowConditional( allow )
	self.allowConditional = allow ~= false
end

function SceneDeserializer:insertEntity( scene, parent, edata, objMap )
	local id = edata['id']
	local components = edata['components']
	local children   = edata['children']
	local entity     = objMap[ id ][ 1 ]
	
	assert( entity, 'entity invalid:'..id )
	
	if self.allowConditional then
		local accept = entity.__accept
		if accept then
			if accept( entity ) == false then
				return false
			end
		end
	end

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

function SceneDeserializer:deserializeGroup( scene, parentGroup, data, objMap )
	local root = data['root']
	local id   = data[ 'id' ]
	local group

	if root then
		group = self.currentRootGroup	
	else
		group = objMap[ id ][ 1 ]
		parentGroup:addChildGroup( group )
	end
	
	if not id:startwith( '!' ) then
		group.__guid = id
	end
	
	for _, entId in ipairs( data[ 'entities' ] ) do
		ent = objMap[ entId ][ 1 ]
		ent._entityGroup = group
	end
	
	for _, childData in ipairs( data[ 'children' ] or {} ) do		
		self:deserializeGroup( scene, group, childData, objMap )
	end

end

function SceneDeserializer:deserializeLegacyScene( data, scene )
	local objMap = {}
	
	if not scene then
		scene = Scene()
		scene:init()
	end

	emitSignal( 'scene.pre_deserialize', scene, data, objMap )
	self:preDeserializeScene( scene, data, objMap )

	self:deserializeEntities( data, objMap, scene )
	
	self:postDeserializeScene( scene, data, objMap )
	emitSignal( 'scene.post_deserialize', scene, data, objMap )

	local configData = data['config'] or {}
	scene:deserializeConfig( configData )
	return scene
end

function SceneDeserializer:deserializeMultipleScene( data, scene )
	if not scene then
		scene = Scene()
		scene:init()
	end

	local indexData = data[ 'index' ]
	local refObjMap = {}

	emitSignal( 'scene.pre_deserialize', scene, data, refObjMap )
	self:preDeserializeScene( scene, data, refObjMap )

	--roots
	local rootGroupDataList = data[ 'roots' ]

	--prepare objmap
	local globalMap = {}
	local indexMT = {
			__index = globalMap
		}
	local groups = {}

	for name, groupData in pairs( rootGroupDataList ) do
		local default = groupData[ 'default' ]

		local group = scene:getRootGroup( name )
		if not group then
			group = scene:addRootGroup( name )
			if default then group._isDefault = default end
		end

		if default then
			assert(
				group._isDefault, 
				'deserializing "default" group data into non default group: '.. group.name
			)
		end

		local objMap = self:_prepareEntitiesObjMap( groupData, nil )
		for k, obj in pairs( objMap ) do
			if not k:startwith( '!' ) then
				globalMap[ k ] = obj
			end
		end
		setmetatable( objMap, indexMT )
		groups[ name ] = { groupData, group, objMap }
	end


	for name, entry in pairs( groups ) do
		local groupData, group, objMap = unpack( entry )
		self.currentRootGroup = group
		self:_deserializeEntitiesData( groupData, objMap, scene )
		self.currentRootGroup = false
	end


	self:postDeserializeScene( scene, data, globalMap )
	emitSignal( 'scene.post_deserialize', scene, data, globalMap )

	local configData = indexData['config'] or {}
	scene:deserializeConfig( configData )

	return scene
end

function SceneDeserializer:deserializeScene( data, scene )
	local stype = data[ 'scene_type' ]
	if stype == 'single' then --legacy
		return self:deserializeLegacyScene( data, scene )
	elseif stype == 'multiple' then
		return self:deserializeMultipleScene( data, scene )
	else
		error( 'wtf?' )
	end
end

function SceneDeserializer:_prepareEntitiesObjMap( data, objMap )
	objMap = objMap or {}
	local map = data[ 'map' ]
	-- pre-load proto instance
	local protoMerged = data[ '__PROTO_MERGED' ] or false
	if not protoMerged then
		local protoInstances = {}
		for id, objData in pairs( map ) do
			if objData[ '__PROTO' ] then
				tinsert( protoInstances, id )
			end
		end
		mergeProtoDataList( data, protoInstances )
		data[ '__PROTO_MERGED' ] = true
	end
	_prepareObjectMap( map, objMap )
	return objMap
end

function SceneDeserializer:_deserializeEntitiesData( data, objMap, scene )
	local map = data[ 'map' ]
	_deserializeObjectMapData( objMap )
	for id, objData in pairs( map ) do
		local protoHistory = objData[ 'proto_history' ]
		if protoHistory then
			local entry = objMap[id]
			local obj = entry[1]
			obj.__proto_history = protoHistory
		end
		local protoPath = objData[ '__PROTO' ]
		if protoPath then
			local entry = objMap[id]
			local obj = entry[1]
			obj.PROTO_INSTANCE_STATE = {
				proto = protoPath
			}
			local overrideMap = objData[ 'overrided' ]
			if overrideMap then
				for id, overrided in pairs( overrideMap ) do
					local entry = objMap[ id ]
					if entry then
						local obj   = entry[1]
						local overrideMarks = {}
						for k in pairs( overrided ) do
							overrideMarks[ k ] = true
						end
						obj.__overrided_fields = overrideMarks
					else
						_warn( 'overrided object not found', id )
					end
				end
			end
		end

	end
	
	if data['guid'] then
		for id, guid in pairs( data['guid'] ) do
			local entry = objMap[ id ]
			local obj = entry and entry[1]
			if obj then
				obj.__guid = guid
			end
		end
	end

	--groups
	if scene then
		local groupDatas = data[ 'groups' ] or {}
		local rootGroup = self.currentRootGroup or scene:getRootGroup()
		for i, gdata in ipairs( groupDatas ) do
			self:deserializeGroup( scene, rootGroup, gdata, objMap )
		end
	end

	--insetEntity
	for i, edata in ipairs( data[ 'entities' ] ) do
		self:insertEntity( scene, nil, edata, objMap )
	end

	--deserialize proto/prefab linkage
	if data['prefabId'] then
		for id, prefabId in pairs( data['prefabId'] ) do
			local entry = objMap[ id ]
			if entry then 
				local obj = entry[ 1 ]
				obj.__prefabId = prefabId
			else
				_warn( 'prefab instance not found in objMap:' .. id )
			end
		end
	end

	if data['protos'] then
		for i, info in ipairs( data['protos'] ) do
			local id = info.id
			local entry = objMap[ id ]
			if entry then 
				local obj = entry[ 1 ]
				obj.FLAG_PROTO_SOURCE = true
				obj.PROTO_TIMESTAMP = info.timestamp
			else
				_warn( 'proto instance not found in objMap:' .. id )
			end
		end
	end
end

function SceneDeserializer:deserializeEntities( data, objMap, scene )
	local objMap = self:_prepareEntitiesObjMap( data, objMap )
	self:_deserializeEntitiesData( data, objMap, scene )
	return objMap
end

function SceneDeserializer:preDeserializeScene( scene, data, objMap )
end

function SceneDeserializer:postDeserializeScene( scene, data, objMap )
end

function SceneDeserializer:deserializeSingleEntity( data, option )
	local objMap = self:deserializeEntities( data, nil, nil )
	local rootId = data[ 'entities'] [1] ['id']
	local rootEntry = objMap[ rootId ]
	return rootEntry[ 1 ], objMap
end



--------------------------------------------------------------------
--API
--------------------------------------------------------------------
function serializeScene( scene, keepProto )
	return SceneSerializer():serializeScene( scene, keepProto )
end

function deserializeScene( data, scene, allowConditional )
	local deserializer = SceneDeserializer()
	if allowConditional then
		deserializer:setAllowConditional( true )
	end
	return deserializer:deserializeScene( data, scene )	
end

function serializeSceneToFile( scene, path, keepProto )
	return SceneSerializer():serializeSceneToFile( scene, path, keepProto )
end

--------------------------------------------------------------------
function makeEntityCopyData( ent )
	local data, objMap = serializeEntity( ent, 'keepProto' )
	local rootId = data['entities'][1]['id']
	local newGuids = {}
	local objects = objMap.objects
	for obj, id in pairs( objects ) do
		if type( obj ) == 'table' and obj.PROTO_INSTANCE_STATE then
			newGuids[ id ] = id
		end
	end
	data['guid'] = newGuids
	
	return {
		guid = newGuids,
		data = encodeJSON( data ),
		}
end

function makeEntityPasteData( copyData, idGenerator )
	local guids   = copyData['guid']
	local json   = copyData[ 'data' ]
	for guid in pairs( guids ) do
		local newId = idGenerator()
		json = json:gsub( guid, newId )
	end
	local entityData = decodeJSON( json )
	return entityData
end

function makeEntityCloneData( ent, idGenerator )
	local copyData = makeEntityCopyData( ent )
	return makeEntityPasteData( copyData, idGenerator )
end

function copyAndPasteEntity( ent, idGenerator )
	local pasteData = makeEntityCloneData( ent, idGenerator )
	local created = mock.deserializeEntity( pasteData )
	return created
end

function makeEntityGroupPasteData( copyData, idGenerator )
	
end

function makeComponentCopyData( com )
	--TODO
end

function makeComponentPasteData( copyData, idGenerator )
	--TODO
end


--------------------------------------------------------------------
function serializeEntity( ent, keepProto )
	local data, objMap = SceneSerializer():serializeSingleEntity( ent, keepProto )
	return data, objMap
end

function deserializeEntity( data )
	return SceneDeserializer():deserializeSingleEntity( data )
end


-------------------------------------------------------------------
--Loader
---------------------------------------------------------------------
local sceneGroupFilterEnabled = false
local sceneGroupFilterInclude = false
local sceneGroupFilterExclude = false

function setSceneGroupFilter( includes, excludes )
	sceneGroupFilterEnabled = true
	sceneGroupFilterInclude = includes
	sceneGroupFilterExclude = excludes
end

function matchSceneGroupFilter( name )
	if not sceneGroupFilterEnabled then return true end
	if sceneGroupFilterInclude then
		local matched = false
		for i, pattern in ipairs( sceneGroupFilterInclude ) do
			if string.match( name, pattern ) then matched = true break end
		end
		if not matched then return false end
	end
	if sceneGroupFilterExclude then
		for i, pattern in ipairs( sceneGroupFilterExclude ) do
			if string.match( name, pattern ) then return false end
		end
	end
	return true
end

function loadSceneDataFromPath( path, option )
	if path and MOAIFileSystem.checkPathExists( path ) then
		local indexDataPath = path .. '/' .. _SCENE_INDEX_NAME
		if not MOAIFileSystem.checkFileExists( indexDataPath ) then
			return error( 'scene index data not found:' .. tostring( indexDataPath ) )
		end
		local data = {}
		data[ 'scene_type' ] = 'multiple'

		local indexData = loadAssetDataTable( indexDataPath )
		local files = MOAIFileSystem.listFiles( path )
		local rootGroupDataList = {}
		local assetDependency = {}
		local ignoreGroupFilter = option.ignoreGroupFilter

		for i, filename in ipairs( files ) do
			if filename:endwith( _SCENE_GROUP_EXTENSION ) then
				local subName = basename_noext( filename )
				local accepted = true
				if not ignoreGroupFilter then
					accepted = matchSceneGroupFilter( subName )
				end
				if accepted then
					local subData = loadAssetDataTable( path .. '/' .. filename )
					rootGroupDataList[ subName ] = subData
					local dep = subData[ 'asset_dependency' ]
					if dep then
						for path, tag in pairs( dep ) do
							local tag0 = assetDependency[ tag ]
							local tag1
							if tag == 'preload' then
								tag1 = 'preload'
							elseif tag == 'dep' then
								tag1 = ( not tag0 ) and 'dep'
							end
							assetDependency[ path ] = tag1
						end
					end
				end
			end
		end
		data[ 'asset_dependency' ] = assetDependency
		data[ 'index' ] = indexData
		data[ 'roots' ] = rootGroupDataList
		return data

	elseif path and MOAIFileSystem.checkFileExists( path ) then
		local data = loadAssetDataTable( path )
		data[ 'scene_type' ] = 'single'
		return data

	else
		return error( 'no file found:' .. tostring( path ) )

	end

end


local function sceneLoader( node, option )
	local data = node.cached.data
	if not data then --load data
		data = loadSceneDataFromPath( node:getObjectFile( 'def' ), option )
		if not game.editorMode then --cache scene data
			node.cached.data = data
		end
	end
	
	option = option or {}
	local scene  = option.scene or Scene()
	local allowConditional = option.allowConditional
	local preloadDependency = option.preloadDependency ~= false
	--configuration
	scene:init()
	scene.path = node:getNodePath()

	_Stopwatch.start( 'scene_load_dependency' )
	if preloadDependency then
		--entities
		local dep = data['asset_dependency']
		if dep then
			for assetPath, tag in pairs( dep ) do
				if tag == 'preload' and canPreload( assetPath ) then
					mock.loadAsset( assetPath, { preload = true } )
				end
			end
		end
		
	end
	_Stopwatch.stop( 'scene_load_dependency' )
	
	_Stopwatch.start( 'scene_load_deserialization' )
	
		deserializeScene( data, scene, allowConditional )
	
	_Stopwatch.stop( 'scene_load_deserialization' )

	_log( 'loading scene:', node:getPath() )
	_log( _Stopwatch.report( 'scene_load_dependency', 'scene_load_deserialization' ) )

	return scene, false --no cache
end

local function sceneUnloader( node )
	
end


registerAssetLoader( 'scene', sceneLoader, sceneUnloader )
