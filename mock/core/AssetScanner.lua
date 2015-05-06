module 'mock'

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

local _scanObject, _scanField

function _scanField( obj, f, data, assetSet, noNewRef )
	local id = f:getId()

	local ft = f:getType()
	if ft == '@asset' then
		local v = f:getValue( obj )
		if v then assetSet[ v ] = true end
	elseif isAtomicValue( ft ) or isTupleValue( ft ) then
		return
	end

	local fieldValue = f:getValue( obj )
	if not fieldValue then 
		data[ id ] = nil
		return
	end

	if ft == '@array' then --compound
		local array = {}
		local it = f.__itemtype
		if it == '@asset' then
			for i, item in pairs( fieldValue ) do
				if item then
					assetSet[ item ] = true
				end
			end
		elseif f.__objtype == 'sub' then
			for i, item in pairs( fieldValue ) do
				_scanObject( item, assetSet )
			end
		else --ref
			--let go			
		end		
		return
	end

	if f.__objtype == 'sub' then
		_scanObject( fieldValue, assetSet )
	else --ref					
		--let go
	end

end

--------------------------------------------------------------------
function _scanObject( obj, assetSet, noNewRef )
	local tt = type(obj)
	if tt == 'string' or tt == 'number' or tt == 'boolean' then
		return
	end

	local model = getModel( obj )
	if not model then return nil end

	local fields = model:getFieldList( true )
	---
	local data = {}

	for _, f in ipairs( fields ) do
		if not ( f:getMeta( 'no_save', false ) or f:getType() == '@action' ) then
			_scanField( obj, f, data, assetSet, noNewRef )
		end
	end

	return	
end

function scanObjectAsset( entry, assetSet )
	assetSet = assetSet or {}
	_scanObject( entry, assetSet )
	return assetSet
end

function _scanEntity( e, assetSet )
	scanObjectAsset( e, assetSet )
	if e.children then
		for child in pairs( e.children ) do
			_scanEntity( child, assetSet )
		end
	end
	if e.components then
		for com in pairs( e.components ) do
			scanObjectAsset( com, assetSet )
		end
	end
end

function scanEntityAsset( e )
	local assetSet = {}
	_scanEntity( e, assetSet )
	return assetSet
end

function scanSceneAsset( scn )
	local assetSet = {}
	for e in pairs( scn.entities ) do
		if not e.parent then
			_scanEntity( e, assetSet )
		end
	end
	return assetSet
end
