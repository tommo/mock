module 'mock'

registerSignals{
	'scene.serialize',
	'scene.deserialize',
}

--------------------------------------------------------------------
local function entitySortFunc( a, b )
	return  a._priority < b._priority
end

--------------------------------------------------------------------
local function collectEntity( entity, objMap )
	if entity.FLAG_EDITOR_OBJECT then return end
	local coms = {}
	local children = {}

	if entity:getClass() == Entity then
		for com in pairs( entity.components ) do
			if not com.FLAG_EDITOR_OBJECT then
				table.insert( coms, objMap:map( com ) )
			end
		end

		local childrenList = {}
		local i = 1
		for e in pairs( entity.children ) do
			childrenList[i] = e
			i = i + 1
		end
		table.sort( childrenList, entitySortFunc )

		for i, child in ipairs( childrenList ) do
			local childData = collectEntity( child, objMap )
			if childData then
				table.insert( children, childData )
			end
		end
	end

	return {
		id = objMap:map( entity ),
		components = coms,
		children   = children
	}
end

--------------------------------------------------------------------
local function insertEntity( scn, parent, edata, objMap )
	local id = edata['id']
	local components = edata['components']
	local children   = edata['children']

	local entity = objMap[ id ][ 1 ]
	--components
	for _, comId in ipairs( components ) do
		local com = objMap[ comId ][ 1 ]
		entity:attach( com )
	end
	if scn then
		scn:addEntity( entity )
	elseif parent then
		parent:addChild( entity )
	end

	--chilcren
	for i, childData in ipairs( children ) do
		insertEntity( nil, entity, childData, objMap )
	end

	return entity
end


--------------------------------------------------------------------
function serializeScene( scene )
	emitSignal( 'scene.serialize', scene )
	local objMap = SerializeObjectMap()
	local entityList = {}
	for e in pairs( scene.entities ) do
		if not e.parent then --1st level entity
			table.insert( entityList, e )
		end
	end
	table.sort( entityList, entitySortFunc )

	local entities = {}
	for i, e in ipairs( entityList ) do
		local data = collectEntity( e, objMap )
		if data then table.insert( entities, data ) end
	end

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

	return {
		_assetType = 'scene',
		meta       = scene.metaData or {},
		map        = map,
		entities   = entities
	}
end

--------------------------------------------------------------------
function deserializeScene( data, scn )
	local objMap = {}
	_deserializeObjectMap( data.map, objMap )
	
	if not scn then
		scn = Scene()
		scn:enter()
	end

	for i, edata in ipairs( data.entities ) do
		insertEntity( scn, nil, edata, objMap )
	end
	scn.metaData = data['meta'] or {}

	emitSignal( 'scene.deserialize', scn )
	return scn
end

function serializeSceneToFile( scn, path )
	local data = serializeScene( scn )
	local str  = MOAIJsonParser.encode( data )
	local file = io.open( path, 'wb' )
	if file then
		file:write( str )
		file:close()
	else
		_error( 'can not write to scene file', path )
		return false
	end
	return true
end

--------------------------------------------------------------------
--PREFAB
--------------------------------------------------------------------
function serializeEntity( obj )
	local objMap = SerializeObjectMap()
	local data = collectEntity( obj, objMap )
	local map = {}
	while true do
		local newObjects = objMap:flush()
		if next( newObjects ) then
			for obj, id in pairs( newObjects )  do
				map[ id ] = _serializeObject( obj, objMap, 'noNewRef' )
			end
		else
			break
		end
	end
	return {				
		map    = map,
		body   = data
	}
end

function deserializeEntity( data )
	local objMap = {}
	_deserializeObjectMap( data.map, objMap )
	return insertEntity( nil, nil, data.body, objMap )
end

-------------------------------------------------------------------
local function sceneLoader( node, option )
	local data = loadAssetDataTable( node:getAbsFilePath() )
	local scn = option.scene or Scene()
	--configuration
	scn:enter()
	--entities
	deserializeScene( data, scn )
	return scn, false
end

registerAssetLoader( 'scene', sceneLoader )

