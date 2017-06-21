module 'mock'


-- local UIStyleSheetRegistry = {}
-- local function findStyleSheet( query )
-- 	local result = false
-- 	--TODO
-- 	return result
-- end

local insert, remove = table.insert, table.remove
local match = string.match
--------------------------------------------------------------------

local function _compareStyleItemEntry( a, b )
	local qa = a[2]
	local qb = b[2]
	local na = qa.name
	local nb = qb.name
	if na ~= nb then
		local ma = nb:match( qa.finalPattern )
		local mb = na:match( qb.finalPattern )
		if ma ~= mb then
			if ma then return true end
			if mb then return false end
		end
		local as, bs = qa.state, qb.state
		if bs and not as then return true end
		if as and not bs then return false end
	end
	return a[1] < b[1]
end

--------------------------------------------------------------------
local _UIStyleLoaderEnv = {}

--value packing functions
function _UIStyleLoaderEnv.rgb( r,g,b )
	return { ( r or 255 ) / 255, ( g or 255 ) /255, ( b or 255 ) / 255 }
end

function _UIStyleLoaderEnv.rgba( r,g,b,a )
	return { ( r or 255 ) / 255, ( g or 255 ) /255, ( b or 255 ) / 255, ( a or 255 ) / 255 }
end

local function _loadUIStyleSheetSource( src, assetFinder )
	local items = {}
	local imports = {}
	local assets = {}
	local currentNamespace = ''
	local function importFunc( n )
		insert( imports, n )
	end

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

	local function assetFunc( name, assetTarget )
		local assetData = {}
		assetData.tag  = 'asset'
		assetData.name = name
		assetData.target = assetTarget or false
		insert( assets, assetData )
		return assetData
	end

	local function imageFunc( name )
		return assetFunc( name, 'image' )
	end

	local function image9Func( name )
		return assetFunc( name, 'image9' )
	end

	local function scriptFunc( src )
		local scriptData = {}
		scriptData.tag = 'script'
		scriptData.source = src
		return scriptData
	end

	local env = {
		import    = importFunc;
		style     = styleFunc;
		namespace = namespaceFunc;
		--
		asset     = assetFunc;
		image     = imageFunc;
		image9    = image9Func;
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

	return items, imports, assets
end

--------------------------------------------------------------------
CLASS: UIStyleSheet ()
	:MODEL{}

function UIStyleSheet:__init()
	self.assetPath = false
	self.maxPathSize = 0
	self.items = {}
	self.localCache = {}
	self.globalCache = {}
	self.importedSheets = {}
end

function UIStyleSheet:findAsset( name )
	if self.assetPath then
		--find siblings
		local basePath = dirname( self.assetPath )
		local siblingPath = basePath .. '/' .. name
		if hasAsset( siblingPath ) then
			return siblingPath
		end
		--try imported sheet
		for i, sheet in ipairs( self.importedSheets ) do
			local found = sheet:findAsset( name )
			if found then return found end
		end
	end
	return findAsset( name ) --asset library
end

function UIStyleSheet:solveAssetData( data )
	local name = data.name
	local target = data.target
	local assetPath = self:findAsset( name )
	if not assetPath then
		data.asset = false
		return false
	end
	if target == 'image' then --convert texture into deck
		if matchAssetType( assetPath, 'texture' ) then
			local deck = Quad2D()
			deck:setTexture( assetPath )
			local dw, dh = deck:getSize()
			deck:setOrigin( dw/2, dh/2 )
			deck:update()
			data.asset = AdHocAsset( deck )
		end
	elseif target == 'image9' then --conver texture into patch deck
		if matchAssetType( assetPath, 'texture' ) then
			local deck = StretchPatch()
			deck:setTexture( assetPath )
			local dw, dh = deck:getSize()
			deck:setOrigin( dw/2, dh/2 )
			deck:update()
			data.asset = AdHocAsset( deck )
		end
	else
		data.asset = assetPath
	end
	return true
end

function UIStyleSheet:load( src )
	local idx = 0
	local noTag = {}
	local taggedList = {}
	local maxPathSize = 0

	local function _addItem( item )
		item._index = idx
		idx = idx + 1
		for i, q in ipairs( item.qualifiers ) do
			local tag = q.tag or false
			local l
			if tag then
				l = taggedList[ tag ]
				if not l then
					l = {}
					taggedList[ tag ] = l
				end
			else
				l = noTag
			end
			insert( l, { idx, q, item } )
		end
	end

	local function _findAsset(...)
		--TODO
	end
	
	local items, imports, assets = _loadUIStyleSheetSource( src, _findAsset )
	if not items then
		self.items = {}
		return false
	end
	for i, item in ipairs( getBaseStyleSheet().items ) do
		_addItem( item )
	end
	maxPathSize = getBaseStyleSheet().maxPathSize

	local loaded = {}
	local importedSheets = {}
	for i, import in pairs( imports ) do
		--try local
		local path = self:findImport( import )
		if path then
			if isAssetLoading( path ) then
				_error( 'cyclic stylesheet imports detected', path )
				return false
			end
		else
			_error( 'cannot find stylesheet to import:', import )
			return false
		end
		if not loaded[ path ] then
			local sheet = loadAsset( path )
			if not sheet then
				_error( 'cannot import stylesheet', import, path )
				return false
			end
			loaded[ path ] = true
			importedSheets[ i ] = sheet
			maxPathSize = math.max( maxPathSize, sheet.maxPathSize )
			for i, item in ipairs( sheet.items ) do
				_addItem( item )
			end
		end
	end

	for i, item in ipairs( items ) do
		maxPathSize = math.max( maxPathSize, item.pathSize )
		_addItem( item )
	end

	--solve assets
	for i, assetData in ipairs( assets ) do
		self:solveAssetData( assetData )
	end

	table.sort( noTag, _compareStyleItemEntry )

	for t, list in pairs( taggedList ) do
		table.sort( list, _compareStyleItemEntry )
		for _, entry0 in ipairs( noTag ) do
			local p = entry0[2].finalPattern
			local inserted = false
			for i, entry1 in ipairs( list ) do
				if match( entry1[2].name, p ) then
					insert( list, i, entry0 )
					inserted = true
					break
				end
			end
			if not inserted then
				insert( list, entry0 )
			end
		end

		-- print()
		-- print( 'tag:', t )
		-- for i, entry in ipairs( list ) do
		-- 	print( i, entry[2].name, entry[1] )
		-- end
		
	end
	self.maxPathSize = maxPathSize
	self.items = items
	self.taggedList = taggedList
	self.importedSheets = importedSheets
	return true
end

function UIStyleSheet:findImport( name )
	if self.assetPath then
		--try local asset siblings first
		local path = dirname( self.assetPath ) .. '/' .. name
		local node = getAssetNode( path )
		if not node then
			path = path .. '.ui_style'
			node = getAssetNode( path )
		end
		if node then
			return node:getPath()
		end
	end
	local path = findAsset( name, 'ui_style' )
	if not path then return false end
	return path
end

function UIStyleSheet:loadFromAsset( node )
	local dataPath = node:getObjectFile( 'def' )
	self.assetPath = node:getPath()
	return self:loadFromFile( dataPath )
end

function UIStyleSheet:loadFromFile( path )
	local source = loadTextData( path )
	if source then
		return self:load( source )
	else
		return false
	end
end

function UIStyleSheet:query( acc )
	local globalCache = self.globalCache
	local queryList, fullQuery = acc:getQueryList()
	local data = globalCache[ fullQuery ]
	if not data then
		data = {}
		for i, query in ipairs( queryList ) do
			local result = self:_queryStyleData( unpack( query ) )
			for k, v in pairs( result ) do
				data[ k ] = v
			end
		end
		globalCache[ fullQuery ] = data
	end
	return data
end

function UIStyleSheet:_queryStyleData( tag, query )
	local localCache = self.localCache
	local data = localCache[ query ]
	if data then return data end
	local data = {}
	local taggedList = self.taggedList
	local l = taggedList[ tag ]
	if l then
		for i, entry in ipairs( l ) do
			local qualifier = entry[ 2 ]
			if match( query, qualifier.finalPattern ) then
				-- print( 'matched', query, qualifier.finalPattern )
				local item = entry[ 3 ]
				for k,v in pairs( item.data ) do
					data[ k ] = v
				end
			end
		end
	end
	
	localCache[ query ] = data
	return data
end

-- function UIStyleSheet:collectLocalData( name, data )
-- 	data = data or {}
-- 	local localData = self:getLocalData( name )
-- 	if localData then
-- 		for k, v in pairs( localData ) do
-- 			data[ k ] = v
-- 		end
-- 	end
-- 	return data
-- end

-- function UIStyleSheet:getLocalData( name )
-- 	local data = self.localCache[ name ]
-- 	if data then return data end
-- 	data = {}
-- 	for i, item in ipairs( self.items ) do
-- 		if item:accept( name ) then
-- 			for k,v in pairs( item.data ) do
-- 				data[ k ] = v
-- 			end
-- 		end
-- 	end
-- 	self.localCache[ name ] = data
-- 	return data
-- end

--------------------------------------------------------------------
CLASS: UIStyleRawItem ()
	:MODEL{}


function UIStyleRawItem:__init( superStyle )
	self._index = 0
	self.pathSize = 0
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
	local name = ''
	local pass = false
	if tag then
		name = name .. tag
		pattern = pattern .. tag
		pass = false
	else
		pattern = pattern .. '[^>]*'
		pass = true
	end

	if state0 then
		name = name .. ':' .. state0
		pattern = pattern .. ':' .. state0
		pass = false
	elseif not pass then
		pattern = pattern .. '[^>]*'
		pass = true
	end

	for i, f in ipairs( features ) do
		name = name ..'.'..f
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
		name     = name,
		pattern  = pattern
	}
end

local function parseStyleName( n, ns )
	local path = {}
	n = n:trim()
	n = ( ns or '' ) .. n
	local name    = false
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
			name    = data.name
		else
			pattern = pattern ..'>'..data.pattern
			name = name ..'>'..data.name
		end
	end

	-- print( n, '====>', pattern )
	
	return {
		tag  = path and path[ #path ].tag,
		state = path and path[ #path ].state,
		path = path,
		pathSize = #path,
		pattern = pattern,
		name    = name,
		finalPattern = pattern and ( '^' .. pattern .. '$' ) or false;
	}
end

function UIStyleRawItem:parseTarget( ... )
	local pathSize = 0
	local qualifiers = self.qualifiers
	for i, name in ipairs( {...} ) do
		local data = parseStyleName( name, self.namespace )
		if data then
			table.insert( qualifiers, data )
			pathSize = math.max( pathSize, data.pathSize )
		end
	end
	self.pathSize = pathSize
end

function UIStyleRawItem:load( data )
	self.data = data
end


--------------------------------------------------------------------
local function UIStyleSheetLoader( node )
	local sheet = UIStyleSheet()
	if sheet:loadFromAsset( node ) then
		return sheet
	else
		return false
	end
end

registerAssetLoader( 'ui_style', UIStyleSheetLoader )
