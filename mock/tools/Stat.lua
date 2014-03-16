module 'mock'

CLASS: Stat ()
	:MODEL{}

function Stat:__init( data )	
	self.values = {}
	self.changeListeners = {}
	if data then self:update( data ) end
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
	return self.values and values[n] or default
end

function Stat:add( n, v )
	local values = self.values
	values[n] = ( values[n] or 0 ) + ( v or 1 )
end

function Stat:set( n, v )
	local values = self.values
	local v0 = values[n]
	if v0 == v then return end
	values[n]	= v
	local changeListenerList = self.changeListeners[ n ]
	if changeListenerList then
		for func in pairs( changeListenerList ) do
			func( n, v, v0 )
		end
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

function Stat:removeChangeListener( key, func )
	local l = self.changeListeners[ key ]
	if not l then return end
	l[ func ] = nil
end
