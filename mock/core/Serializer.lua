module 'mock'

--------------------------------------------------------------------
--TODO:
--  hash table type
--  embbed compound type? eg. array of array
--  MOAI model
--------------------------------------------------------------------
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


--------------------------------------------------------------------
CLASS: SerializeObjectMap ()
function SerializeObjectMap:__init()
	self.newObjects = {}
	self.objects    = {}
	self.objectCount = {}
	self.currentId  = 10000
end

function SerializeObjectMap:map( obj, noNewRef )
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
		id = 'OBJ'..id
	end
	self.objects[ obj ] = id
	self.objectCount[ obj ] = 1
	self.newObjects[ obj ] = id
	return id
end

function SerializeObjectMap:flush()
	local newObjects = self.newObjects
	self.newObjects = {}
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
		id = id .. ':' .. namespace
	end
	self.objects[ id ] = { obj, data }
end

function DeserializeObjectMap:get( namespace, id )
	if namespace then
		id = id .. ':' .. namespace
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
		data[ id ] = f:getValue( obj )
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
				array[ i ] = objMap:map( item, noNewRef )
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
function _serializeObject( obj, objMap, noNewRef )
	local tt = type(obj)
	if tt == 'string' or tt == 'number' or tt == 'boolean' then
		return { model = false, body = obj }
	end

	local model = getModel( obj )
	if not model then return nil end

	local fields = model:getFieldList( true )
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
		extra = __serialize( obj )
	end

	return {
		model = model:getName(),
		body  = body,
		extra = extra
	}
end

--------------------------------------------------------------------
local function serialize( obj, objMap )
	assert( obj )
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
		if fieldData then
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
					local itemTarget = objMap[ makeId( itemData, namespace ) ]
					array[ i ] = itemTarget[1]
				else
					local item = _deserializeObject( nil, itemData, objMap, namespace )
					array[ i ] = item
				end
			end
		else
			for i, itemData in pairs( fieldData ) do
				if type( itemData ) == 'table' then --need conversion?
					local item = _deserializeObject( nil, itemData, objMap, namespace )
					array[ i ] = item
				else
					local itemTarget = objMap[ makeId( itemData, namespace ) ]
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
		local newid = makeId( fieldData, namespace )
		local target = objMap[ newid ]
		if not target then
			_error( 'target not found', id )
			f:setValue( obj, nil )
		else
			f:setValue( obj, target[1] )
		end
	end

end

function _deserializeObject( obj, data, objMap, namespace )
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

	local ns0 = data['namespace']
	if ns0 then
		namespace = makeId( ns0, namespace )
	end

	local fields = model:getFieldList( true )
	local body   = data.body
	for _,f in ipairs( fields ) do
		if not ( f:getMeta( 'no_save', false ) or f:getType() == '@action' ) then
			_deserializeField( obj, f, body, objMap, namespace )		
		end
	end

	local __deserialize = obj.__deserialize
	if __deserialize then
		__deserialize( obj, data['extra'], namespace )
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
		objMap[ id ] = objMap[ alias ]
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

function serializeToString( obj )
	local data = serialize( obj )
	local str  = encodeJSON( data )
	return str	
end

function deserializeFromString( obj, str, objMap )
	local data = MOAIJsonParser.decode( str )
	obj = deserialize( obj, data, objMap )
	return obj
end

function serializeToFile( obj, path )
	local str = serializeToString( obj )	
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
		assert( dstModel == model )
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
		__clone( dst, obj )
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


_M.serialize   = serialize
_M.deserialize = deserialize
_M.clone       = _cloneObject
_M._serializeObject   = _serializeObject
_M._deserializeObject = _deserializeObject

_M._deserializeObjectMap = _deserializeObjectMap

_M.isTupleValue  = isTupleValue
_M.isAtomicValue = isAtomicValue

_M.makeNameSpacedId = makeId