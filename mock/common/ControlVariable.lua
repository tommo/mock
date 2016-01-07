module 'mock'

--------------------------------------------------------------------
CLASS: ControlVariable ()
	:MODEL{}

function ControlVariable:__init()
	self.name = 'name'
	self.desc = ''
	self.vtype = 'number' --'b'
	self.value = 0
end

function ControlVariable:initFromVar( v )
	local tt = type( v )
	if tt == 'boolean' then 
		return self:initBoolean( v )
	else
		return self:initNumber( v )
	end
end

function ControlVariable:initBoolean( b )
	self.vtype = 'boolean'
	self.value = b and true or false
end

function ControlVariable:initInt( i )
	self.vtype = 'int'
	self.value = math.floor( tonumber(i) or 0 )
end

function ControlVariable:initNumber( i )
	self.vtype = 'number'
	self.value = tonumber(i)
end

function ControlVariable:set( v )
	local t = self.vtype
	if t == 'number' then
		self.value = tonumber( v ) or 0
	elseif t == 'int' then
		self.value =math.floor( tonumber( v ) or 0 )
	elseif t == 'boolean' then
		self.value = v and true or false
	end
end

function ControlVariable:get()
	return self.value
end

function ControlVariable:setDesc( desc )
	self.desc = desc
end

function ControlVariable:setName( name )
	self.name = name
end

function ControlVariable:save()
	return {
		name  = self.name,
		desc  = self.desc,
		value = self.value,
		vtype  = self.vtype
	}
end

function ControlVariable:load( data )
	self.name  = data.name
	self.desc  = data.desc
	self.vtype = data.vtype
	self:set( data.value )
end

--------------------------------------------------------------------
CLASS: ControlVariableSet ()
	:MODEL{
	}

function  ControlVariableSet:__init()
	self.variables = {}
	self.variableMap = {}
	self.changingHistory = {}
end

function ControlVariableSet:clearAccCache()
	self.variableMap = {}
end

function ControlVariableSet:findVar( name )
	local var = self.variableMap[ name ]
	if var then return var end
	for i, var in ipairs( self.variables ) do
		if var.name == name then
			self.variableMap[ name ] = var
			return var
		end
	end
end

function ControlVariableSet:get( name, default )
	local var = self:findVar( name )
	if not var then return default end
	return var:get()
end

function ControlVariableSet:set( name, value )
	local var = self:findVar( name )
	if not var then
		_error( 'control variable not found:', name )
		return
	end
	var:set( value )
	-- print( var:get(), var.vtype, var.value, value )
end

function ControlVariableSet:addVar( name, vtype )
	local var = ControlVariable()
	if vtype == 'boolean' then
		var:initBoolean( false )
	elseif vtype == 'int' then
		var:initInt( 0 )
	else
		var:initNumber( 0 )
	end
	var.name = name
	table.insert( self.variables, var )
	return var
end

function ControlVariableSet:removeVar( var )
	local idx = table.index( self.variables, var )
	if not idx then return end
	table.remove( self.variables, idx )
	if self.variableMap[ var.name ] == var then
		self.variableMap[ var.name ] = nil
	end
end

function ControlVariableSet:clear()
	self.variableMap = {}
	self.variables = {}
end

function ControlVariableSet:__serialize()
	local output = {}
	for i, var in ipairs( self.variables ) do
		output[ i ] = var:save()
	end
	return output
end

function ControlVariableSet:__deserialize( data )
	local variables = {} 
	for i, varData in ipairs( data ) do
		local var = ControlVariable()
		var:load( varData )
		variables[ i ] = var
	end
	self.variables = variables
end

--------------------------------------------------------------------
--Global Object Related
--------------------------------------------------------------------
registerGlobalObject( 'ControlVariableSet', ControlVariableSet )

local function splitVariableNS( id )
	local pos = string.findlast( id, '%.' )
	if not pos then return nil, id end
	local ns   = id:sub( 1, pos-1 )
	local base = id:sub( pos+1, -1 )
	return ns, base
end

function getControlVariableSet( id )
	local db = getGlobalObject( id )
	if db and db:isInstance( ControlVariableSet ) then
		return db
	end
	return nil
end

function getControlVariable( fullId, default )
	local ns, base = splitVariableNS( fullId )
	if not ns then 
		return _error( 'no control variable set specified' )
	end
	local db = getControlVariableSet( ns )
	if db then
		return db:get( base, default )
	else
		_error( 'control variable set not found', ns )
	end
	return nil
end	

function setControlVariable( fullId, value )
	local ns, base = splitVariableNS( fullId )
	if not ns then 
		return _error( 'no control variable set specified' )
	end
	local db = getControlVariableSet( ns )
	if db then
		return db:set( base, value )
	else
		_error( 'control variable set not found', ns )
	end
	return nil
end
