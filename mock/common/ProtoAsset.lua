module 'mock'

local simplecopy    = table.simplecopy
local makeId        = makeNameSpacedId
local makeNamespace = makeNameSpace

local modelFromName = Model.fromName
local isTupleValue  = isTupleValue
local isAtomicValue = isAtomicValue

local tinsert = table.insert

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

function markProtoInstanceOverrided( obj, fid, overrided )	
	if not obj.__proto_history then return false end
	local overridedFields = obj.__overrided_fields
	if not overridedFields then
		overridedFields = {}
		obj.__overrided_fields = overridedFields
	end

	if not overridedFields[ fid ] then
		if overrided == false then
			overridedFields[ fid ] = nil
		else
			overridedFields[ fid ] = true
		end
		obj.PROTO_TIMESTAMP = os.time()
		return true
	end

	return false
end



function markProtoInstanceFieldsOverrided( obj, fid, ... )
	for i, f in ipairs{ fid, ... } do
		markProtoInstanceOverrided( obj, f )
	end
end

function isProtoInstanceOverrided( obj, fid )
	local protoInstance = findProtoInstance( obj )
	if not protoInstance then return false end
	local overridedFields = obj.__overrided_fields
	return overridedFields and overridedFields[ fid ] and true or false
end

function resetProtoInstanceOverridedField( obj, fid )
	local protoInstance = findProtoInstance( obj )
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
	self.id       = id
	self.ready    = false
	self.loading  = false
	self.rootName = false
end

function Proto:getRootName()
	return self.rootName
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

local function mergeEntityEntry( entry, entry0, namespace, deleted, added )
	local localAdded = added and added[ entry['id'] ]

	local components = entry.components
	for i, cid in ipairs( entry0.components ) do
		local newId = makeId( cid, namespace )
		if not( deleted and deleted[ newId ] ) then
			tinsert( components, newId )
		end
	end

	if localAdded and localAdded.components then
		for i, cid in ipairs( localAdded.components ) do
			tinsert( components, cid )
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
			tinsert( children, newChildEntry )
			mergeEntityEntry( newChildEntry, childEntry, namespace, deleted, added )
		end
	end

	if localAdded and localAdded.children then
		for i, data in ipairs( localAdded.children ) do
			tinsert( children, data )
		end
	end

end

local function mergeObjectMap( map, map0, namespace, protoPath )
	for id, data in pairs( map0 ) do
		if id:find( '!', 1, true ) == 1 then --non anonymous reference
			local newid = id
			local newData = simplecopy( data )
			map[ id ] = newData
		else
			local newid = makeId( id, namespace )
			local newData = simplecopy( data )
			local ns1 = data['namespace']
			if ns1 then
				newData['namespace'] = makeNamespace( ns1, namespace )
			else
				newData['namespace'] = namespace
			end
			map[ newid ]   = newData
			if data.model then
				local history = newData['proto_history']
				if not history then
					history = {}
					newData['proto_history'] = history
				end
				-- if not table.index( history, protoPath ) then
				tinsert( history, protoPath )
				-- end
				local protoPath0 = newData['__PROTO']
				if protoPath0 then --remove previous proto data
					newData['__PROTO']   = nil
					newData['overrided'] = nil
					newData['deleted']   = nil
					newData['added']     = nil
					-- if not table.index( history, protoPath0 ) then
					-- 	tinsert( history, protoPath0 )
					-- end
				end
			end
		end
	end
end

local function mergeGUIDMap( map, map0, namespace )
	for id, guid in pairs( map0 ) do
		local newid   = makeId( id, namespace )
		local newGuid = makeId( guid, namespace )
		map[ newid ]   = newGuid
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
	_warn( 'invalid alias:', alias, id, namespace )
	return false
end

local function mergeProtoData( data, id )
	local entityEntry = findEntityData( data, id )
	if not entityEntry then return false end

	local objData   = data.map[ id ]
	local protoPath = objData[ '__PROTO' ]
	local p0 = loadAsset( protoPath )
	local data0 = p0.data

	local overrideMap  = objData['overrided']
	local deleteList   = objData['deleted']
	local addSet       = objData['added']
	local extraMap     = objData['extra']
	
	local deleteSet = false
	if deleteList then
		deleteSet = {}
		for i, id in ipairs( deleteList ) do
			deleteSet[ id ] = true
		end
	end

	local entityEntry0 = data0.entities[1]
	local rootId = makeId( entityEntry0.id, id )

	mergeEntityEntry( entityEntry, entityEntry0, id, deleteSet, addSet )
	
	mergeObjectMap( data.map,  data0.map, id, protoPath )
	mergeGUIDMap  ( data.guid, data0.guid, id )

	local map = data.map
	
	-- print( rootId, '=>', id  )

	map[ id ] = map[ rootId ]
	map[ id ]['__PROTO']   = protoPath
	map[ id ]['overrided'] = overrideMap
	map[ id ]['deleted']   = deleteList
	map[ id ]['added']     = addSet
	map[ rootId ] = { alias = id }
	
	local guids = data.guid
	for id0, guid0 in pairs( guids ) do
		if guid0 == rootId then
			guids[id0] = nil
		end
	end
	guids[ rootId ] = id
	--overrid
	local namespace = id
	if overrideMap  then
		for id, overBody in pairs( overrideMap ) do
			if overBody then
				local oldData = getActualData( map, id, namespace )
				if oldData then
					local oldBody = oldData.body
					if not oldBody then
						table.print( map[id] )
						error('?????')
					end
					local newBody = simplecopy( oldBody )
					for k, v in pairs( overBody ) do
						newBody[ k ] = v
					end
					map[id].body = newBody				
				end
			end
		end
		if extraMap then
			for id, extraData in pairs( extraMap ) do
				local obj = map[id]
				if obj then
					obj.extra = extraData
				end
			end
		end
	end

	return true
end

--nested proto instance needs some RETRY
local function mergeProtoDataList( data, instanceIdList )
	local set = {}
	for i, id in ipairs( instanceIdList ) do
		set[id] = true
	end
	while true do
		local progress = false
		local rest = {}
		for id in pairs( set ) do
			if not mergeProtoData( data, id ) then
				rest[ id ] = true
			else
				progress = true
			end
		end
		if not next( rest ) then --job done
			break
		end
		if not progress then --error
			table.print( rest )
			error( 'failed to insert proto instance' )
		end
		set = rest --retry insertion
	end
	return true
end

_M.mergeProtoData     = mergeProtoData
_M.mergeProtoDataList = mergeProtoDataList

local _proto_id = 5
function Proto:buildInstanceData( overridedData, guid )
	local rootId = guid or "__instance_".._proto_id
	_proto_id = _proto_id - 1
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
end

function Proto:getData()
	return self.data
end

local function attachObjectNamespace( objData, model, namespace )
	local body = objData[ 'body' ]
	for k,v in pairs( body ) do
		local field = model:getField( k )
		if field then
			local ft = field:getType()
			if not ( isTupleValue( ft ) or isAtomicValue( ft ) ) then
				if ft == '@array' then
					if isAtomicValue( field.__itemtype ) then
						--do nothing
					elseif field.__objtype == 'sub' then
						--todo
					else
						for i, item in pairs( v ) do
							if type( item ) == 'string' and item:find( '!', 1, true ) == 1 and not ( item:find(':') ) then
								v[ i ] = item .. ':' .. namespace
							end
						end				
					end

				elseif field.__objtype == 'sub' then
					--todo
				elseif type( v ) == 'string' and v:find( '!', 1, true ) == 1 and not ( v:find(':') ) then
					body[ k ] = v .. ':' .. namespace
				end
			end
		else
			_info( 'missing field in proto', k, model:getName() )
		end
	end

end

function Proto:loadData( dataPath )
	if self.loading then
		print( dataPath )
		error( 'cyclic proto reference' )
	end
	self.loading = true --cyclic ref avoiding
	
	local data     = loadAssetDataTable( dataPath )
	if not data then
		error( 'empty proto data:' .. tostring( dataPath )  )
	end
	--expand all data
	local protoInstances = {}
	for id, objData in pairs( data.map )  do
		if objData[ '__PROTO' ] then
			tinsert( protoInstances, id )
		end
	end

	local rootId = data.entities[1]['id']
	mergeProtoDataList( data, protoInstances )

	--attach namespace
	local namespace = rootId
	local map1 = {}
	for id, objData in pairs( data.map ) do
		local modelName = objData[ 'model' ]
		if modelName then
			model = modelFromName( modelName )
			if model then
				attachObjectNamespace( objData, model, namespace )
			end
		end
		if type( id ) == 'string' and ( not id:find( ':' ) ) and id:find( '!', 1, true ) == 1 then
			map1[ id..':'..namespace ] = objData
		else
			map1[ id ] = objData
		end
	end
	data.map = map1

	self.data      = data
	self.ready     = true
	self.rootId    = rootId
	local rootData = data.map[ self.rootId ]
	self.rootName  = rootData['body']['name']
	self.loading   = false
	return true
end

function Proto:createInstance( overridedData, guid )
	local instanceData = self:buildInstanceData( overridedData, guid )
	local instance, objMap = deserializeEntity( instanceData )
	instance.PROTO_INSTANCE_STATE ={
		proto = self.id
	}
	-- clearNamespaceCache() --CLEAR or not ?
	return instance
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
			_warn( 'alias not found', id, alias, namespace )
		end
	end

	--find model&field
	local subId
	if subObject == instance then --root object
		subId = protoData[ 'entities' ][1]['id']
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
		local dataPath = node:getObjectFile( 'def' )
		if not dataPath then
			error( 'empty proto data path:' .. node:getNodePath() )
		end
		proto:loadData( dataPath )
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

