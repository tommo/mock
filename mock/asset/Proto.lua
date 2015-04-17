module 'mock'

local simplecopy = table.simplecopy
local makeId     = makeNameSpacedId
--------------------------------------------------------------------
CLASS: Proto ()
	:MODEL{}

function Proto:__init( id )
	self.id   = id
	self.source = false
	self.ready  = false
	self.loading = false
end

local function mergeTable( a, b )
	for k, v in pairs( b ) do
		a[k] = v
	end
end

local function _findEntityData( data, id )
	if data['id'] == id then return data end
	for i, childData in ipairs( data.children ) do
		local found = _findEntityData( childData, id )
		if found then return found end
	end
	return false
end

local function findEntityData( data, id )
	for i, entData in ipairs( data.entities ) do
		local found = _findEntityData( entData, id )
		if found then return found end
	end
	return false
end

local function mergeEntityEntry( entry, entry0, namespace )
	local components = entry.components
	for i, cid in ipairs( entry0.components ) do
		components[i] = makeId( cid, namespace )
	end
	local children = entry.children
	for i, childEntry in ipairs( entry0.children ) do
		local cid = childEntry.id
		local newChildEntry = {
			id = makeId( cid, namespace ),
			children = {},
			components = {}
		}
		children[i] = newChildEntry
		mergeEntityEntry( newChildEntry, childEntry, namespace )
	end
end

local function mergeObjectMap( map, map0, namespace )
	for id, data in pairs( map0 ) do
		local newid = makeId( id, namespace )
		local newData = simplecopy( data )
		newData.namespace = namespace
		map[ newid ]   = newData
	end
end

local function mergeGUIDMap( map, map0, namespace )
	for id, guid in pairs( map0 ) do
		local newid = makeId( id, namespace )
		map[ newid ]   = newid
	end
end

local function mergeProtoData( data, id )
	local objData   = data.map[ id ]
	local protoPath = objData[ '__PROTO' ]
	local p0 = loadAsset( protoPath )
	local data0 = p0.data

	mergeObjectMap( data.map,  data0.map, id  )
	mergeGUIDMap  ( data.guid, data0.guid, id )

	local entityEntry = findEntityData( data, id )
	if not entityEntry then
		table.print( data )
		error()
	end
	entityEntry0 = data0.entities[1]
	mergeEntityEntry( entityEntry, entityEntry0, id )
	local rootId = makeId( entityEntry0.id, id )
	objData['alias'] = rootId
	data.map[ rootId ]['__PROTO'] = protoPath
end


_M.mergeProtoData = mergeProtoData

function Proto:buildInstanceData( overridedData, guid )
	local rootId = guid or "__root__"
	return {
		entities = {
			{ id = rootId,
				children = {},
				components = {}
			}
		},
		map = {
			[rootId] = {
				__PROTO = self.id
			}
		},
		guid = {

		}
	}
	-- if not overridedData then return self.data end
	-- local data = self.data
	-- local newData = simplecopy( data )

	-- --only data.map needs process 		
	-- local newDataMap = simplecopy( data.map )
	-- newData.map = newDataMap
	-- for id, overridedBodyData in pairs( overridedData ) do
	-- 	local originalObjectData = newDataMap[id]
	-- 	if originalObjectData then
	-- 		local newObjectData = simplecopy( originalObjectData )
	-- 		local originalBody  = originalObjectData.body
	-- 		local newBody       = simplecopy( originalBody )
	-- 		newObjectData.body  = newBody
	-- 		newDataMap[ id ]    = newObjectData
	-- 		for k, v in pairs( overridedBodyData ) do
	-- 			newBody[ k ] = v
	-- 		end
	-- 	else
	-- 	--object removed, skip
	-- 	end
	-- end

	-- return newData
end

function Proto:getData()
	return self.data
end

function Proto:loadData( dataPath )
	if self.loading then
		error( 'cyclic proto reference' )
	end
	self.loading = true --cyclic ref avoiding
	
	local data     = loadAssetDataTable( dataPath )
	--expand all data
	local protoInstances = {}
	for id, objData in pairs( data.map )  do
		if objData[ '__PROTO' ] then
			protoInstances[id] = objData
		end
	end

	for id, objData in pairs( protoInstances ) do
		mergeProtoData( data, id )
	end

	self.data      = data
	self.ready     = true

	self.loading = false
end

function Proto:createInstance( overridedData, guid )
	local instanceData = self:buildInstanceData( overridedData, guid )
	local instance, objMap = deserializeEntity( instanceData )
	local objMapInstance = {}
	-- if instanceData['guid'] then
	-- 	for id, guid in pairs( instanceData['guid'] ) do
	-- 		local entry = objMap[ id ]
	-- 		local obj = entry[ 1 ]
	-- 		obj.__proto_guid = guid
	-- 		objMapInstance[ guid ] = entry
	-- 	end
	-- end

	instance.FLAG_PROTO_INSTANCE = self.id
	if not overridedData then
		local protoName = instance:getName()
		instance:setName( protoName..'_Instance' )
	end

	return instance, objMapInstance
end

function Proto:setSource( src )
	self.source = src
end

--------------------------------------------------------------------
CLASS: ProtoManager ()
	:MODEL{}

function ProtoManager:__init()
	self.protoMap = {}
end

function ProtoManager:getProto( node )
	local nodePath = node:getNodePath()
	local proto = self.protoMap[ nodePath ]
	if not proto then 
		proto = Proto( nodePath )
		self.protoMap[ nodePath ] = proto
	end
	if not proto.ready then
		proto:loadData( node:getObjectFile( 'def' ) )
	end
	return proto
end

function ProtoManager:removeProto( node )
	local nodePath = node:getNodePath()
	local proto = self.protoMap[ nodePath ]
	if proto then
		proto.ready = false
	end
end

protoManager = ProtoManager()

function createProtoInstance( path, overridedData, guid )
	local proto, node = loadAsset( path )
	if proto then
		return proto:createInstance( overridedData, guid )
	else
		_warn( 'proto not found:', path )
		return nil
	end
end

--------------------------------------------------------------------
local function ProtoLoader( node )
	return protoManager:getProto( node )
end

local function ProtoUnloader( node )
	protoManager:removeProto( node )
end

registerAssetLoader( 'proto',  ProtoLoader, ProtoUnloader, { skip_parent = true } )

