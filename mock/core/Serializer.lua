module 'mock'

--------------------------------------------------------------------
--TODO:
--  hash table type
--  embbed compound type? eg. array of array
--  MOAI model
--------------------------------------------------------------------
local NULL = {}

local function getModel( obj )
	local class = getClass( obj )
	if not class then return nil end
	return Model.fromClass( class )	
end

local function isAtomicValue( ft )
	return
		   ft == 'number' 
		or ft == 'int' 
		or ft == 'string' 
		or ft == 'boolean' 
		or ft == '@enum'
		or ft == '@asset'
		or ft == 'variable'
end

local function isTupleValue( ft )
	return
		   ft == 'vec2' 
		or ft == 'vec3' 
		or ft == 'color'
end


local function makeId( refId, namespace )
	return namespace and refId..':'..namespace or refId
end

local namespaceParentCache = {}
local find = string.find
local sub  = string.sub

local function findNamespaceParent( ns )
	while true do
		local idx = find( ns, ':' )
		local parent
		if idx then
			parent = sub( ns, idx+1 )
		end
		namespaceParentCache[ ns ] = parent or false
		if not parent then return end
		ns = parent
	end
end

local function makeNamespace( ns, ns0 )
	if ns0 then
		local newNS = ns..':'..ns0
		if namespaceParentCache[ newNS ] == nil then
			findNamespaceParent( newNS )
		end
		return newNS
	else
		return ns
	end
end

local function clearNamespaceCache()
	namespaceParentCache = {}
end

--------------------------------------------------------------------
CLASS: SerializeObjectMap ()
function SerializeObjectMap:__init()
	self.newObjects = {}
	self.objects    = {}
	self.objectCount = {}
	self.internalObjects = {}
	self.currentId  = 10000
end

function SerializeObjectMap:mapInternal( obj, noNewRef )
	local id = self:map( obj, noNewRef )
	if not id then return nil end
	self:makeInternal( obj )
	return id
end

function SerializeObjectMap:makeInternal( obj )
	self.internalObjects[ obj ] = true
	self.newObjects[ obj ] = nil
end

function SerializeObjectMap:isInternal( obj )
	return self.internalObjects[ obj ] ~= nil
end

function SerializeObjectMap:map( obj, noNewRef )
	if not obj then return nil end
	local id = self.objects[ obj ]
	if id then
		self.objectCount[ obj ] = self.objectCount[ obj ] + 1
		return id
	end
	if noNewRef then return nil end
	if obj.__guid then
		id = obj.__guid
	else
		id = self.currentId + 1
		self.currentId = id
		id = '!'..id
	end
	self.objects[ obj ] = id
	self.objectCount[ obj ] = 1
	self.newObjects[ obj ] = id
	return id
end

function SerializeObjectMap:flush( obj )
	local newObjects = self.newObjects
	if obj then
		if newObjects[ obj ] then
			newObjects[ obj ] = nil
			return obj
		end
	else
		self.newObjects = {}
	end
	return newObjects
end

function SerializeObjectMap:getObjectRefCount( obj )
	return self.objectCount[ obj ] or 0
end

function SerializeObjectMap:hasObject( obj )
	return self.objects[ obj ] or false
end


--------------------------------------------------------------------
CLASS: DeserializeObjectMap ()

function DeserializeObjectMap:__init()
	self.objects = {}
end

function DeserializeObjectMap:set( namespace, id, obj, data )
	if namespace then
		id = makeId( id, namespace )
	end
	self.objects[ id ] = { obj, data }
end

function DeserializeObjectMap:get( namespace, id )
	if namespace then
		id = makeId( id, namespace )
	end
	return self.objects[ id ]
end

---------------------------------------------------------------------
local _serializeObject, _serializeField

function _serializeField( obj, f, data, objMap, noNewRef )
	local id = f:getId()

	local ft = f:getType()
	
	if f.__is_tuple or isTupleValue( ft ) then
		local v = { f:getValue( obj ) }
		data[ id ] = v
		return
	end

	if isAtomicValue( ft ) then
		local v = f:getValue( obj )
		if v ~= nil then
			data[ id ] = v
		end
		return
	end

	local fieldValue = f:getValue( obj )
	if not fieldValue then 
		data[ id ] = nil
		return
	end

	if ft == '@array' then --compound
		local array = {}
		if isAtomicValue( f.__itemtype ) then
			for i, item in pairs( fieldValue ) do
				array[ i ] = item
			end
		elseif f.__objtype == 'sub' then
			for i, item in pairs( fieldValue ) do
				local itemData = _serializeObject( item, objMap )
				array[ i ] = itemData
			end
		else --ref
			for i, item in pairs( fieldValue ) do
				array[ i ] = item and objMap:map( item, noNewRef ) or false
			end
		end
		data[ id ] = array
		return
	end

	if f.__objtype == 'sub' then
		data[ id ] = _serializeObject( fieldValue, objMap )
	else --ref					
		data[ id ] = objMap:map( fieldValue, noNewRef )
	end

end

--------------------------------------------------------------------
function _serializeObject( obj, objMap, noNewRef, partialFields )
	local tt = type(obj)
	if tt == 'string' or tt == 'number' or tt == 'boolean' then
		return { model = false, body = obj }
	end

	local model = getModel( obj )
	if not model then return nil end

	local fields 

	if partialFields then
		fields = {}
		for i, key in ipairs( partialFields ) do
			local f = model:getField( key, true )
			if f then table.insert( fields, f ) end
		end
	else
		fields = model:getFieldList( true )	
	end

	---
	local body = {}

	for _, f in ipairs( fields ) do
		if not ( f:getMeta( 'no_save', false ) or f:getType() == '@action' ) then
			_serializeField( obj, f, body, objMap, noNewRef )
		end
	end
	----	

	local extra = false

	local __serialize = obj.__serialize
	if __serialize then 
		extra = __serialize( obj, objMap )
	end

	return {
		model = model:getName(),
		body  = body,
		extra = extra
	}
end

--------------------------------------------------------------------
local function serialize( obj, objMap )
	assert( obj, 'nil object' )
	objMap = objMap or SerializeObjectMap()
	local rootId = objMap:map( obj )
	local map = {}
	while true do
		local newObjects = objMap:flush()
		if next( newObjects ) then
			for obj, id in pairs( newObjects )  do
				map[ id ] = _serializeObject( obj, objMap )
			end
		else
			break
		end
	end

	local model = getModel( obj )

	return {		
		root  = rootId,
		model = model:getName(),
		map   = map
	}
end

local find = string.find
local sub  = string.sub
local function getObjectWithNamespace( objMap, id, namespace )
	while true do
		if not namespace then return objMap[ id ] end
		local newId = makeId( id, namespace )
		local obj = objMap[ newId ]
		if obj then return obj end
		namespace = namespaceParentCache[ namespace ]
	end
	-- while true do

	-- 	local newId = makeId( id, namespace )
	-- 	local obj = objMap[ newId ]
	-- 	if obj then return obj end
		
	-- 	if not namespace then return nil end

	-- 	local idx = find( namespace, ':' )
	-- 	if idx then
	-- 		namespace = sub( namespace, idx+1 )
	-- 	else
	-- 		namespace = nil
	-- 	end
	-- 	-- return objMap[ newId ] or objMap[ id ]
	-- end
end

--------------------------------------------------------------------
local _deserializeField, _deserializeObject

function _deserializeField( obj, f, data, objMap, namespace )
	local id = f:getId()
	local fieldData = data[ id ]
	local ft = f:getType()
	if isAtomicValue( ft ) then
		if fieldData ~= nil then
			f:setValue( obj, fieldData )
		end
		return
	end

	if f.__is_tuple or isTupleValue( ft ) then --compound
		if type( fieldData ) == 'table' then
			f:setValue( obj, unpack( fieldData ) )
		end
		return
	end

	if not fieldData then
		f:setValue( obj, nil )
		return
	end

	if ft == '@array' then --compound
		local array = {}
		local itemType = f.__itemtype
		if isAtomicValue( itemType ) then
			for i, itemData in pairs( fieldData ) do
				array[ i ] = itemData
			end
		elseif f.__objtype == 'sub' then
			for i, itemData in pairs( fieldData ) do
				if type( itemData ) == 'string' then --need conversion?
					local itemTarget = getObjectWithNamespace( objMap, itemData, namespace )
					array[ i ] = itemTarget[1]
				else
					local item = _deserializeObject( nil, itemData, objMap, namespace )
					array[ i ] = item
				end
			end
		else
			for i, itemData in pairs( fieldData ) do
				local tt = type( itemData )
				if tt == 'table' then --need conversion?
					local item = _deserializeObject( nil, itemData, objMap, namespace )
					array[ i ] = item
				elseif itemData == false then --'NULL'?
					array[ i ] = false
				else
					local itemTarget = getObjectWithNamespace( objMap, itemData, namespace )
					array[ i ] = itemTarget[1]
				end
			end
		end
		f:setValue( obj, array )
		return
	end

	if f.__objtype == 'sub' then
		f:setValue( obj, _deserializeObject( nil, fieldData, objMap, namespace ) )
	else --'ref'
		local target = getObjectWithNamespace( objMap, fieldData, namespace )
		if not target then
			_error( 'target not found', newid )
			f:setValue( obj, nil )
		else
			f:setValue( obj, target[1] )
		end
	end

end

function _deserializeObject( obj, data, objMap, namespace, partialFields )
	local model 
	if obj then
		model = getModel( obj )
	else
		local modelName = data['model']
		if modelName then
			model = Model.fromName( modelName )
		else --raw value
			return data['body'], objMap
		end
	end
	
	if not model then return nil end

	if not obj then
		obj = model:newInstance()
	else
		--TODO: assert obj class match
	end

	local ns = data['namespace']
	if ns then
		namespace = makeNamespace( ns, namespace )
	end

	local fields 
	if partialFields then
		fields = {}
		for i, key in ipairs( partialFields ) do
			local f = model:getField( key, true )
			if f then table.insert( fields, f ) end
		end
	else
		fields = model:getFieldList( true )	
	end
	
	local body   = data.body
	for _,f in ipairs( fields ) do
		if not ( f:getMeta( 'no_save', false ) or f:getType() == '@action' ) then
			_deserializeField( obj, f, body, objMap, namespace )		
		end
	end

	local __deserialize = obj.__deserialize
	if __deserialize then
		__deserialize( obj, data['extra'], objMap )
	end

	return obj, objMap
end

local function _deserializeObjectMap( map, objMap, objIgnored, rootId, rootObj )
	objMap = objMap or {}
	objIgnored = objIgnored or {}
	objAliases = {}

	for id, objData in pairs( map ) do
		if not objIgnored[ id ] then			
			local modelName = objData.model
			if not modelName then --alias/raw
				local alias = objData['alias']
				if alias then
					local ns0 = objData['namespace']
					if ns0 then alias = makeId( alias, ns0 ) end
					objAliases[ id ] = alias
					objMap[ id ] = alias
				else
					objMap[ id ] = { objData.body, objData }
				end
			else
				local model = Model.fromName( modelName )
				if not model then
					error( 'model not found for '.. objData.model )
				end
				local instance 
				if rootObj and id == rootId then
					instance = rootObj
				else
					instance = model:newInstance()
				end
				objMap[ id ] = { instance, objData }
			end
		end
	end

	for id, alias in pairs( objAliases ) do
		local origin
		while alias do
			origin = objMap[ alias ]
			if type( origin ) == 'string' then
				alias = origin
			else
				break
			end
		end
		if not origin then
			table.print( objMap )
			_error( 'alias not found', id, alias )
			error()
		end
		objMap[ id ] = origin
	end

	for id, item in pairs( objMap ) do
		if not objIgnored[ id ] and not objAliases[id] then
			local obj     = item[1]
			local objData = item[2]
			_deserializeObject( obj, objData, objMap )
		end
	end

	return objMap
end

local function deserialize( obj, data, objMap )
	objMap = objMap or {}
	if not data then return obj end
	
	local map = data.map or {}
	local rootId = data.root
	if not rootId then return nil end

	objMap = _deserializeObjectMap( map, objMap, false, rootId, obj )

	local rootTarget = objMap[ rootId ]
	return rootTarget[1]
end



--------------------------------------------------------------------
local deflate = false

function serializeToString( obj, compact )
	local data = serialize( obj )
	local str  = encodeJSON( data, compact or false )
	return str	
end

function deserializeFromString( obj, str, objMap )
	local data = MOAIJsonParser.decode( str )
	obj = deserialize( obj, data, objMap )
	return obj
end

function serializeToFile( obj, path, compact )
	local str = serializeToString( obj, compact )	
	if deflate then
		str  = MOAIDataBuffer.deflate( str, 0 )
	end
	local file = io.open( path, 'wb' )
	if file then
		file:write( str )
		file:close()
	else
		_error( 'can not write to file', path )
	end
	return data
end

function deserializeFromFile( obj, path, objMap )
	assert( path, 'no input for deserialization' )
	local file=io.open( path, 'rb' )
	if file then
		local str = file:read('*a')
		file:close()
		if deflate then
			str  = MOAIDataBuffer.inflate( str )
		end
		obj = deserializeFromString( obj, str, objMap )
	else
		_error( 'file not found', path )
	end
	return obj
end

--------------------------------------------------------------------

local _cloneObject, _cloneField

function _cloneField( obj, dst, f, objMap )
	local id = f:getId()

	local ft = f:getType()
	if isAtomicValue( ft ) or isTupleValue( ft ) then
		f:setValue( dst, f:getValue( obj ) )
		return
	end

	local fieldValue = f:getValue( obj )
	if not fieldValue then 
		f:setValue( dst, fieldValue )
		return
	end

	if ft == '@array' then --compound
		local array = {}
		if isAtomicValue( f.__itemtype ) then
			for i, item in pairs( fieldValue ) do
				array[ i ] = item
			end
		elseif f.__objtype == 'sub' then
			for i, item in pairs( fieldValue ) do
				array[ i ] = _cloneObject( item, nil, objMap )
			end
		else --ref
			for i, item in pairs( fieldValue ) do
				array[ i ] = objMap[ item ] or item
			end
		end
		f:setValue( dst, array )
		return
	end

	if f.__objtype == 'sub' then
		f:setValue( dst, _cloneObject( fieldValue, nil, objMap ) )
	else --ref					
		f:setValue( dst, objMap[ fieldValue ] or fieldValue )
	end

end

--------------------------------------------------------------------
function _cloneObject( obj, dst, objMap )
	local model = getModel( obj )
	if not model then return nil end
	if dst then
		local dstModel = getModel( dst )
		-- assert( dstModel == model )
	else
		dst = model:newInstance()
	end
	objMap = objMap or {}
	objMap[ obj ] = dst
	local fields = model:getFieldList( true )
	---
	for _, f in ipairs( fields ) do
		if not ( f:getMeta( 'no_save', false ) or f:getType() == '@action' ) then
			_cloneField( obj, dst, f, objMap )
		end
	end
	----	
	local __clone = dst.__clone
	if __clone then
		__clone( dst, obj, objMap )
	end
	return dst
end

--------------------------------------------------------------------

function checkSerializationFile( path, modelName )
	local file=io.open( path, 'rb' )
	if file then
		local str = file:read('*a')
		if deflate then
			str  = MOAIDataBuffer.inflate( str )
		end
		local data = MOAIJsonParser.decode( str )
		if not data then return false end		
		return data['model'] == modelName
	else
		return false
	end	
end

function createEmptySerialization( path, modelName )
	local model = Model.fromName( modelName )
	if not model then return false end
	local target = model:newInstance() 
	if not target then return false end
	serializeToFile( target, path )
	return true
end


--------------------------------------------------------------------
--public API
_M.serialize   = serialize
_M.deserialize = deserialize
_M.clone       = _cloneObject

--internal API
_M._serializeObject      = _serializeObject
_M._cloneObject          = _cloneObject
_M._deserializeObject    = _deserializeObject
_M._deserializeObjectMap = _deserializeObjectMap

_M._deserializeField     = _deserializeField
_M._serializeField       = _serializeField

_M.isTupleValue          = isTupleValue
_M.isAtomicValue         = isAtomicValue

_M.makeNameSpacedId      = makeId
_M.makeNameSpace         = makeNamespace
_M.clearNamespaceCache   = clearNamespaceCache

_M._NULL = NULL