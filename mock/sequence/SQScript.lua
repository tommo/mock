module 'mock'

local ccreate, cresume, cyield, cstatus
	= coroutine.create, coroutine.resume, coroutine.yield, coroutine.status
--------------------------------------------------------------------

CLASS: SQNode ()
CLASS: SQRoutine ()

CLASS: SQScript ()

CLASS: SQContext ()



--------------------------------------------------------------------
SQNode :MODEL{
		Field 'index'   :int();
		Field 'comment' :string();
		Field 'active'  :boolean();

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

function SQNode:addChild( node, idx )
	node.parentNode = self
	node.parentRoutine = self.parentRoutine
	if idx then
		table.insert( self.children, idx, node )
	else
		table.insert( self.children, node )
	end
	return node
end

function SQNode:removeChild( node )
	local idx = table.index( self.children, node )
	if not idx then return false end
	table.remove( self.children, idx )
	node.parentNode = false
	node.parentRoutine = false	
end

function SQNode:getName()
	return 'node'
end

function SQNode:getComment()
	return self.comment
end

function SQNode:setComment( c )
	self.comment = c
end

function SQNode:executeChildNodes( context, env )
	local children = self.children
	for i, child in ipairs( children ) do
		child:execute( context )
	end
	return true
end

function SQNode:execute( context ) --inside a coroutine
	-- print( 'execute node', self:getClassName() )
	local env = {}
	--node enter
	local resultEnter = self:enter( context, env )

	--node step
	if resultEnter ~= false then
		local dt = 0
		while true do
			local resultStep = self:step( context, env, dt )
			if resultStep then break end
			dt = cyield()
		end
	end

	--children
	self:executeChildNodes( context, env )

	--node exit
	return self:exit( context, env )
	
end


function SQNode:enter( context, env )
	return true
end

function SQNode:step( context, env, dt )
	return true
end

function SQNode:exit( context, env )
	return true
end

--------------------------------------------------------------------
SQRoutine :MODEL{
		Field 'name' :string();
		Field 'comment' :string();

		Field 'rootNode' :type( SQNode ) :no_edit();
		Field 'parentScript' :type( SQScript ) :no_edit();
}

function SQRoutine:__init()
	self.parentScript   = false

	self.rootNode = SQNode()	
	self.rootNode.parentRoutine = self

	self.name = ''
	self.comment = ''
end

function SQNode:getComment()
	return self.comment
end

function SQNode:setComment( c )
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

function SQRoutine:execute( context )
	return context:executeRoutine( self )
end


--------------------------------------------------------------------
SQScript :MODEL{
		Field 'comment';	
		Field 'routines' :array( SQRoutine ) :no_edit();
}

function SQScript:__init()
	self.routines = {}
	self.comment = ''
end

function SQScript:addRoutine( routine )
	local routine = routine or SQRoutine()
	routine.parentScript = self
	table.insert( self.routines, routine )
	return routine
end

function SQScript:removeRoutine( routine )
	local idx = table.index( self.routines, routine )
	if not idx then return end
	routine.parentRoutine = false
	table.remove( self.routines, idx )
end

function SQScript:_postLoad( data )
end

--------------------------------------------------------------------
SQContext :MODEL{
	
}

function SQContext:__init()
	self.currentScript = false
	self.running = false
	self.paused  = false

	self.coroutines = {}
	self.signalCounters = {}
end


function SQContext:isPaused()
	return self.paused
end

function SQContext:pause( paused )
	self.paused = paused ~= false
end

function SQContext:isRunning()
	return self.running
end

function SQContext:isDone()
	return not self.running
end

function SQContext:loadScript( script )
	self.running = true
	self.currentScript = script
	for i, routine in ipairs( script.routines ) do
		self:executeRoutine( routine )
	end
end

function SQContext:getSignalCounter( id )
	return self.signalCounters[ id ] or 0
end

function SQContext:incSignalCounter( id )
	local v = ( self.signalCounters[ id ] or 0 ) + 1
	self.signalCounters[ id ] = v
	return v
end

local function _SQConexteCoroutineFunc( context, routine )
	local dt = cyield()
	local node = routine:getRootNode()
	-- print( 'starting routine', context, routine )
	return node:execute( context )
end

function SQContext:executeRoutine( routine )
	local coroutines = self.coroutines
	local coro = ccreate( _SQConexteCoroutineFunc )
	coroutines[ routine ] = coro
	return cresume( coro, self, routine )
end

function SQContext:update( dt )
	if self.paused then return end
	local coroutines = self.coroutines
	local done = false
	for routine, coro in pairs( coroutines ) do
		local succ, result = cresume( coro, dt )
		if not succ then
			if not done then done = {} end
			done[ routine ] = true
			print( result )
			print( debug.traceback( coro ) )
			error( 'error in SQRoutine execution:' )
		elseif cstatus( coro ) == 'dead' then
			if not done then done = {} end
			done[ routine ] = true
		end
	end

	if done then
		for r in pairs( done ) do
			coroutines[ r ] = nil
		end
		if not next( coroutines ) then
			self.running = false
		end
	end
end

function SQContext:_actionInner()

end

--------------------------------------------------------------------
--------------------------------------------------------------------
function loadSQScriptFromRaw( data )
	local script = mock.deserialize( nil, data )
	script:_postLoad()
	return script
end

function loadSQScriptFromString( strData )
	local t = MOAIJsonParser.decode( strData )
	return loadSQScriptFromRaw( t )
end

function loadSQScript( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	return loadSQScriptFromRaw( data )
end


mock.registerAssetLoader( 'animator_data', loadSQScript )
