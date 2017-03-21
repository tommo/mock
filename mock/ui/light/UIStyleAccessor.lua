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
	self.styleSheet    = false
	self.state   = false

	self.featureSet = {}
	self.needUpdate = true

	local clas = owner.__class
	self.localQueryBaseList = getWidgetClassCache( clas )
	
	self.localQueryList = false
	self.queryList      = false
	self.fullQuery      = false

	self.cachedData     = false
	self.localData      = false

end

function UIStyleAccessor:setStyleSheet( styleSheet )
	self.styleSheet = styleSheet or false
	self:markDirty()
end

function UIStyleAccessor:getStyleSheet()
	local styleSheet = self.styleSheet
	if not styleSheet then return getBaseStyleSheet() end
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
	local owner = self.owner
	owner.styleModified = true
	owner:invalidateVisual()
end

function UIStyleAccessor:getStyleSheet()
	return self.owner:getStyleSheetObject() or getBaseStyleSheet()
end

function UIStyleAccessor:update()
	if self.cachedData then return end
	local styleSheet = self:getStyleSheet()
	self.cachedData = styleSheet:query( self ) or {}
end

function UIStyleAccessor:getQueryList()
	local list, fullQuery = self.queryList, self.fullQuery
	if list then return list, fullQuery end
	return self:buildQueryList()
end

function UIStyleAccessor:buildQueryList()
	local owner = self.owner
	local sheet = self:getStyleSheet()
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
		localQueryList[ i ] = { prefix, query }
		queryList[ i ] = { prefix, query }
	end

	local maxPathSize = sheet.maxPathSize
	local parent = owner:getParentWidget()
	local pathSize = 1
	while parent do
		pathSize = pathSize + 1
		if pathSize > maxPathSize then break end
		local pacc = parent.styleAcc
		local plist, pFullQuery = pacc:getQueryList()
		for i, parentQuery in ipairs( plist ) do
			for i, localQuery in ipairs( localQueryList ) do
				local query = parentQuery[2] .. '>' .. localQuery[2]
				insert( queryList, { localQuery[1], query } )
			end
		end
		fullQuery =  pFullQuery .. '>'.. fullQuery
		parent = parent:getParentWidget()
	end
	
	--TODO: remove queries without resul
	-- print( '----')
	-- for i, entry in ipairs( queryList ) do
	-- 	print( entry[ 2 ] )
	-- end

	self.queryList = queryList
	self.fullQuery = fullQuery
	return queryList, fullQuery
end

function UIStyleAccessor:get( key, default )
	local v = self.cachedData[ key ]
	if v == nil then return default end
	return v
end

function UIStyleAccessor:getColor( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'string' then
		if data == 'none' then
			return 0,0,0,0
		end
		if data:startwith( '#' ) then
			return hexcolor( data )
		else
			local hex = getNamedColorHex( data )
			if hex then
				return hexcolor( hex )
			end
		end
	end
	if default then
		return unpack( default )
	else
		return nil
	end
end

function UIStyleAccessor:getVec2( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data
	elseif tt == 'table' then
		local a,b = unpack( data )
		return a or 0, b or 0
	end
	if default then
		return unpack( default )
	else
		return nil
	end
end

function UIStyleAccessor:getVec3( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data, data
	elseif tt == 'table' then
		local a,b,c,d = unpack( data )
		return a or 0, b or 0, c or 0
	end
	if default then
		return unpack( default )
	else
		return nil
	end
end

function UIStyleAccessor:getVec4( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	if tt == 'number' then
		return data, data, data, data
	elseif tt == 'table' then
		local a,b,c,d = unpack( data )
		return a or 0, b or 0, c or 0, d or 0
	end
	if default then
		return unpack( default )
	else
		return nil
	end
end

function UIStyleAccessor:getString( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	return tt == 'string' and data or default
end

function UIStyleAccessor:getNumber( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	return tt == 'number' and data or default
end

function UIStyleAccessor:getBoolean( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	return tt == 'boolean' and data or default
end

function UIStyleAccessor:getAsset( key, default )
	local data = self.cachedData[ key ]
	local tt = type( data )
	local owner = self.owner
	if tt == 'table' then
		if data.tag == 'asset' then return data.asset end
		if data.tag == 'object' then return data.object end
	elseif tt == 'string' then
		return data
	end
	return default
end
