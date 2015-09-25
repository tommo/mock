module 'mock'
CLASS: Component ()
 	:MODEL{}

--------------------------------------------------------------------
wrapWithMoaiPropMethods( Component, '_entity._prop' )
--------------------------------------------------------------------

--------------------------------------------------------------------
--basic
--------------------------------------------------------------------
function Component:getEntity()
	return self._entity
end

function Component:getEntityName()
	return self._entity:getName()
end

function Component:getEntityTags()
	return self._entity:getTags()
end

function Component:destroyEntity()
	if self._entity then self._entity:destroy() end
end

function Component:findEntity( name )
	return self._entity:findEntity( name )
end

function Component:findChild( name, deep )
	return self._entity:findChild( name, deep )
end

function Component:getParent()
	return self._entity.parent
end

function Component:findEntityCom( name, comId )
	return self._entity:findEntityCom( name, comId )
end

function Component:findChildCom( name, comId, deep )
	return self._entity:findChildCom( name, comId, deep )
end

--------------------------------------------------------------------
function Component:getComponent( comType )
	return self._entity:getComponent( comType )
end

function Component:getComponentByName( comTypeName )
	return self._entity:getComponentByName( comTypeName )
end

function Component:com( id )
	return self._entity:com( id )
end

function Component:detachFromEntity()
	if self._entity then
		self._entity:detach( self )
	end
end

--------------------------------------------------------------------
--Scene
--------------------------------------------------------------------
function Component:getScene()
	local ent = self._entity
	return ent and ent.scene
end

function Component:getLayer()
	local ent = self._entity
	return ent and ent:getLayer()
end

function Component:attachGlobalAction( groupId, action )
	return self._entity:attachGlobalAction( groupId, action )
end

function Component:setActionPriority( action, priority )
	return self._entity:setActionPriority( action, priority )
end

function Component:setCurrentCoroutinePriority( priority )
	return self._entity:setCurrentCoroutinePriority( priority )
end


--------------------------------------------------------------------
--message & state
--------------------------------------------------------------------
function Component:tell( ... )
	return self._entity:tell( ... )
end

function Component:tellSelfAndChildren( ... )
	return self._entity:tellSelfAndChildren( ... )
end

function Component:tellChildren( ... )
	return self._entity:tellChildren( ... )
end

function Component:tellSiblings( ... )
	return self._entity:tellSiblings( ... )
end

function Component:getState()
	return self._entity.state()
end

function Component:inState( ... )
	return self._entity:inState( ... )
end

function Component:setState( state )
	return self._entity:setState( state )
end

function Component:inStateGroup( ... )
	return self._entity:inStateGroup( ... )
end


--------------------------------------------------------------------
-- invokes
--------------------------------------------------------------------

function Component:invokeUpward( methodName, ... )
	return self._entity:invokeUpward( methodName, ... )
end

function Component:invokeChildren( methodName, ... )
	return self._entity:invokeChildren( methodName, ... )
end

function Component:invokeComponents( methodName, ... )
	return self._entity:invokeComponents( methodName, ... )
end

function Component:invokeOneComponent( methodName, ... )
	return self._entity:invokeOneComponent( methodName, ... )
end

--------------------------------------------------------------------
--signals
--------------------------------------------------------------------
function Component:connect( sig, methodName )	
	return self._entity:connectForObject( self, sig, methodName )
end

-- function Component:disconnectAll()  ---DONE by entity

--------------------------------------------------------------------
-- Wait wrapping
--------------------------------------------------------------------
function Component:waitStateEnter(...)
	return self._entity:waitStateEnter(...)
end

function Component:waitStateExit(s)
	return self._entity:waitStateExit(s)
end

function Component:waitStateChange()
	return self._entity:waitStateChange()
end

function Component:waitFieldEqual( name, v )
	return self._entity:waitFieldEqual( name, v )
end

function Component:waitFieldNotEqual( name, v )
	return self._entity:waitFieldNotEqual( name, v )
end

function Component:waitFieldTrue( name )
	return self._entity:waitFieldTrue( name )
end

function Component:waitFieldFalse( name )
	return self._entity:waitFieldFalse( name )
end

function Component:waitSignal(sig)
	return self._entity:waitSignal(sig)
end

function Component:waitFrames(f)
	return self._entity:waitFrames(f)
end

function Component:waitTime(t)
	return self._entity:waitTime(t)
end

function Component:pauseThisThread( noyield )
	return self._entity:pauseThisThread( noyield )
end

function Component:wait( a )
	return self._entity:wait( a )
end

--------------------------------------------------------------------
---------coroutine control
--------------------------------------------------------------------

function Component:_weakHoldCoroutine( newCoro )
	local coroutines = self.coroutines
	if not coroutines then
		coroutines = { 
			[newCoro] = true
		}
		self.coroutines = coroutines
		return newCoro
	end
	--remove dead ones
	local dead = {}
	for coro in pairs( coroutines ) do
		if coro:isDone() then
			dead[ coro ] = true
		end
	end
	for coro in pairs( dead ) do
		coroutines[ coro ] = nil
	end
	coroutines[ newCoro ] = true
	return newCoro	
end

function Component:getCurrentCoroutine()
	return MOAICoroutine.currentThread()
end

function Component:addCoroutine( func, ... )
	local coro = self._entity:addCoroutineFor( self, func, ... )
	return self:_weakHoldCoroutine( coro )
end

function Component:addCoroutineP( func, ... )
	local coro = self._entity:addCoroutinePFor( self, func, ... )
	return self:_weakHoldCoroutine( coro )
end

function Component:addDaemonCoroutine( func, ... )
	local coro = self._entity:addDaemonCoroutineFor( self, func, ... )
	return self:_weakHoldCoroutine( coro )
end

function Component:clearCoroutines()
	if not self.coroutines then return end
	for coro in pairs( self.coroutines ) do
		coro:stop()
	end
	self.coroutines = nil
end

function Component:findCoroutine( method )
	if not self.coroutines then return end
	for coro in pairs( self.coroutines ) do
		if coro._func == method and (not coro:isDone()) then
			return coro
		end
	end
	return nil
end

function Component:findAllCoroutines( method )
	if not self.coroutines then return end
	local found = {}
	for coro in pairs( self.coroutines ) do
		if coro._func == method and (not coro:isDone()) then
			table.insert( found, coro )
		end
	end
	return found
end

function Component:findAndStopCoroutine( method )
	if not self.coroutines then return end
	for coro in pairs( self.coroutines ) do
		if coro._func == method and (not coro:isDone()) then
			coro:stop()
		end
	end
end


--------------------------------------------------------------------
-------Component management
--------------------------------------------------------------------
local componentRegistry = {}
function registerComponent( name, creator )
	-- assert( not componentRegistry[ name ], 'duplicated component type:'..name )
	if not creator then
		_error( 'no component to register', name )
	end
	componentRegistry[ name ] = creator
end

function registerEntityWithComponent( name, ... )
	local comClasses = {...}
	local creator = function( ... )
		local e = Entity()
		for i, comClass in ipairs( comClasses ) do
			local com = comClass()
			e:attach( com )
		end
		return e
	end
	return registerEntity( name, creator )
end

function getComponentRegistry()
	return componentRegistry
end

function getComponentType( name )
	return componentRegistry[ name ]
end


--------------------------------------------------------------------
-----------convert MOAIProp into attachable components
--------------------------------------------------------------------

local onAttachProp = function( self, entity )
	return entity:_attachProp( self )
end

local onDetachProp = function( self, entity )
	return entity:_detachProp( self )
end

function injectMoaiPropComponentMethod( clas )
	injectMoaiClass( clas, {
		onAttach       = onAttachProp,
		onDetach       = onDetachProp,
		setupProp      = setupMoaiProp,
		setupTransform = setupMoaiTransform
		})
end

injectMoaiPropComponentMethod( MOAIProp )
injectMoaiPropComponentMethod( MOAIProp2D )
injectMoaiPropComponentMethod( MOAITextBox )
injectMoaiPropComponentMethod( MOAIParticleSystem )
injectMoaiPropComponentMethod( MOAITextBox )



--------------------------------------------------------------------
local function affirmComponentClass( t, id )
	if type(id) ~= 'string' then error('component class name expected',2) end
	local classCreator = CLASS[ id ]
	local f = function( a, ... )		
		local clas = classCreator( CLASS, ... )
		mock.registerComponent( id, clas )
		return clas
	end
	setfenv( f, getfenv( 2 ) )
	return f
end

_G.COMPONENT = setmetatable( {}, { __index = affirmComponentClass } )

--------------------------------------------------------------------

local function affirmEntityClass( t, id )
	if type(id) ~= 'string' then error('entity class name expected',2) end
	local classCreator = CLASS[ id ]
	local f = function( a, superclass, ... )
		if not superclass then
			superclass = Entity
		end
		local clas = classCreator( CLASS, superclass, ... )
		mock.registerEntity( id, clas )
		return clas
	end
	setfenv( f, getfenv( 2 ) )
	return f
end

_G.ENTITY = setmetatable( {}, { __index = affirmEntityClass } )
