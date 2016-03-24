module 'mock'

--------------------------------------------------------------------
local function entitySortFunc( a, b )
	return  a._priority < b._priority
end

local function componentSortFunc( a, b )
	return ( a._componentID or 0 ) < ( b._componentID or 0 )
end


local function collectEntity( entity, objMap )
	if entity.FLAG_INTERNAL or entity.FLAG_EDITOR_OBJECT then return end
	local components = {}
	local children = {}

	for i, com in ipairs( entity:getSortedComponentList() ) do
		if not com.FLAG_INTERNAL then
			table.insert( components, objMap:map( com ) )
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

	return {
		id = objMap:map( entity ),
		components = components,
		children   = children
	}
end


--------------------------------------------------------------------
local function insertEntity( scene, parent, edata, objMap )
	local id = edata['id']
	local components = edata['components']
	local children   = edata['children']

	local entity = objMap[ id ][ 1 ]
	

	if scene then
		scene:addEntity( entity )
	elseif parent then
		parent:addChild( entity )
	end

	if components then
		--components
		for _, comId in ipairs( components ) do
			local com = objMap[ comId ][ 1 ]
			entity:attach( com )
		end
	end
	
	if children then
		--chilcren
		for i, childData in ipairs( children ) do
			insertEntity( nil, entity, childData, objMap )
		end
	end

	return entity
end

--------------------------------------------------------------------
--PREFAB
--------------------------------------------------------------------
function serializeEntityLegacy( obj )
	local objMap = SerializeObjectMap()
	for i, layer in ipairs( game:getLayers() ) do
		objMap:map( layer.name )
	end
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

function deserializeEntityLegacy( data )
	local objMap = {}
	local protoInstances = {}
	local map = data.map
	for id, objData in pairs( map ) do
		local protoPath = objData[ '__PROTO' ]
		if protoPath then
			protoInstances[ id ] = true
			local instance = createProtoInstance( protoPath )
			objmap[ id ] = {
				instance, objData
			}
		end
	end
	_deserializeObjectMap( map, objMap, protoInstances )
	return insertEntity( nil, nil, data.body, objMap )
end