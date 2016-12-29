module 'mock'

--------------------------------------------------------------------
local _UIStyleLoaderEnv = {}

--value packing functions
function _UIStyleLoaderEnv.rgb( r,g,b )
	return { ( r or 255 ) / 255, ( g or 255 ) /255, ( b or 255 ) / 255 }
end

function _UIStyleLoaderEnv.rgba( r,g,b,a )
	return { ( r or 255 ) / 255, ( g or 255 ) /255, ( b or 255 ) / 255, ( a or 255 ) / 255 }
end

function _UIStyleLoaderEnv.image( path )
	return { path = path }
end

function _UIStyleLoaderEnv.script( s )
	return s
end

local function _loadUIStyleSheetSource( src )
	local items = {}
	local currentNamespace = ''
	local function namespaceFunc( n )
		currentNamespace = type( n ) == 'string' and n or ''
		currentNamespace = currentNamespace:trim() .. ' '
	end

	local function styleFunc( ... )
		local styleItem = UIStyleRawItem()
		styleItem:setNamespace( currentNamespace )
		styleItem:parseTarget( ... )
		table.insert( items, styleItem )

		local styleUpdater
		styleUpdater = function( data )
			local tt = type( data )
			if tt == 'table' then
				styleItem:load( data )

			elseif tt == 'string' then
				styleItem:parseTarget( data )
				return styleUpdater

			else
				error( 'invalid style data', 2 )
			end

		end

		return styleUpdater
	end

	local env = {
		style = styleFunc;
		namespace = namespaceFunc;
	}

	setmetatable( env, { __index = _UIStyleLoaderEnv } )
	local func, err = loadstring( src )
	if not func then
		_warn( 'failed loading style sheet script' )
		print( err )
		return false
	end

	setfenv( func, env )
	local ok, err = pcall( func )
	if not ok then
		_warn( 'failed evaluating style sheet script' )
		print( err )
		return false
	end

	return items
end


--------------------------------------------------------------------
CLASS: UIStyleSheetCache ()
	:MODEL{}

function UIStyleSheetCache:__init()
	self.sheets   = {}
	self.sheetSet = {}
	self.cache = {}
	self.dirty = true
end

function UIStyleSheetCache:addSheet( sheet )
	assert( sheet )
	if not self.sheetSet[ sheet ] then
		table.insert( self.sheets, sheet )
		self.sheetSet[ sheet ] = true
		self:markDirty()
	end
	return sheet
end

function UIStyleSheetCache:markDirty()
	self.dirty = true
	self.cache = {}
end

function UIStyleSheetCache:update( forced )
	if not ( forced or self.dirty ) then return end
	--TODO
end

function UIStyleSheetCache:query( acc )
	self:update()
	local queryList, fullQuery = acc:getQueryList()
	local data = self.cache[ fullQuery ]
	if not data then
		data = {}
		for i, query in ipairs( queryList ) do
			local result = self:_queryStyleData( query )
			for k, v in pairs( result ) do
				data[ k ] = v
			end
		end
		self.cache[ fullQuery ] = data
	end
	return data
end

function UIStyleSheetCache:_queryStyleData( query )
	local data = self.cache[ query ]
	if data then return data end

	data = {}
	for i, sheet in ipairs( self.sheets ) do
		sheet:collectData( query, data )
	end
	self.cache[ query ] = data

	return data
end

--------------------------------------------------------------------
CLASS: UIStyleSheet ()
	:MODEL{}

function UIStyleSheet:__init()
	self.items = {}
end

function UIStyleSheet:load( src )
	local items = _loadUIStyleSheetSource( src )
	if items then
		self.items = items
		return true
	else
		self.items = {}
		return false
	end
end

local extend = table.extend
function UIStyleSheet:collectData( name, data )
	local data = data or {}
	for i, item in ipairs( self.items ) do
			if item:accept( name ) then
				for k,v in pairs( item.data ) do
					data[ k ] = v
				end
			end
	end
	return data
end

--------------------------------------------------------------------
CLASS: UIStyleRawItem ()
	:MODEL{}

local _itemIndex = 0
function UIStyleRawItem:__init( superStyle )
	_itemIndex = _itemIndex + 1
	self._index = _itemIndex
	self.qualifiers = {}
end

function UIStyleRawItem:setNamespace( ns )
	self.namespace = ns
end

local function parseStyleNamePart( n )
	local features = {}
	local featureSet = {}
	n = n:trim()
	local current = nil
	--parse tag
	local a, b, tag = n:find( '^%s*([%w]+)', current )
	if b then	current = b + 1	end
	
	local state0
	while true do
		--parse state
		local a, b, state = n:find( '^%s*:(%w+)', current)
		if state then
			if state0 then
				_warn( 'multiple state names found', n )
				return false
			end
			state0 = state
			current = b + 1
		end
		local a, b, feature = n:find( '^%s*%.(%w+)', current )
		if feature then
			current = b + 1
			feature = feature:lower()
			if not featureSet[ feature ] then
				featureSet[ feature ] = true
				table.insert( features, feature )	
			end
		elseif not state then
			break
		end
	end
	if not ( current and current >= #n ) then
		_warn( 'invalid style name> ', n )
		return false
	end

	table.sort( features )
	local pattern = ''
	local pass = false
	if tag then
		pattern = pattern .. tag
		pass = false
	else
		pattern = pattern .. '[^>]*'
		pass = true
	end

	if state0 then
		pattern = pattern .. ':' .. state0
		pass = false
	elseif not pass then
		pattern = pattern .. '[^>]*'
		pass = true
	end

	for i, f in ipairs( features ) do
		pattern = pattern .. '%.'..f
		pattern = pattern .. '[^>]*'
		pass = true
	end

	if not pass then
		pattern = pattern .. '[^>]*'
		pass = true
	end

	-- pattern = pattern .. '$'

	return {
		tag      = tag or false,
		state    = state0 or false,
		features = features,
		pattern  = pattern
	}
end

local function parseStyleName( n, ns )
	local path = {}
	n = n:trim()
	n = ( ns or '' ) .. n

	local pattern = false
	local parts = n:split( '>', true ) --child element
	for i, part in ipairs( parts ) do
		local data = parseStyleNamePart( part )
		if not data then 
			return false
		end
		path[ i ] = data
		if not pattern then
			pattern = data.pattern
		else
			pattern = pattern ..'>'..data.pattern
		end
	end

	-- print( n, '====>', pattern )
	
	return {
		path = path,
		pattern = pattern,
		finalPattern = pattern and ( '^' .. pattern .. '$' ) or false;
	}
end

function UIStyleRawItem:parseTarget( ... )
	local qualifiers = self.qualifiers
	for i, name in ipairs( {...} ) do
		local data = parseStyleName( name, self.namespace )
		if data then
			table.insert( qualifiers, data )
		end
	end
end

local match = string.match
function UIStyleRawItem:accept( name )
	for i, q in ipairs( self.qualifiers ) do
		local pattern = q.finalPattern
		if pattern then
			local matched = match( name, pattern ) and true or false			
			if matched then
				-- print( 'matched >>', pattern, name  )
				return true
			-- else
			-- 	print ( 'no match ..', pattern, name )
			end
		end
	end
	return false
end

function UIStyleRawItem:load( data )
	self.data = data
end

