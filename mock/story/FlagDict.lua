module 'mock'

--------------------------------------------------------------------
CLASS: FlagDict ()
	:MODEL{}

function FlagDict:__init()
	self.flags = {}
end

function FlagDict:get( id )
	return self.flags[ id ]
end

function FlagDict:check( id )
	local v = self:get( id )
	if v == 0 then return false end
	return v and true or false
end

function FlagDict:add( id, delta )
	delta = delta or 1
	local v = self:get( id )
	local tt = type( v )
	if tt == 'nil' then
		v = 0
	elseif tt ~= 'number' then
		_warn( 'converting non number flag', id )
		v = tonumber( v ) or 0
	end
	return self:set( id, v + delta )
end

function FlagDict:set( id, value )
	local tt = type( value )
	assert( tt == 'number' or tt =='boolean' or tt =='nil' )
	self.flags[ id ] = value
end

function FlagDict:remove( id )
	return self:set( id, nil )
end
