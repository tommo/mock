module 'mock'
--------------------------------------------------------------------
CLASS: SceneReferenceManager ( GlobalManager )
	:MODEL{}

function SceneReferenceManager:__init()
	_sceneReferenceManager = self
	self.references = {}
	self.referenceMap = {}
	self.dirty = true
end

function SceneReferenceManager:getKey()
	return 'scene_reference'
end

function SceneReferenceManager:saveConfig()
	local result = {}
	for i, ref in ipairs( self.references ) do
		result[ i ] = ref:saveData()
	end
	return result
end

function SceneReferenceManager:loadConfig( data )
	local references = {}
	for i, refData in ipairs( data ) do
		local ref = SceneReference()
		ref:loadData( refData )
		references[ i ] = ref
	end
	self.dirty = true
end

function SceneReferenceManager:affirmReferenceMap()
	if not self.dirty then return self.referenceMap end
	self.dirty = false
	local map = {}
	for i, ref in ipairs( self.references ) do
		map[ ref:getId() ] = ref
	end
	self.referenceMap = map
	return map
end

function SceneReferenceManager:addReference()
	local ref = SceneReference()
	table.insert( self.references, ref )
	self.referenceMap[ ref:getId() ] = ref
	self.dirty = true
	return ref
end

function SceneReferenceManager:removeReference( ref )
	local idx = table.index( self.references, ref )
	if idx then table.remove( self.references, idx ) end
	local map = self.referenceMap
	local id = ref:getId()
	if map[ id ] == ref then
		map[ id ] = nil
	end
end

function SceneReferenceManager:getReference( id )
	local map = self:affirmReferenceMap()	
	return map[ id ]
end


--------------------------------------------------------------------
local _sceneReferenceManager = SceneReferenceManager()
function getSceneReferenceManager()
	return _sceneReferenceManager
end



--------------------------------------------------------------------
CLASS: SceneReference ()
	:MODEL{
		Field 'id' :string();
		Field 'comment' :string();
		Field 'scene' :asset( 'scene' ) :getset( 'TargetScene');
		Field 'entityGuid' :string();
		Field 'entityName' :string();
	}

function SceneReference:__init()
	self.id = 'reference'
	self.comment = 'no comment'
	self.targetScenePath = false
	self.loc = { 0,0,0 }
	self.entityGuid = false
	self.entityName = false
end

function SceneReference:setLoc( x,y,z )
	self.loc = { x,y,z }
end

function SceneReference:getLoc()
	return unpack( self.loc )
end

function SceneReference:setTargetScene( path )
	self.targetScenePath = path
end

function SceneReference:getTargetScene()
	return self.targetScenePath
end

function SceneReference:saveData()
	return {
		id    = self.id,
		scene = self.targetScenePath,
		entityGuid = self.entityGuid, 
		entityName = self.entityName,
	}
end

function SceneReference:loadData( data )
	self.id = data[ 'id' ]
	self.entityGuid = data[ 'entityGuid' ]
	self.entityName = data[ 'entityName' ]
	self.targetScenePath = data[ 'scene' ] 
end
