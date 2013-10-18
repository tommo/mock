module 'mock'


--------------------------------------------------------------------
local stateCollectorMT
local setmetatable=setmetatable
local rawget,rawset=rawget,rawset
local pairs=pairs

stateCollectorMT = {
	__index = function( t, k )
		local __state = t.__state
		local __id    = t.__id
		return setmetatable({
			__state = __state and __state..'.'..k or k,
			__id    = __id and __id..'_'..k or '_FSM_'..k,
			__class = t.__class
		}	,stateCollectorMT)
	end,

	--got state method
	__newindex =function( t, action, func ) 
		local name  = t.__state
		local id    = t.__id
		local class = t.__class
		if action~='step' and action~='enter' and action~='exit' then
			return error('unsupported state action:'..action)
		end
		--NOTE:validation will be done after setting scheme to controller
		--save under fullname
		local methodName = id..'__'..action
		rawset ( class, methodName, func )
	end

}

local function newStateMethodCollector( class )
	return setmetatable({
		__state = false,
		__id    = false,
		__class = class
	}	,stateCollectorMT )
end

--------------------------------------------------------------------
CLASS:  FSMController ( Behaviour )
	:MODEL{
		Field 'state'  :string() :readonly() :get('getState');
		Field 'scheme' :asset('fsm_scheme') :getset('Scheme');
	}

-----fsm state method collector
FSMController.fsm = newStateMethodCollector( FSMController ) 

function FSMController:__initclass( subclass )
	subclass.fsm = newStateMethodCollector( subclass )
end

function FSMController:onStart( entity )
	self.threadFSMUpdate = self:addCoroutine( 'onThreadFSMUpdate' )
	Behaviour.onStart( self, entity )
end

function FSMController:getState()
	local ent = self._entity
	return ent and ent:getState()
end

function FSMController:updateFSM( dt )
	local func = self.currentStateFunc
	if func then
		return func( self, dt, 0 )
	end
end

function FSMController:setScheme( schemePath )
	self.schemePath = schemePath
	local scheme = loadAsset( schemePath )
	self.scheme = scheme
	if scheme then
		self.currentStateFunc = scheme[ 'start' ].func
		self:validateStateMethods()
	else
		self.currentStateFunc = nil
	end	
end

function FSMController:validateStateMethods()
	--todo
end

function FSMController:getScheme()
	return self.schemePath
end

function FSMController:onThreadFSMUpdate()
	local dt = 0
	while true do
		self:updateFSM( dt )
		dt = coroutine.yield()
	end
end

