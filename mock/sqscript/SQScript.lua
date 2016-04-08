module 'mock'

local ccreate, cresume, cyield, cstatus
	= coroutine.create, coroutine.resume, coroutine.yield, coroutine.status

local insert, remove = table.insert, table.remove
--------------------------------------------------------------------

CLASS: SQNode ()
CLASS: SQRoutine ()
CLASS: SQScript ()

CLASS: SQState ()



--------------------------------------------------------------------
SQNode :MODEL{
		Field 'index'   :int() :no_edit(); 
		Field 'comment' :string() :no_edit(); 
		Field 'active'  :boolean() :no_edit(); 

		Field 'parentRoutine' :type( SQRoutine ) :no_edit();
		Field 'parentNode' :type( SQNode ) :no_edit();
		Field 'children'   :array( SQNode ) :no_edit();
}

function SQNode:__init()
	self.parentRoutine = false
	
	self.index      = 0
	self.active     = true
	self.parentNode = false
	self.children   = {}

	self.comment    = ''

	self.context    = false
	self.tag        = false

end

function SQNode:getRoot()
	return self.parentRoutine:getRootNode()
end

function SQNode:getChildren()
	return self.children
end

function SQNode:getParent()
	return self.parentNode
end

function SQNode:getNextSibling()
	local p = self.parentNode
	local siblings = p and p.children
	return siblings[ self.index + 1 ]
end

function SQNode:getRoutine()
	return self.parentRoutine
end

function SQNode:isGroup()
	return false
end

function SQNode:canInsert()
	return false
end

function SQNode:isBuiltin()
	return false
end

function SQNode:initFromEditor()
end

function SQNode:addChild( node, idx )
	node.parentNode = self
	node.parentRoutine = self.parentRoutine
	if idx then
		insert( self.children, idx, node )
	else
		insert( self.children, node )
	end
	return node
end

function SQNode:indexOfChild( node )
	return table.index( self.children, node )
end

function SQNode:removeChild( node )
	local idx = table.index( self.children, node )
	if not idx then return false end
	remove( self.children, idx )
	node.parentNode = false
	node.parentRoutine = false	
	return true
end

function SQNode:getName()
	return 'node'
end

function SQNode:getComment()
	return self.comment
end

function SQNode:getRichText()
	return 'SQNode'
end

function SQNode:getIcon()
	return false
end

function SQNode:setComment( c )
	self.comment = c
end

function SQNode:enter( state, env )
	return true
end

function SQNode:step( state, env, dt )
	return true
end

function SQNode:exit( state, env )
	return true
end

function SQNode:_load( data )
	self.srcData = data
	self:load( data )
end

function SQNode:load( data )
end

function SQNode:_build()
	self:build()
	for i, child in ipairs( self.children ) do
		child.index = i
		child:_build()
	end
end

function SQNode:build()
end

function SQNode:acceptSubNode( name )
	return true
end

--------------------------------------------------------------------
CLASS: SQNodeGroup ( SQNode )
	:MODEL{
		Field 'name' :string();
}

function SQNodeGroup:__init()
	self.name = 'group'
end

function SQNodeGroup:isGroup()
	return true
end

function SQNodeGroup:canInsert()
	return true
end


function SQNodeGroup:getRichText()
	return string.format(
		'[ <group>%s</group> ]',
		self.name
		)
end

function SQNodeGroup:getIcon()
	return 'sq_node_group'
end


--------------------------------------------------------------------
CLASS: SQNodeLabel( SQNode )
	:MODEL{
		Field 'id' :string();
}

function SQNodeLabel:__init()
	self.id = 'label'
end

function SQNodeLabel:getRichText()
	return string.format(
		'<label>%s</label>',
		self.id
		)
end

function SQNodeLabel:getIcon()
	return 'sq_node_label'
end

function SQNodeLabel:build()
	local routine = self:getRoutine()
	insert( routine.labelNodes, self )
end


--------------------------------------------------------------------
CLASS: SQNodeGoto( SQNode )
	:MODEL {
		Field 'label' :string();
}

function SQNodeGoto:__init()
	self.label = 'label'
end

function SQNodeGoto:load( data )
	self.label = data.args[1]
end

function SQNodeGoto:enter( state, env )
	local routine = self:getRoutine()
	local targetNode = routine:findLabelNode( self.label )
	if not targetNode then
		_warn( 'target label not found', self.label )
		state:setJumpTarget( false )
	else
		state:setJumpTarget( targetNode )
	end
	return 'jump'
end

function SQNodeGoto:getRichText()
	return string.format(
		'<cmd>GOTO</cmd> <label>%s</label>',
		self.label
		)
end

function SQNodeGoto:getIcon()
	return 'sq_node_goto'
end



---------------------------------------------------------------------
CLASS: SQNodeEnd( SQNode )
	:MODEL{
		Field 'stopAllRoutines' :boolean()
}

function SQNodeEnd:__init()
	self.stopAllRoutines = false
end

function SQNodeEnd:enter( state )
	if self.stopAllRoutines then
		state:stop()
		return 'jump'
	else
		state._jumpTargetNode = false --jump to end
		return 'jump'
	end
end

function SQNodeEnd:getRichText()
	return string.format(
		'<end>END</end> <flag>%s</flag>',
		self.stopAllRoutines and 'All Routines' or ''
		)
end

function SQNodeEnd:getIcon()
	return 'sq_node_end'
end


--------------------------------------------------------------------
CLASS: SQNodeRoot( SQNodeGroup )



--------------------------------------------------------------------
SQRoutine :MODEL{
		Field 'name' :string();
		Field 'autoStart' :boolean();
		Field 'comment' :string();
		Field 'rootNode' :type( SQNode ) :no_edit();
		Field 'parentScript' :type( SQScript ) :no_edit();
}

function SQRoutine:__init()
	self.parentScript   = false

	self.rootNode = SQNodeRoot()	
	self.rootNode.parentRoutine = self
	self.autoStart = false

	self.name = 'unnamed'
	self.comment = ''

	self.labelNodes = {}
end

function SQRoutine:findLabelNode( id )
	for i, node in ipairs( self.labelNodes ) do
		if node.id == id then return node end
	end
	return nil
end

function SQRoutine:getName()
	return self.name
end

function SQRoutine:setName( name )
	self.name = name
end

function SQRoutine:getComment()
	return self.comment
end

function SQRoutine:setComment( c )
	self.comment = c
end

function SQRoutine:getRootNode()
	return self.rootNode
end

function SQRoutine:addNode( node, idx )
	return self.rootNode:addChild( node, idx )
end

function SQRoutine:removeNode( node )
	return self.rootNode:removeChild( node )
end

function SQRoutine:execute( state )
	return state:executeRoutine( self )
end

function SQRoutine:build()
	self.rootNode:_build()
end


--------------------------------------------------------------------
SQScript :MODEL{
		Field 'comment';	
		Field 'routines' :array( SQRoutine ) :no_edit();
}

function SQScript:__init()
	self.routines = {}
	self.comment = ''
	self.built = false
end

function SQScript:addRoutine( routine )
	local routine = routine or SQRoutine()
	routine.parentScript = self
	insert( self.routines, routine )
	return routine
end

function SQScript:removeRoutine( routine )
	local idx = table.index( self.routines, routine )
	if not idx then return end
	routine.parentRoutine = false
	remove( self.routines, idx )
end

function SQScript:getRoutines()
	return self.routines
end

function SQScript:getComment()
	return self.comment
end

function SQScript:_postLoad( data )
end

function SQScript:build()
	if self.built then return true end
	self.built = true
	for i, routine in ipairs( self.routines ) do
		routine:build()
	end
	return true
end


--------------------------------------------------------------------
CLASS: SQRoutineState ()
 
function SQRoutineState:__init( state, routine )
	self.parentState = state
	self.routine = routine
	self.running = false
	self.started = false
	self.jumpTarget = false

	self.currentParentNode = false
	self.currentNode = false
	self.currentNodeEnv = false

	local rootNode = routine:getRootNode()
	self.currentNode  = rootNode
	self.currentQueue = {}
	self.index = 1

	self.nodeEnvMap = {}
end

function SQRoutineState:start()
	if self.started then return end
	self.started = true
	self.running = true
	self.parentState.running = true
end

function SQRoutineState:stop()
	if self.running then
		self.running = false
	end
end

function SQRoutineState:reset()
	self.started = false
	self.running = false
	self.jumpTarget = false
	self.nodeEnvMap = {}
	self.currentParentNode = false
	self.currentNodeEnv = false
	self.currentNode = self.routine:getRootNode()
end

function SQRoutineState:restart()
	self:reset()
	self:start()
end

function SQRoutineState:getSignalCounter( id )
	return self.parentState:getSignalCounter( id )
end

function SQRoutineState:incSignalCounter( id )
	return self.parentState:incSignalCounter( id )
end

function SQRoutineState:getEnv( key, default )
	return self.parentState:getEnv( key, default )
end

function SQRoutineState:setEnv( key, value )
	return self.parentState:setEnv( key, value )
end


function SQRoutineState:update( dt )
	if not self.running then return end
	self:updateNode( dt )
end

function SQRoutineState:updateNode( dt )
	local node = self.currentNode
	if node then
		local env = self.currentNodeEnv
		local res = node:step( self, env, dt )
		if res then
			if res == 'jump' then
				return self:doJump()
			end
			return self:exitNode()
		end
	else
		return self:nextNode()
	end
end

function SQRoutineState:nextNode()
	local index1 = self.index + 1
	local node1 = self.currentQueue[ index1 ]
	if not node1 then
		return self:exitGroup()
	end
	self.index = index1
	self.currentNode = node1
	local env = {}
	self.currentNodeEnv = env
	local res = node1:enter( self, env )
	if res == 'jump' then
		return self:doJump()
	end
	if res == false then
		return self:nextNode()
	end
	return self:updateNode( 0 )
end

function SQRoutineState:exitNode( fromGroup )
	local node = self.currentNode
	if node:isGroup() then --Enter group
		self.nodeEnvMap[ node ] = self.currentNodeEnv
		self.index = 0
		self.currentQueue = node.children
	else
		local res = node:exit( self, self.currentNodeEnv )
		if res == 'jump' then
			return self:doJump()
		end
	end
	return self:nextNode()
end

function SQRoutineState:exitGroup()
	--exit group node
	local groupNode = self.currentNode.parentNode
	local env = self.nodeEnvMap[ groupNode ] or {}
	local res = groupNode:exit( self, env )
	if res == 'jump' then
		return self:doJump()
	elseif res == 'loop' then
		--Loop
		self.index = 0
	else
		local parent = groupNode.parentNode
		if not parent then 
			self.running = false
			return true
		end
		self.currentQueue = parent.children
		self.index = groupNode.index
	end
	return self:nextNode()
end

function SQRoutineState:setJumpTarget( node )
	self.jumpTarget = node
end

function SQRoutineState:doJump()
	local target = self.jumpTarget
	if not target then
		self.running = false
		return false
	end

	self.jumpTarget = false
	local parentNode = target.parentNode
	self.currentQueue = parentNode.children
	self.index = target.index - 1
	return self:nextNode()
	
end

--------------------------------------------------------------------
SQState :MODEL{
	
}

function SQState:__init()
	self.currentScript = false
	self.running = false
	self.paused  = false

	self.routineStates = {}
	self.coroutines = {}
	self.signalCounters = {}
	self.env = {}
end

function SQState:getEnv( key, default )
	local v = self.env[ key ]
	if v == nil then return default end
	return v
end

function SQState:setEnv( key, value )
	self.env[ key ] = value
end

function SQState:getSignalCounter( id )
	return self.signalCounters[ id ] or 0
end

function SQState:incSignalCounter( id )
	local v = ( self.signalCounters[ id ] or 0 ) + 1
	self.signalCounters[ id ] = v
	return v
end


function SQState:isPaused()
	return self.paused
end

function SQState:pause( paused )
	self.paused = paused ~= false
end

function SQState:isRunning()
	return self.running
end

function SQState:isDone()
	return not self.running
end

function SQState:stop()
	self.running = false
end

function SQState:loadScript( script )
	script:build()
	self.currentScript = script
	for i, routine in ipairs( script.routines ) do
		local routineState = SQRoutineState( self, routine )
		insert( self.routineStates, routineState )
		if routine.autoStart then
			routineState:start()
		end
	end
	self.running = true
end

function SQState:update( dt )
	if not self.running then return end
	if self.paused then return end
	local running = false
	for i, routineState in ipairs( self.routineStates ) do
		running = running or routineState.running
		routineState:update( dt )
	end
	if not running then self.running = false end
end

function SQState:findRoutineState( name )
	for i, routineState in ipairs( self.routineStates ) do
		if routineState.routine.name == name then return routineState end
	end
	return nil
end

function SQState:stopRoutine( name )
	local rc = self:findRoutineState( name )
	if rc then
		rc:stop()
		return true
	end
end

function SQState:startRoutine( name )
	local rc = self:findRoutineState( name )
	if rc then
		rc:start()
		return true
	end
end

function SQState:restartRoutine( name )
	local rc = self:findRoutineState( name )
	if rc then
		rc:restart()
		return true
	end
end

function SQState:isRoutineRunning( name )
	local rc = self:findRoutineState( name )
	if rc then 
		return rc.running
	end
	return nil
end

function SQState:startAllRoutines()
	for i, routineState in ipairs( self.routineStates ) do
		if not routineState.started then
			routineState:start()
		end
	end
	return true
end

--------------------------------------------------------------------
local SQNodeRegistry = {}
local defaultOptions = {}
function registerSQNode( name, clas, options )
	options = options or {}
	local entry0 = SQNodeRegistry[ name ]
	if entry0 then
		_warn( 'duplicated SQNode:', name )
	end
	SQNodeRegistry[ name ] = {
		clas     = clas,
		comment  = options[ 'comment' ] or ''
	}
end

function findInSQNodeRegistry( name )
	return SQNodeRegistry[ name ]
end

function getSQNodeRegistry()
	return SQNodeRegistry
end



--------------------------------------------------------------------
local function loadSQNode( data, parentNode )
	local node
	local t = data.type
	print( t, node )
	if t == 'context' then
		--TODO: context inference
		return false

	elseif t == 'tag'     then
		--TODO: tag inference
		return false

	elseif t == 'label'   then
		local labelNode = SQNodeLabel()
		labelNode.id = data.id
		return labelNode

	elseif t == 'action' then
		--find action node factory
		local actionName = data.name
		local entry = SQNodeRegistry[ actionName ]
		if not entry then
			_error( 'unkown action node type', actionName )
			return SQNode() --dummy node
		end
		local clas = entry.clas
		node = clas()
		node:load( data )

	elseif t == 'root' then
		--pass
		node = parentNode

	else
		--error
		error( 'wtf?', t )
	end

	for i, childData in ipairs( data.children ) do
		local childNode = loadSQNode( childData, childNode )
		if childNode then
			node:addChild( childNode )
		end
	end

	return node

end

--------------------------------------------------------------------
function loadSQScript( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	local script = SQScript()
	local routine = script:addRoutine()
	routine.autoStart = true
	loadSQNode( data, routine.rootNode )
	script:build()
	return script
	-- local script = mock.deserialize( nil, data )
	-- script:_postLoad()
	-- script:build()
	-- return script
end

--------------------------------------------------------------------
registerSQNode( 'group', SQNodeGroup )
-- registerSQNode( 'label', SQNodeLabel )
registerSQNode( 'end',   SQNodeEnd   )
registerSQNode( 'goto',  SQNodeGoto  )

mock.registerAssetLoader( 'sq_script', loadSQScript )
