module 'mock'

CLASS: Stat ()
	:MODEL{}

function Stat:__init( data )	
	self.values = {}
	self.changeListeners = {}
	self.changeSignals   = {}
	self.allowNotifyChanges = true
	self.globalChangeSignal = false
	self.globalChangeListenerList = {}
	self.changeListeners[ '*' ] = self.globalChangeListenerList
	if data then self:update( data ) end

	local accessorMT = {
			__index = function( t, k )
					return self:get( k )
				end,

			__newindex = function( t, k, v )
					return self:set( k, v )
				end
		}
		
	self.accessor = setmetatable( {}, accessorMT )

end

function Stat:disableNotifyChanges()
	self.allowNotifyChanges = true
end

function Stat:enableNotifyChanges( enabled )
	self.allowNotifyChanges = enabled ~= false
end

function Stat:getAccessor()
	return self.accessor
end

function Stat:getValues()
	return self.values
end

function Stat:update( data )
	if data then
		local t = self.values
		for k, v in pairs( data ) do
			t[ k ] = v
		end
	end
end

function Stat:clear()
	self.values = {}
end

function Stat:get( n, default )
	local values = self.values
	local v = values[n]
	return v == nil and default or v
end

function Stat:add( n, v )
	local values = self.values
	return self:set( n, ( values[n] or 0 ) + ( v or 1 ) )
end

function Stat:sub( n, v )
	return self:add( n, -v )
end

function Stat:setRaw( n, v )
	self.values[n]	= v
end

function Stat:set( n, v, notify )
	local values = self.values
	local v0 = values[n]
	if v0 == v then return end
	values[n]	= v
	if not self.allowNotifyChanges then return end
	for func in pairs( self.globalChangeListenerList ) do
		func( n, v, v0 )
	end

	local changeListenerList = self.changeListeners[ n ]
	if changeListenerList then
		for func in pairs( changeListenerList ) do
			func( n, v, v0 )
		end
	end
	local sig = self.changeSignals[ n ]
	if sig then
		emitSignal( sig, n , v, v0 )
	end
	if self.globalChangeSignal then
		emitSignal( self.globalChangeSignal, n, v, v0 )
	end
end

function Stat:setMax( n, v )
	if self:isMax( n, v ) then return self:set( n, v ) end	
end

function Stat:setMin( n, v )
	if self:isMin( n, v ) then return self:set( n, v ) end		
end

function Stat:isMax( n, v )
	local values = self.values
	local v0 = values[n]
	return not v0 or v > v0
end

function Stat:isMin( n, v )
	local values = self.values
	local v0 = values[n]
	return not v0 or v < v0
end

function Stat:addChangeListener( key, func )
	local l = self.changeListeners[ key ]
	if not l then
		l = {}
		self.changeListeners[ key ] = l
	end
	l[ func ] = true
end

function Stat:removeChangeListener( a, b )
	local key, func
	if a and b then
		key, func = a, b
		local l = self.changeListeners[ key ]
		if not l then return end
		l[ func ] = nil
	elseif type( a ) == 'function' then
		for _, l in pairs( self.changeListeners ) do
			l[ a ] = nil
		end
	end
end

function Stat:setGlobalChangeSignal( sigName )
	self.globalChangeSignal = sigName
end

function Stat:setChangeSignal( key, sigName )
	if self.changeSignals[ key ] and sigName then
		_warn( 'duplicated change singal for stat key:', key )
	end
	self.changeSignals[ key ] = sigName
end

function Stat:setChangeSignalList( t )
	for i, entry in ipairs( t ) do
		local key, sig = unpack( entry )
		self:setChangeSignal( key, sig )
	end
end

function Stat:serialize()
	return MOAIJsonParser.decode( MOAIJsonParser.encode( self.values ) )
end

function Stat:deserialize( values )
	self.values = values
end
