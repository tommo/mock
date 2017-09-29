module 'mock'

--[[
input
* object id
* model full name
* object name
]]

local insert = table.insert

--------------------------------------------------------------------
CLASS: AnimatorTargetId ()
	:MODEL{}
function AnimatorTargetId:get( entity, scene )
end

function AnimatorTargetId:serialize()
end

function AnimatorTargetId:deserialize( data )
end

function AnimatorTargetId:getTag()
	return 'unkown'
end

function AnimatorTargetId:toString()
	return '???'
end

function AnimatorTargetId:getSep()
	return '.'
end

function AnimatorTargetId:getTargetClass()
	return nil
end

--------------------------------------------------------------------
CLASS: AnimatorTargetPath ()
	:MODEL{}

function AnimatorTargetPath:__init()
	self.ids = {}
end

function AnimatorTargetPath:get( entity, scene )
	local found = entity
	scene = scene or ( entity and entity.scene )
	for i, targetId in ipairs( self.ids ) do
		found = targetId:get( found, scene )
		if not found then return false end
	end
	return found
end

function AnimatorTargetPath:match( entity, relativeTo )
	return self:get( relativeTo ) == entity
end

function AnimatorTargetPath:getTargetClass()
	local lastId = self.ids[ #self.ids ]
	if not lastId then return nil end
	return lastId:getTargetClass()
end

function AnimatorTargetPath:serialize()
	local data = {}
	for i, targetId in ipairs( self.ids ) do
		data[ i ] = {
			targetId:getTag(),
			targetId:serialize()
		}
	end
	return data
end

function AnimatorTargetPath:deserialize( data )
	local ids = {}
	for i, idData in ipairs( data ) do
		local tag = idData[ 1 ]
		local id
		if tag == 'com' then
			id = AnimatorComponentId()
		elseif tag == 'child' then
			id = AnimatorChildEntityId()
		elseif tag == 'global' then
			id = AnimatorGlobalEntityId()
		elseif tag == 'this' then
			id = AnimatorThisEntityId()
		end
		id:deserialize( idData[2] )
		ids[ i ] = id
	end
	self.ids = ids
end

function AnimatorTargetPath:appendId( id )
	insert( self.ids, id )
end

function AnimatorTargetPath:prependId( id )
	insert( self.ids, 1, id )
end

function AnimatorTargetPath:toString()
	local output = false
	for i, id in ipairs( self.ids ) do
		local part = id:toString()
		if output then
			local sep = id:getSep()
			output = output .. sep  .. part
		else
			output = part
		end
	end
	return output or '???'
end

--static
function AnimatorTargetPath.buildFor( obj, relativeTo )
	if isInstance( obj, Entity ) then
		return AnimatorTargetPath.buildForEntity( obj, relativeTo )
	elseif obj._entity then
		return AnimatorTargetPath.buildForComponent( obj, relativeTo )
	else
		error( 'invalid animator path target:'.. tostring( obj ) )
	end
end

function AnimatorTargetPath.buildForEntity( target, relativeTo )
	local path = AnimatorTargetPath()
	--if target is child of relative
	if target:isChildOf( relativeTo ) then --relative path
		local current = target
		while true do
			local id = AnimatorChildEntityId.buildForObject( current )
			path:prependId( id )
			current = current.parent
			if current == relativeTo then break end
		end
	elseif target == relativeTo then
		local id = AnimatorThisEntityId.buildForObject( target )
		path:prependId( id )
	else --absolute path
		local id = AnimatorGlobalEntityId.buildForObject( target )
		path:prependId( id )
	end

	return path
end

function AnimatorTargetPath.buildForComponent( com, relativeTo )
	local entity = com._entity
	local path = AnimatorTargetPath.buildForEntity( entity, relativeTo )
	local comId = AnimatorComponentId.buildForObject( com )
	path:appendId( comId )
	return path
end

--------------------------------------------------------------------
local function componentSortFunc( a, b )
	return ( a._AnimatorComponentId or 0 ) < ( b._AnimatorComponentId or 0 )
end

local function getComponentOfClass( entity, targetClas )
	local candidates = {}
	for com in pairs( entity.components ) do
		if com.__class == targetClas then
			insert( candidates, com )
		end
	end
	table.sort( candidates, componentSortFunc )
	return candidates
end

CLASS: AnimatorComponentId ( AnimatorTargetId )
	:MODEL{}
function AnimatorComponentId:__init() -- No. index of model
	self.targetClas = false
	self.index = 1
end

function AnimatorComponentId:get( entity, scene )
	local index = self.index
	local targetClas = self.targetClas
	local candidates = getComponentOfClass( entity, targetClas )
	return candidates[ index ]
end

function AnimatorComponentId:getTag()
	return 'com'
end

function AnimatorComponentId:getTargetClass()
	return self.targetClas
end

function AnimatorComponentId:serialize()
	return {
		clas = self.targetClas.__fullname,
		idx = self.index
	}
end

function AnimatorComponentId:deserialize( data )
	self.index = data.idx
	self.targetClas = getClassByName( data.clas )
end

function AnimatorComponentId.buildForObject( com )
	local entity = com._entity
	local comId = AnimatorComponentId()
	local targetClas = com.__class
	comId.targetClas = targetClas
	--determine com index
	local candidates = getComponentOfClass( entity, targetClas )

	local index = table.index( candidates, com )
	comId.index = index
	return comId
end

function AnimatorComponentId:toString()
	return self.targetClas and 
		( self.targetClas.__name .. '['.. self.index..']' ) or '???'
end

function AnimatorComponentId:getSep()
	return '\\'
end

--------------------------------------------------------------------
CLASS: AnimatorChildEntityId ( AnimatorTargetId )
	:MODEL{}

function AnimatorChildEntityId:__init()
	self.id         = false
	self.name       = false
	self.targetClas = false
end

function AnimatorChildEntityId:get( entity, scene )
	local id = self.id
	local targetClas = self.targetClas
	local name = self.name
	local candidates = {}
	for child in pairs( entity.children ) do
		if id and child.__guid == id then
			return child
		end
		if child.__class == targetClas and child.name == name then
			return child
		end
	end
	return false
end

function AnimatorChildEntityId:getTag()
	return 'child'
end

function AnimatorChildEntityId:getTargetClass()
	return self.targetClas
end

function AnimatorChildEntityId.buildForObject( obj )
	local id = AnimatorChildEntityId()
	id.id = obj.__guid
	id.targetClas = obj.__class
	id.name = obj:getName()
	return id
end

function AnimatorChildEntityId:serialize()
	return {
		id   = self.id,
		clas = self.targetClas.__fullname,
		name = self.name,
	}
end

function AnimatorChildEntityId:deserialize( data )
	self.id = data.id
	self.targetClas = getClassByName( data.clas )
	self.name = data.name
end

function AnimatorChildEntityId:toString()
	return self.name or ( self.targetClas and ( '<'..self.targetClas.__name..'>' ) ) or '???'
end


--------------------------------------------------------------------
CLASS: AnimatorThisEntityId( AnimatorChildEntityId )
function AnimatorThisEntityId:getTag()
	return 'this'
end

function AnimatorThisEntityId:get( entity, scene )
	return entity
end

function AnimatorThisEntityId:getTargetClass()
	return self.targetClas
end

function AnimatorThisEntityId.buildForObject( obj )
	local id = AnimatorThisEntityId()
	id.id = obj.__guid
	id.targetClas = obj.__class
	id.name = obj:getName()
	return id
end

function AnimatorThisEntityId:toString()
	return '<this>'
end


--------------------------------------------------------------------
CLASS: AnimatorGlobalEntityId ( AnimatorChildEntityId )
	:MODEL{}

function AnimatorGlobalEntityId:__init()
	self.id         = false
	self.name       = false
	self.targetClas = false
end

function AnimatorGlobalEntityId:getTag()
	return 'global'
end

function AnimatorGlobalEntityId:get( entity, scene )
	local id = self.id
	local targetClas = self.targetClas
	local name = self.name
	local candidate = false
	local topScore = 0	
	for entity in pairs( scene.entities ) do
		if entity.__guid == id then 
			return entity
		elseif entity:getName() == name then
			local score = 1
			if entity.__class == targetClas then
				score = score + 1
			end
			if score > topScore then
				topScore = score
				candidate = entity
			end
		end
	end
	
	return candidate
end

function AnimatorGlobalEntityId.buildForObject( obj )
	local id = AnimatorGlobalEntityId()
	id.id = obj.__guid
	id.targetClas = obj.__class
	id.name = obj:getName()
	return id
end

function AnimatorGlobalEntityId:serialize()
	return {
		id   = self.id,
		clas = self.targetClas.__fullname,
		name = self.name,
	}
end

function AnimatorGlobalEntityId:deserialize( data )
	self.id = data.id
	self.targetClas = assert( getClassByName( data.clas ) )
	self.name = data.name
end

function AnimatorGlobalEntityId:toString()
	return self.name or ( self.targetClas and ( '<'..self.targetClas.__name..'>' ) ) or '???'
end
