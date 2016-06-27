--------------------------------------------------------------------
--[[
	Behavior Tree implementation by Tommo.zhou
	Note:
		* structure = (multiple CONTEXT Instances) -> (single Tree Instance)
		* the implementaion heavily relies on tail-recursive feature of Lua
		* the concurrent selector code might be a little messy...

]]
--------------------------------------------------------------------
local remove, insert = table.remove, table.insert
local ipairs, pairs = ipairs, pairs

module 'mock'
--------------------------------------------------------------------
local function _randInteger( k ) 
	 return math.floor( math.random() * k ) + 1
end

local function makeShuffleList( range )
	local t = {}
	for i = 1, range do
		t[i] = i
	end
	for i = range, 2, -1 do
		local k = _randInteger( i )
		t[ k ], t[ i ] = t[ i ], t[ k ]
	end
	return t
end

--------------------------------------------------------------------
local ActionRegistry = {}
function getActionRegistry() 
	return ActionRegistry
end

function getActionClass( id )
	return ActionRegistry[ id ]
end

function registerActionClass( id, class )
	if ActionRegistry[ id ] then
		_warn( 'duplicated action class', id )
	end
	ActionRegistry[ id ] = class
end

--------------------------------------------------------------------
---Action ( base class for userdefined object behavior )
--------------------------------------------------------------------
CLASS: BTAction ()

--------------------------------------------------------------------
BTAction.serialize = false
BTAction.start = false
BTAction.stop = false

--class function
function BTAction.register( thisClas, id )
	registerActionClass( id, thisClas )
	return thisClas
end

--class function
function BTAction:step( dt )
	--pass
	return 'ok'
end

function BTAction:getBTNode()
	return self._BTNode
end

function BTAction:getArgumentTable()
	return self._BTNode.arguments
end

function BTAction:getArgN( k, default )
	return tonumber( self:getArg( k, nil ) ) or default or 0
end

function BTAction:getArgB( k, default )
	local v = self:getArg( k, nil )
	if v == nil then return default and true or false end
	if v == 'false' then return false end
	return true
end

function BTAction:getArg( k, default )
	local args = self._BTNode.arguments
	local v = args and args[ k ] or nil
	return v == nil and default or v
end

--------------------------------------------------------------------
local DUMMYAction = BTAction()
--------------------------------------------------------------------
-- BTContext: used as a component
CLASS: BTContext ()

function BTContext:__init( owner )
	self._actionTable  = {}
	self._runningQueue = {}
	self._runningQueueNeedShrink = false
	self._active        = true
	self._activeActions = table.weak_v()
	self._conditions    = {}
	self._params        = {}
	self._owner         = owner or false
	self._nodeContext   = {}
end

function BTContext:getOwner()
	return self._owner
end

function BTContext:getOwnerEntity()
	local owner =  self._owner
	return owner and owner:getEntity()
end

function BTContext:getController()
	return self._owner
end

function BTContext:getControllerEntity()
	return self._owner:getEntity()
end

function BTContext:validateTree( tree )
	return tree.root:validate( self )
end

function BTContext:executeTree( tree )
	self._conditionDirty = false
	tree.root:execute( self )
end

function BTContext:buildDebugInfo()
	local _activeActions = self._activeActions
	local _runningQueue = self._runningQueue
	local out = ''
	for i, node in pairs( _runningQueue ) do
		local action = _activeActions[ node ]
		if action then
			out = out .. string.format( '%s:%s\n', node.name, node.actionName or '<NIL>' )
		end
	end
	return out
end

---------
function BTContext:setActionTable( actions )
	if not actions then error( 'action table expected', 2 ) end
	self._actionTable = actions
end

function BTContext:requestAction( actionNode )
	local _activeActions = self._activeActions
	local action = _activeActions[ actionNode ]
	--TODO: should we recreate action every time??
	if action then return action end

	local name = actionNode.actionName
	local actionClas = self._actionTable[ name ]
	if not actionClas then
		actionClas = ActionRegistry[ name ]
	end
	local action
	if actionClas then
		action = actionClas()	
	end
	if not action then
		_warn( 'invalid action class:'..name )
		action = DUMMYAction
	end
	self._activeActions[ actionNode ] = action
	action._BTNode = actionNode
	return action
end

function BTContext:getParam( key, default )
	local v = self._params[ key ]
	if v == nil then return default end
	return v
end

function BTContext:setParam( key, value )
	self._params[ key ] = value
end

function BTContext:setConditionTable( t )
	self._conditions = t
end

function BTContext:getConditionTable()
	return self._conditions
end

function BTContext:getCondition( name )
	return self._conditions[ name ]
end

function BTContext:setCondition( name, v )
	self._conditions[ name ] = v
	self._conditionDirty = true
end

function BTContext:completeEvaluation( res )
	--TODO: delegate?
	self._runningQueue = {}
	self._nodeContext  = {}
	return 'complete'
end

function BTContext:updateRunningNodes( dt )
	local _runningQueue = self._runningQueue
	local count = #_runningQueue
	if count == 0 then return false end

	for i = 1, count do 
		--only execute currently available nodes, new nodes left to next update
		local node = _runningQueue[ i ]
		if node then --might have already removed
			if node:update( self, dt ) == 'complete' then return 'complete' end
		end
	end

	--shrink running queue?

	if self._runningQueueNeedShrink then
		local newQueue = {}
		-- local j = 1
		for i, node in ipairs( _runningQueue ) do
			if node then insert( newQueue, node ) end
			-- if node then newQueue[ j ] = node ; j = j + 1 end
		end
		self._runningQueue = newQueue
	end

	return true
end

function BTContext:addRunningNode( n )
	return insert( self._runningQueue, n )
end

function BTContext:removeRunningChildNodes( parentNode )
	self._runningQueueNeedShrink = true
	local _runningQueue  = self._runningQueue
	local _activeActions = self._activeActions

	for i, node in ipairs( _runningQueue ) do
		if node and node:hasParent( parentNode ) then
			--stop this & exclude this in new queue
			--TODO: stop the nodes in reversed order?
			local action = _activeActions[ node ]
			if action then
				local stop   = action.stop
				if stop then stop( action, self ) end
			end
			_runningQueue[ i ] = false --remove later
		end		
	end

end

function BTContext:removeRunningNode( nodeToRemove )
	-- print( 'remove running node', nodeToRemove:getClassName(), nodeToRemove.actionName  )
	self._runningQueueNeedShrink = true
	local _activeActions = self._activeActions
	local _runningQueue = self._runningQueue

	--just remove one node
	for i, node in ipairs( _runningQueue ) do
		if node == nodeToRemove then
			_runningQueue[ i ] = false
			return node:stop( self )
			-- _activeActions[ nodeToRemove ] = nil
		end
	end
	_warn( 'bt node not removed', nodeToRemove:getClassName(), nodeToRemove.name )
end

function BTContext:clearRunningNode()
	for i, node in ipairs( self._runningQueue ) do
		if node then
			node:stop( self )
		end
	end
	self._runningQueue  = {}
	self._activeActions = {}
end

function BTContext:resetRunningState()
	self:clearRunningNode()
	self._nodeContext = {}
end

function BTContext:saveState()
	--TODO:...
end

function BTContext:loadState( data )
	--TODO:...
end

--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: BehaviorTree ()
function BehaviorTree:__init()
	self.root = BTRootNode()
end

local function loadNode( data )	
	local nodeType, value, children = data.type, data.value, data.children
	if nodeType == 'commented' then 
		return false --ignore
	end
	local class = assert( BehaviorTreeNodeTypes[ nodeType ], 'unknown node type:'..tostring(nodeType) )
	local node = class()
	if nodeType == 'condition' or nodeType == 'condition_not' then
		if value:sub( -2, -1 ) == '()' then
			node.conditionName = value:sub( 1, -3 )
			node.conditionType = 'call'
		else
			node.conditionName = value
			node.conditionType = 'field'
		end

	elseif nodeType == 'action' then
		node.actionName = value
		node.arguments  = data.arguments or false

	elseif nodeType == 'msg' then
		node.msg = value
		node.arguments = data.arguments or false

	elseif nodeType == 'log' then
		node.logText = value

	elseif nodeType == 'decorator_for' then
		local args = data.arguments
		if args then
			node:setRange( args['min'], args['max'] )
		else
			node:setRange( 1 )
		end

	elseif nodeType == 'decorator_prob' or nodeType == 'decorator_weight' then
		local args = data.arguments
		node:setValue( args[ 'value' ] )
		
	end
	if children then
		for i, childData in ipairs( children ) do
			if not childData.commented then
				local childNode = loadNode( childData )
				if childNode then	node:addNode( childNode ) end
			end
		end
	end

	return node
end

function BehaviorTree:load( data )
	self.root = loadNode( data )
	self.root:validate()
	self.root:postLoad()
	return self
end


--------------------------------------------------------------------
--BTNode: base class of behavior tree nodes
--@ execute( context )  reimplement this for specific behavior
--------------------------------------------------------------------
CLASS: BTNode ()
function BTNode:__init()
	self.name = 'BTNode'
	self.parentNode = false
	self.depth = 0 --depth in tree
end

function BTNode:execute( context )
	error('not implemented execute in :'..self:getType())
end

function BTNode:validate( context )
	return true
end

function BTNode:postLoad()
	return true
end

function BTNode:stop( context )
	return true
end

function BTNode:getType() --for debug purpose
	return 'BTNode'
end

function BTNode:addNode( n )
	error( 'no subnode or targetnode support for '..self:getType(),2)
end


BTNode.cancel = false

function BTNode:hasParent( node )
	if node.depth > self.depth then return false end
	local p = self.parentNode
	while p do
		if p == node then return true end
		p = p.parentNode
	end
	return false
end

function BTNode:returnUpLevel( res, context )
	return self.parentNode:resumeFromChild( self, res, context )
end

function BTNode:resumeFromChild( child, res, context )
	return self:returnUpLevel( res, context )
end


--------------------------------------------------------------------
--Action Node in behavior tree, can have 'running' state
--------------------------------------------------------------------
CLASS: BTActionNode ( BTNode )
function BTActionNode:__init( name )
	self.actionName = name
	self.arguments  = false
end

function BTActionNode:getType()
	return 'Action'
end

function BTActionNode:execute( context )
	local act = context:requestAction( self )
	local start = act.start
	if start then 
		local res = start( act, context, self )
		if res == 'ok' or res == 'fail' then
			return self:returnUpLevel( res, context )
		end
	end
	return self:update( context, 0, true )
end

function BTActionNode:update( context, dt, fromExecute )
	local act = context._activeActions[ self ]
	local res = act:step( context, dt, self )	
	assert ( 
		res == 'ok' or res == 'fail' or res=='running', 
		string.format('invalid action return value inside %s: %s', self.actionName, tostring( res ) )
		)
	if res == 'running' then
		if fromExecute then
			--first time we run the update, put it in queue
			context:addRunningNode( self )
		end
		return 'running'
	else
		--fail or ok
		if fromExecute then
			--not in queue yet, just stop
			self:stop( context )
		else
			context:removeRunningNode( self )
		end
		return self:returnUpLevel( res, context )
	end
end

function BTActionNode:returnUpLevel( res, context )		
	return self.parentNode:resumeFromChild( self, res, context )
end

function BTActionNode:stop( context )
	local act = context._activeActions[ self ]
	local stop = act.stop
	if stop then stop( act, context, self ) end
end

function BTActionNode:validate( context )
	if not context then return true end
	assert( context:requestAction( self ), 'action not registered for:'..self.actionName )
end

--------------------------------------------------------------------
CLASS: BTLoggingNode ( BTNode )
	:MODEL{}

function BTLoggingNode:__init( name )
	self.logText = name
end

function BTLoggingNode:getType()
	return 'Log'
end

function BTLoggingNode:execute( context )
	print( self.logText )
	return self:returnUpLevel( 'ignore', context )
end

--------------------------------------------------------------------
CLASS: BTMsgSendingNode ( BTNode )
	:MODEL{}

function BTMsgSendingNode:__init()
	self.msg = false
end

function BTMsgSendingNode:getType()
	return 'Msg'
end

function BTMsgSendingNode:execute( context )
	--TODO: arguments
	context:getControllerEntity():tell( self.msg, self, self )
	return self:returnUpLevel( 'ignore', context )
end

--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: BTCondition ( BTNode )
function BTCondition:__init( conditionName )
	self.conditionName = conditionName
end

function BTCondition:getType()
	return 'Condition'
end

function BTCondition:setCondition( name )
	self.conditionName = name
end

function BTCondition:addNode( node )
	--single child node
	assert( not self.targetNode, 'condtion node can only have ONE target node.' )
	self.targetNode = node
	node.parentNode = self
	node.depth = self.depth + 1
	return node
end

function BTCondition:execute( context )
	local res = context:getCondition( self.conditionName )
	if res then
		local target = self.targetNode
		if target then --condition node can link a child node
			return target:execute( context )
		else
			return self:returnUpLevel( 'ok', context )
		end
	else
		return self:returnUpLevel( 'fail', context )
	end
end

function BTCondition:resumeFromChild( child, res, context )
	return self:returnUpLevel( res, context )
end

function BTCondition:validate( context )
	if self.targetNode then return self.targetNode:validate( context ) end
	return true
end

--------------------------------------------------------------------
CLASS: BTConditionNot ( BTCondition )
function BTConditionNot:getType()
	return 'ConditionNot'
end

function BTConditionNot:execute( context )
	local res = context:getCondition( self.conditionName )
	if not res then
		local target = self.targetNode
		if target then --condition node can link a child node
			return target:execute( context )
		else
			return self:returnUpLevel( 'ok', context )
		end
	else
		return self:returnUpLevel( 'fail', context )
	end
end

--------------------------------------------------------------------
--COMPOSITION
--------------------------------------------------------------------
--base class of composition nodes such as priority / sequence/ concurrent
--------------------------------------------------------------------
CLASS: BTCompositedNode ( BTNode )
function BTCompositedNode:__init( name )
	self.children = {}
	self.childrenCount = 0
	self.name = name
end

function BTCompositedNode:getType() --for debug purpose
	return 'BTCompositedNode'
end

function BTCompositedNode:resumeFromChild( node, result, context )
	error ('implement resumeFromChild !!')
end

--The tree must be constructed from top down,  to ensure right depth value
function BTCompositedNode:validate( context )
	for i, nn in ipairs( self.children ) do
		if not nn:validate( context ) then return false end
	end
	return true
end

function BTCompositedNode:postLoad( context )
	for i, nn in ipairs( self.children ) do
		if not nn:postLoad( context ) then return false end
	end
	return true
end

function BTCompositedNode:addNode( node )
	node.parentNode = self
	node.depth = self.depth + 1
	insert( self.children, node )
	self.childrenCount = #self.children
	return node
end

function BTCompositedNode:removeNode( node ) --might be useful for editor?
	node.parentNode = false
	local children = self.children
	for i, nn in ipairs( children ) do
		if nn == node then
			remove( children, i )
			self.childrenCount = #children
			break
		end
	end
	return node
end

--------------------------------------------------------------------
--------------------------------------------------------------------
CLASS: BTPrioritySelector ( BTCompositedNode )
function BTPrioritySelector:getType()
	return 'BTPrioritySelector'
end

function BTPrioritySelector:execute( context )
	local nodeContext = context._nodeContext
	local index = nodeContext[ self ] or 1
	local child = self.children[ index ]
	if not child then
		nodeContext[ self ] = false
		return self:returnUpLevel( 'fail', context )
	end
	--run child node
	nodeContext[ self ] = index + 1
	return child:execute( context )
end

function BTPrioritySelector:resumeFromChild( child, res, context )
	if res == 'ok' then  --done
		context._nodeContext[ self ] = false
		return self:returnUpLevel( 'ok', context )
	end 
	return self:execute( context )
end


--------------------------------------------------------------------
CLASS: BTRootNode ( BTPrioritySelector )
function BTRootNode:getType()
	return 'RootNode'
end

function BTRootNode:returnUpLevel( res, context )
	return context:completeEvaluation( res )
end



--------------------------------------------------------------------
CLASS: BTSequenceSelector ( BTCompositedNode )
function BTSequenceSelector:getType()
	return 'BTSequenceSelector'
end

function BTSequenceSelector:execute( context )
	local nodeContext = context._nodeContext
	local index = nodeContext[ self ] or 1
	local child = self.children[ index ]
	if not child then
		nodeContext[ self ] = false
		return self:returnUpLevel( 'ok', context )
	end
	--run child node
	nodeContext[ self ] = index + 1
	return child:execute( context )
end

function BTSequenceSelector:resumeFromChild( child, res, context )
	if res == 'fail' then  --done
		context._nodeContext[ self ] = false
		return self:returnUpLevel( 'fail', context )
	end 
	return self:execute( context )
end

--------------------------------------------------------------------
CLASS: BTRandomSelector ( BTCompositedNode )
function BTRandomSelector:__init()
	self.probList = {}
end

function BTRandomSelector:getType()
	return 'BTRandomSelector'
end

function BTRandomSelector:postLoad()
	local l = {}
	for i, n in ipairs( self.children ) do
		local weight = 1
		if n:getType() == 'BTDecoratorWeight' then
			weight = n.value
		end
		l[ i ] = { weight, n }
	end
	self.probList = l
	return true
end

function BTRandomSelector:execute( context )
	local chosen = probselect( self.probList )
	if chosen then
		return chosen:execute( context )
	else
		return self:returnUpLevel( 'ignore', context )
	end
end

function BTRandomSelector:resumeFromChild( child, res, context )
	return self:returnUpLevel( res, context )
end

--------------------------------------------------------------------
CLASS: BTShuffledSequenceSelector ( BTCompositedNode )
function BTShuffledSequenceSelector:getType()
	return 'BTShuffledSequenceSelector'
end

function BTShuffledSequenceSelector:execute( context )
	local nodeContext = context._nodeContext
	local executeList = nodeContext[ self ]
	if not executeList then
		executeList = makeShuffleList( self.childrenCount )
		nodeContext[ self ] = executeList
	end

	local index = remove( executeList )
	if index then
		local child = self.children[ index ]
		return child:execute( context )
	else
		--queue empty
		nodeContext[ self ] = false
		return self:returnUpLevel( 'ok', context )
	end
end

function BTShuffledSequenceSelector:resumeFromChild( child, res, context )
	if res == 'fail' then
		context._nodeContext[ self ] = false
		return self:returnUpLevel( 'fail', context )
	end
	return self:execute( context )
end

--------------------------------------------------------------------
--------------------------------------------------------------------
--fails when either of concurrent child node fails
CLASS: BTConcurrentAndSelector ( BTCompositedNode )
function BTConcurrentAndSelector:getType()
	return 'BTConcurrentAndSelector'
end

function BTConcurrentAndSelector:execute( context )
	local nodeContext = context._nodeContext

	local env = nodeContext[ self ]
	if not env then 
		env = { okCount = 0, failCount = 0, firstRun = true }
		nodeContext[ self ] = env
	end

	for i, child in ipairs( self.children ) do
		child:execute( context )
	end

	env.firstRun = false
	return self:checkResult( context )
end

function BTConcurrentAndSelector:checkResult( context )
	local env = context._nodeContext[ self ]
	if env.firstRun then
		return 'running'
	end

	local okCount   = env.okCount
	local failCount = env.failCount

	if failCount > 0 then
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		context:removeRunningChildNodes( self )
		return self:returnUpLevel( 'fail', context )

	elseif okCount >= self.childrenCount then --all ok, now resume to parent
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		return self:returnUpLevel( 'ok', context )

	else
		return 'running'

	end
end

function BTConcurrentAndSelector:resumeFromChild( child, res, context )
	local env = context._nodeContext[ self ]
	if res == 'fail' then
		env.failCount = env.failCount + 1

	elseif res == 'ok' then
		env.okCount = env.okCount + 1

	else
		error( 'fatal error' )

	end

	return self:checkResult( context )
end

--------------------------------------------------------------------
--fails when both of concurrent child node fails
CLASS: BTConcurrentOrSelector ( BTCompositedNode )
--CONTEXT = failedChildCount
function BTConcurrentOrSelector:getType()
	return 'BTConcurrentOrSelector'
end


function BTConcurrentOrSelector:execute( context )
	local nodeContext = context._nodeContext
	local env = nodeContext[ self ]
	if not env then 
		env = { failCount = 0, okCount = 0, firstRun = true }
		nodeContext[ self ] = env
	end

	for i, child in ipairs( self.children ) do
		child:execute( context )
	end

	env.firstRun = false
	return self:checkResult( context )
end

function BTConcurrentOrSelector:checkResult( context )
	local env = context._nodeContext[ self ]
	local firstRun  = env.firstRun
	if firstRun then
		return 'running'
	end

	local okCount   = env.okCount
	local failCount = env.failCount

	if failCount >= self.childrenCount then
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		context:removeRunningChildNodes( self )
		return self:returnUpLevel( 'fail', context )

	elseif (okCount + failCount) >= self.childrenCount then 
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		return self:returnUpLevel( 'ok', context )

	else
		return 'running'

	end
end

function BTConcurrentOrSelector:resumeFromChild( child, res, context )
	local env = context._nodeContext[ self ]
	if res == 'fail' then
		env.failCount = env.failCount + 1

	elseif res == 'ok' then
		env.okCount = env.okCount + 1

	else
		error( 'fatal error' )

	end

	return self:checkResult( context )
end



--------------------------------------------------------------------
--ok when either of concurrent child node ok
CLASS: BTConcurrentEitherSelector ( BTCompositedNode )
function BTConcurrentEitherSelector:getType()
	return 'BTConcurrentEitherSelector'
end


function BTConcurrentEitherSelector:execute( context )
	local nodeContext = context._nodeContext

	local env = nodeContext[ self ]
	if not env then 
		env = { failCount = 0, okCount = 0, firstRun = true }
		nodeContext[ self ] = env
	end

	for i, child in ipairs( self.children ) do
		child:execute( context )
	end

	env.firstRun = false
	return self:checkResult( context )
end

function BTConcurrentEitherSelector:checkResult( context )
	local env = context._nodeContext[ self ]
	if env.firstRun then 
		return 'running'
	end

	local okCount   = env.okCount
	local failCount = env.failCount
	if okCount > 0 then
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		context:removeRunningChildNodes( self )
		return self:returnUpLevel( 'ok', context )

	elseif failCount >= self.childrenCount then
		--reset env
		env.okCount      = 0
		env.failCount    = 0
		env.firstRun     = true
		return self:returnUpLevel( 'fail', context )

	else
		return 'running'

	end
end

function BTConcurrentEitherSelector:resumeFromChild( child, res, context )
	local env = context._nodeContext[ self ]
	if res == 'fail' then
		env.failCount = env.failCount + 1

	elseif res == 'ok' then
		env.okCount   = env.okCount + 1

	else
		error( 'fatal error' )

	end

	return self:checkResult( context )
end


--------------------------------------------------------------------
--DECORATOR
---------------------------------------------------------------------
CLASS: BTDecorator ( BTNode )
function BTDecorator:getType()
	return 'Decorator'
end

function BTDecorator:addNode( node )
	--single child node
	assert( not self.targetNode, 'decoration node can only have ONE target node.' )
	self.targetNode = node
	node.parentNode = self
	node.depth = self.depth + 1
	return node
end

function BTDecorator:execute( context )
	return self.targetNode:execute( context )
end

function BTDecorator:validate( context )
	assert( self.targetNode, 'decoration node has no child node' )
	return self.targetNode:validate( context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorNot ( BTDecorator )
function BTDecoratorNot:getType()
	return 'BTDecoratorNot'
end

function BTDecoratorNot:resumeFromChild( child, res, context )
	if res ~= 'ignore' then
		res = res == 'ok' and 'fail' or 'ok'
	end
	return self:returnUpLevel( res, context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorAlwaysOK ( BTDecorator )
function BTDecoratorAlwaysOK:getType()
	return 'BTDecoratorAlwaysOK'
end

function BTDecoratorAlwaysOK:execute( context )
	if self.targetNode then
		return self.targetNode:execute( context )
	else
		return self:returnUpLevel( 'ok', context )
	end
end

function BTDecoratorAlwaysOK:resumeFromChild( child, res, context )
	return self:returnUpLevel( 'ok', context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorAlwaysFail ( BTDecorator )
function BTDecoratorAlwaysFail:getType()
	return 'BTDecoratorAlwaysFail'
end

function BTDecoratorAlwaysFail:execute( context )
	if self.targetNode then
		return self.targetNode:execute( context )
	else
		return self:returnUpLevel( 'fail', context )
	end
end

function BTDecoratorAlwaysFail:resumeFromChild( child, res, context )
	return self:returnUpLevel( 'fail', context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorAlwaysIgnore ( BTDecorator )
function BTDecoratorAlwaysIgnore:getType()
	return 'BTDecoratorAlwaysIgnore'
end

function BTDecoratorAlwaysIgnore:execute( context )
	if self.targetNode then
		return self.targetNode:execute( context )
	else
		return self:returnUpLevel( 'ignore', context )
	end
end

function BTDecoratorAlwaysIgnore:resumeFromChild( child, res, context )
	return self:returnUpLevel( 'ignore', context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorRepeatUntil ( BTDecorator )
function BTDecoratorRepeatUntil:getType()
	return 'BTDecoratorRepeatUntil'
end

function BTDecoratorRepeatUntil:resumeFromChild( child, res, context )
	if res == 'ok' then
		return self:returnUpLevel( 'ok', context )
	else --fail
		context:addRunningNode( self ) 
		return 'running'
	end
end

function BTDecoratorRepeatUntil:update( context )
	context:removeRunningNode( self ) 
	return self:execute( context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorRepeatFor ( BTDecorator )
function BTDecoratorRepeatFor:__init()
	self.minCount = 1
	self.maxCount = 1
end

function BTDecoratorRepeatFor:setRange( min, max )
	self.minCount = min or 1
	self.maxCount = math.max( self.minCount, max or 1 )
end

function BTDecoratorRepeatFor:getType()
	return 'BTDecoratorRepeatFor'
end

function BTDecoratorRepeatFor:execute( context )
	local nodeContext = context._nodeContext
	local count = randi( self.minCount, self.maxCount )
	-- print( 'RAND:', count, self.minCount, self.maxCount )
	local env = nodeContext[ self ]
	if not env then 
		env = { count = count, executed = 0 }
		nodeContext[ self ] = env
	end

	return self.targetNode:execute( context )
end

function BTDecoratorRepeatFor:resumeFromChild( child, res, context )
	if res == 'fail' then
		return self:returnUpLevel( 'fail', context )
	else --fail
		local nodeContext = context._nodeContext
		local env = nodeContext[ self ]
		local count    = env[ 'count' ]
		local executed = env[ 'executed' ] + 1
		if executed >= count then
			nodeContext[ self ] = nil
			return self:returnUpLevel( 'ok', context )
		else
			env[ 'executed' ] = executed
			context:addRunningNode( self ) 
			return 'running'
		end
	end
end

function BTDecoratorRepeatFor:update( context )
	context:removeRunningNode( self ) 
	return self:execute( context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorRepeatWhile ( BTDecorator )
function BTDecoratorRepeatWhile:getType()
	return 'BTDecoratorRepeatWhile'
end

function BTDecoratorRepeatWhile:resumeFromChild( child, res, context )
	if res == 'ok' then
		context:addRunningNode( self ) 
		return 'running'
	else --fail
		return self:returnUpLevel( 'ok', context )
	end
end

function BTDecoratorRepeatWhile:update( context )
	context:removeRunningNode( self ) 
	return self:execute( context )
end

--------------------------------------------------------------------
CLASS: BTDecoratorRepeatForever ( BTDecorator )
function BTDecoratorRepeatForever:getType()
	return 'BTDecoratorRepeatForever'
end

function BTDecoratorRepeatForever:resumeFromChild( child, res, context )
	context:addRunningNode( self ) 
	return 'running'
end

function BTDecoratorRepeatForever:update( context )
	context:removeRunningNode( self ) 
	return self:execute( context )
end


--------------------------------------------------------------------
CLASS: BTDecoratorWeight ( BTDecorator )
function BTDecoratorWeight:getType()
	return 'BTDecoratorWeight'
end

function BTDecoratorWeight:setValue( v )
	self.value = v
end

function BTDecoratorWeight:execute( context )
	if self.targetNode then
		return self.targetNode:execute( context )
	else
		return self:returnUpLevel( 'ignore', context )
	end
end

--------------------------------------------------------------------
CLASS: BTDecoratorProb ( BTDecorator )
function BTDecoratorProb:getType()
	return 'BTDecoratorProb'
end

function BTDecoratorProb:setValue( v )
	self.value = v or 0
end

function BTDecoratorProb:execute( context )
	if prob( self.value * 100 ) then
		return self.targetNode:execute( context )
	else
		return self:returnUpLevel( 'ignore', context )
	end
end


--------------------------------------------------------------------

BehaviorTreeNodeTypes = {
	['root']              = BTRootNode ;
	['condition']         = BTCondition ;
	['condition_not']     = BTConditionNot ;
	['action']            = BTActionNode ;
	['log']               = BTLoggingNode ;
	['msg']               = BTMsgSendingNode ;
	['priority']          = BTPrioritySelector ;
	['sequence']          = BTSequenceSelector ;
	['random']            = BTRandomSelector ;
	['shuffled']          = BTShuffledSequenceSelector ;
	['concurrent_and']    = BTConcurrentAndSelector ;
	['concurrent_or']     = BTConcurrentOrSelector ;
	['concurrent_either'] = BTConcurrentEitherSelector ;
	['decorator_not']     = BTDecoratorNot ;
	['decorator_ok']      = BTDecoratorAlwaysOK ;
	['decorator_fail']    = BTDecoratorAlwaysFail ;
	['decorator_ignore']  = BTDecoratorAlwaysIgnore ;
	['decorator_for']     = BTDecoratorRepeatFor ;
	['decorator_repeat']  = BTDecoratorRepeatUntil ;
	['decorator_while']   = BTDecoratorRepeatWhile ;
	['decorator_forever'] = BTDecoratorRepeatForever ;
	['decorator_prob']    = BTDecoratorProb ;
	['decorator_weight']  = BTDecoratorWeight ;

}

--------------------------------------------------------------------
--------------------------------------------------------------------

CLASS: BTController ( UpdateListener )
	:MODEL{
		Field 'scheme' :asset( '(bt_scheme|bt_script)' ) :getset('Scheme');
	}
	:META{
		category = 'behaviour'
	}
	
mock.registerComponent( 'BTController', BTController )

local startCountDown = 0
function BTController:__init()
	self.schemePath = false
	self.context    = BTContext( self )
	self.tree       = false
	self.resetting  = false

	--use different countdown start value to make the update sparse
	startCountDown = startCountDown + 1
	self._evaluateInterval = 10
	self._evaluateCountDown = startCountDown % self._evaluateInterval
end

function BTController:setEvaluateInterval( e )
	self._evaluateInterval = e
end

function BTController:scheduleUpdate()
	self._evaluateCountDown = 0
end

function BTController:onUpdate( dt )
	local tree = self.tree
	if not tree then return false end
	
	local context = self.context

	if self.resetting then
		self.resetting = false
		context:resetRunningState()
	end

	local running = context:updateRunningNodes( dt )
	self._evaluateCountDown = self._evaluateCountDown - 1

	if ( not running ) and self._evaluateCountDown <= 0 then
		self._evaluateCountDown = self._evaluateInterval
		context:executeTree( self.tree )
		return true
	else
		return false
	end

end

function BTController:onDetach( ent )
	--clear running actions
	self.context:clearRunningNode()
	BTController.__super.onDetach( self, ent )
end

function BTController:buildDebugInfo()
	return self.context:buildDebugInfo()
end

function BTController:getScheme()
	return self.schemePath
end

function BTController:setScheme( schemePath )
	self.schemePath = schemePath
	self.tree = loadAsset( schemePath )
	self:resetEvaluate()	
end

function BTController:resetEvaluate()
	self.resetting = true
	self:scheduleUpdate()
end

function BTController:resetContext( context )
	self.context:clearRunningNode()
	self.context = context or BTContext()
end

function BTController:getContext()
	return self.context
end

function BTController:setParam( k, v )
	return self.context:setParam( k, v )
end

function BTController:getParam( k, default )
	return self.context:getParam( k, default )
end

function BTController:setCondition( k, v, scheduleUpdate )
	if scheduleUpdate ~= false then
		self:scheduleUpdate()
	end
	return self.context:setCondition( k, v )
end

function BTController:getCondition( k )
	return self.context:getCondition( k )
end


