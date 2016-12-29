module 'mock'

local insert = table.insert
---------------------------------------------------------------------
local WidgetClassNameCache = {}
local function getWidgetClassCache( clas )
	local list = WidgetClassNameCache[ clas ] 
	if not list then
		list = {}
		local c = clas
		while true do
			local name = c.__name
			insert( list, 1, name )
			c = c.__super
			if c == UIWidget or ( not c ) then break end
		end
		insert( list, 1, 'UIWidget' )
		WidgetClassNameCache[ clas ] = list
	end
	return list
end

--------------------------------------------------------------------
CLASS: UIStyleAccessor ()
	:MODEL{}

function UIStyleAccessor:__init( owner )
	self.owner   = owner
	self.skin    = false
	self.state   = false

	self.featureSet = {}
	self.needUpdate = true

	local clas = owner.__class
	self.localQueryBaseList = getWidgetClassCache( clas )
	
	self.localQueryList = false
	self.queryList      = false
	self.fullQuery      = false

	self.cachedData     = {}

end

function UIStyleAccessor:setSkin( skin )
	self.skin = skin or false
	self:markDirty()
end

function UIStyleAccessor:setState( s )
	self.state = s
	self:markDirty()
end

function UIStyleAccessor:setFeature( f, bvalue )
	bvalue = bvalue or nil
	local featureSet = self.featureSet
	local b0 = featureSet[ f ]
	if b0 == bvalue then return end
	featureSet[ f ] = bvalue
	self:markDirty()
end

function UIStyleAccessor:hasFeature( f )
	return self.featureSet[ f ] and true
end

function UIStyleAccessor:setFeatures( f )
	local t = {}
	if f then
		for i, k in ipairs( f ) do
			t[ k ] = true
		end
	end
	self.featureSet = t
	self:markDirty()
end

function UIStyleAccessor:getFeatures()
	local t = {}
	return table.keys( self.featureSet )
end

function UIStyleAccessor:markDirty()
	self.cachedData     = false
	self.queryList      = false
	self.localQueryList = false
	self.owner:onStyleChanged()
end

function UIStyleAccessor:update()
	if self.cachedData then return end
	local queryList = self:getQueryList()
	--TODO
end


local function collectQuery( parent )
end

function UIStyleAccessor:getQueryList()
	local list, fullQuery = self.queryList, self.fullQuery
	if list then return list, fullQuery end
	return self:buildQueryList()
end

function UIStyleAccessor:buildQueryList()
	local owner = self.owner
	--update suffix
	local features = table.keys( self.featureSet )
	table.sort( features )
	local state = self.state
	local statePart = state and ( ':'..state ) or ''
	local featurePart = ''
	for i, f in ipairs( features ) do
		featurePart = featurePart.. '.'..f
	end

	local suffix = statePart..featurePart
	self.localFullQuery = self.owner.__class.__name .. suffix

	local baseList = self.localQueryBaseList
	local queryList = {}
	local localQueryList = {}
	local fullQuery = self.localFullQuery

	for i, prefix in ipairs( baseList ) do
		local query = prefix .. suffix
		localQueryList[ i ] = query
		queryList[ i ] = query
	end

	local parent = owner.parent
	while true do
		if not ( parent and parent.FLAG_UI_WIDGET ) then break end
		local pacc = parent.styleAcc
		local plist, pFullQuery = pacc:getQueryList()
		for i, parentQuery in ipairs( plist ) do
			for i, localQuery in ipairs( localQueryList ) do
				local query = parentQuery .. '>' .. localQuery
				insert( queryList, query )
			end
		end
		fullQuery =  pFullQuery .. '>'.. fullQuery
		parent = parent.parent
	end
	--TODO: remove queries without result
	self.queryList = queryList
	return queryList, fullQuery
end

function UIStyleAccessor:getColor( key )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'string' then
		if data == 'none' then
			return 0,0,0,0
		end
		if tt:startwith( '#' ) then
			return hexcolor( data )
		else
			local hex = getNamedColorHex( data )
			if hex then
				return hexcolor( hex )
			end
		end
	end
	return nil
end

function UIStyleAccessor:getVec2( )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data
	elseif tt == 'table' then
		local a,b = unpack( data )
		return a or 0, b or 0
	end
	return nil
end

function UIStyleAccessor:getVec3( )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data, data
	elseif tt == 'table' then
		local a,b,c,d = unpack( data )
		return a or 0, b or 0, c or 0
	end
	return nil
end

function UIStyleAccessor:getVec4( )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data, data, data
	elseif tt == 'table' then
		local a,b,c,d = unpack( data )
		return a or 0, b or 0, c or 0, d or 0
	end
	return nil
end

function UIStyleAccessor:getString( data )
	local tt = type( data )
	return tt == 'string' and data or nil
end

function UIStyleAccessor:getNumber( data )
	local tt = type( data )
	return tt == 'number' and data or nil
end

function UIStyleAccessor:getBoolean( data )
	local tt = type( data )
	return tt == 'boolean' and data or nil
end
