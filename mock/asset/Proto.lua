module 'mock'

local simplecopy = table.simplecopy
local makeId     = makeNameSpacedId
--------------------------------------------------------------------
--Instance helper
--------------------------------------------------------------------

function findTopEntityProtoInstance( ent )
	local protoInstance = nil
	while ent do
		if ent.PROTO_INSTANCE_STATE then protoInstance = ent  end
		ent = ent.parent
	end
	return protoInstance
end

function findEntityProtoInstance( ent )
	while ent do
		if ent.PROTO_INSTANCE_STATE then return ent end
		ent = ent.parent
	end
	return nil
end

function findProtoInstance( obj )
	if isInstance( obj, Entity ) then
		return findEntityProtoInstance( obj )
	end
	if obj._entity then
		return findEntityProtoInstance( obj._entity )
	end
	return nil
end

function findTopProtoInstance( obj )
	if isInstance( obj, Entity ) then
		return findTopEntityProtoInstance( obj )
	end
	if obj._entity then
		return findTopEntityProtoInstance( obj._entity )
	end
	return nil
end

function markProtoInstanceOverrided( obj, fid )
	local protoInstance = findProtoInstance( obj )
	if not protoInstance then return false end

	local overridedFields = obj.__overrided_fields
	if not overridedFields then
		overridedFields = {}
		obj.__overrided_fields = overridedFields
	end

	if not overridedFields[ fid ] then
		overridedFields[ fid ] = true
		return true
	end

	return false
end

function isProtoInstanceOverrided( obj, fid )
	local protoInstance = findProtoInstance( obj )
	if not protoInstance then return false end
	overrided = overrided ~= false
	local overridedFields = obj.__overrided_fields
	return overridedFields and overridedFields[ fid ] and true or false
end


function resetProtoInstanceOverridedField( obj, fid )
	local protoInstance = findTopProtoInstance( obj )
	if not protoInstance then return false end

	local overridedFields = obj.__overrided_fields
	if not overridedFields then return false end
	if not overridedFields[ fid ] then return false end

	local protoState = protoInstance.PROTO_INSTANCE_STATE
	local protoPath  = protoState.proto
	local proto = mock.loadAsset( protoPath )
	proto:resetInstanceField( protoInstance, obj, fid )
	
	return true
end

function clearProtoInstanceOverrideState( obj )
	obj.__overrided_fields = nil
end


--------------------------------------------------------------------
--Proto
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

local function mergeEntityEntry( entry, entry0, namespace, deleted )
	local components = entry.components
	for i, cid in ipairs( entry0.components ) do
		local newId = makeId( cid, namespace )
		if not( deleted and deleted[ newId ] ) then
			table.insert( components, newId )
		end
	end
	local children = entry.children
	for i, childEntry in ipairs( entry0.children ) do
		local cid = childEntry.id
		local newId = makeId( cid, namespace )
		if not( deleted and deleted[ newId ] ) then
			local newChildEntry = {
				id = newId,
				children = {},
				components = {}
			}
			table.insert( children, newChildEntry )
			mergeEntityEntry( newChildEntry, childEntry, namespace, deleted )
		end
	end
end

local function mergeObjectMap( map, map0, namespace )
	for id, data in pairs( map0 ) do
		local newid = makeId( id, namespace )
		local newData = simplecopy( data )
		newData.namespace = namespace
		map[ newid ]   = newData
		if newData.__PROTO then
			newData['override'] = nil
			newData['delete']   = nil
			newData['insert']   = nil
		end
	end
end

local function mergeGUIDMap( map, map0, namespace )
	for id, guid in pairs( map0 ) do
		local newid = makeId( id, namespace )
		map[ newid ]   = newid
	end
end

local function getActualData( dataMap, id, namespace )
	local data = dataMap[ id ]
	local alias
	while data do
		alias = data[ 'alias' ]
		if alias then
			data = dataMap[ makeId( alias, namespace ) ]
		else
			return data
		end
	end
	error( 'invalid alias:'..alias )
end

local function mergeProtoData( data, id )
	local objData   = data.map[ id ]
	local protoPath = objData[ '__PROTO' ]
	local p0 = loadAsset( protoPath )
	local data0 = p0.data

	local overrideList = objData['override']
	local deleteList   = objData['delete']
	
	local deleteSet = false
	if deleteList then
		deleteSet = {}
		for i, id in ipairs( deleteList ) do
			deleteSet[ id ] = true
		end
	end
	local entityEntry = findEntityData( data, id )	
	
	entityEntry0 = data0.entities[1]
	local rootId = makeId( entityEntry0.id, id )

	mergeEntityEntry( entityEntry, entityEntry0, id, deleteSet )
	
	mergeObjectMap( data.map,  data0.map, id  )
	mergeGUIDMap  ( data.guid, data0.guid, id )
	data.guid[ rootId ] = id

	local map = data.map
	map[ id ] = map[ rootId ]
	map[ id ]['__PROTO']  = protoPath
	map[ id ]['override'] = overrideList
	map[ id ]['delete']   = deleteList
	-- map[ id ]['insert']   = deleteList
	map[ rootId ] = { alias = id }

	--overrid
	local namespace = id
	if overrideList then
		for i, override in pairs( overrideList ) do
			local id       = override[ 'id' ]
			local overBody = override[ 'body' ]
			if overBody then
				local oldData = getActualData( map, id, namespace )

				local oldBody = oldData.body
				if not oldBody then
					table.print( map[id] )
				end
				local newBody = simplecopy( oldBody )
				for k, v in pairs( overBody ) do
					newBody[ k ] = v
				end
				map[id].body = newBody				
			end
		end
	end

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
	instance.PROTO_INSTANCE_STATE ={
		proto = self.id
	}
	return instance
end

function Proto:setSource( src )
	self.source = src
end


local function _collectEntity( ent, objMap )
	local guid = ent.__guid
	if not guid then return end
	objMap[ guid ] = { ent, false }
	for child in pairs( ent.children ) do
		_collectEntity( child, objMap )
	end
	for com in pairs( ent.components ) do
		local guid = com.__guid
		if guid then
			objMap[ guid ] = { com, false }
		end
	end
end

function Proto:resetInstanceField( instance, subObject, fieldId )
	local protoData = self:getData()
	local namespace = instance.__guid
	
	local objMap = {}
	local objAliases = {}

	--fill the raw object in objMap first
	for id, objData in pairs( protoData.map ) do
		local modelName = objData.model
		if not modelName then --alias/raw
			local alias = objData['alias']
			if alias then
				local ns0 = objData['namespace']
				if ns0 then alias = makeId( alias, ns0 ) end
				objAliases[ id ] = alias
			else
				objMap[ id ] = { objData.body, objData }
			end
		end
	end

	--collect objects
	_collectEntity( instance, objMap )

	for id, alias in pairs( objAliases ) do
		local origin = objMap[ makeId( alias, namespace ) ]
		if origin then
			objMap[ id ] = origin
		else
			_warn( 'alias not found', id, alias )
		end
	end

	--find model&field
	local subId
	if subObject == instance then --root object
		subId = protoData[ 'entities' ][1]['id']
		print( 'root', subId )
	else
		--strip namespace?
		subId = subObject.__guid
		local idx = subId:find( namespace )
		subId = subId:sub( 1, idx - 2 )
	end

	local subData = protoData.map[ subId ].body
	local model = Model.fromObject( subObject )
	local field = model:getField( fieldId, true )
	if field then
		_deserializeField( subObject, field, subData, objMap, namespace )
	end
	--remove mark
	subObject.__overrided_fields[ fieldId ] = nil
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

