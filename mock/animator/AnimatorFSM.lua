require 'mock.ai.FSMController'
module 'mock'


local _stateParsingCache = {}

local NameToAnimMode = {
	['normal']           = MOAITimer.NORMAL;
	['reverse']          = MOAITimer.REVERSE;
	['continue']         = MOAITimer.CONTINUE;
	['continue_reverse'] = MOAITimer.CONTINUE_REVERSE;
	['loop']             = MOAITimer.LOOP;
	['loop_reverse']     = MOAITimer.LOOP_REVERSE;
	['ping_pong']        = MOAITimer.PING_PONG;
}


local function parseArguments( raw )
	local result = {}
	for part in string.gsplit( raw, ',', true ) do
		local k, v = string.match( part, '^%s*([%w_.]+)%s*=%s*([%w_.%+%-]+)%s*' )
		if k then
			if k == 'duration' then
				v = tonumber( v ) or nil
			elseif k == 'start' or k == 'stop' or k == 'throttle' then
				local nv = tonumber( v )
				v = nv or v
			elseif k == 'mode' then
				v = NameToAnimMode[ v ] or false
			end
			if v ~= nil then
				result[ k ] = v
			end
		end
	end
	return result
end

local _noargs = {}
local function parseAnimatorFSMState( raw )
	local entry = _stateParsingCache[ raw ]
	if entry then return unpack( entry ) end
	content = raw:trim()
	--try  kv param
	do
		local name, optional, argstring = content:match('.*@([%w-_:%.]+)(%??)%s*%(%s*(.*)s*%)%s*')
		if name then
			optional = optional == '?'
			local args = parseArguments( argstring )
			_stateParsingCache[ raw ] = { name, args or _noargs, optional }
			return name, args, optional
		end
	end
	--test name
	do
		local name, optional = content:match('.*@([%w-_:%.]+)(%??)')
		optional = optional == '?'
		_stateParsingCache[ raw ] = { name, _noargs, optional }
		return name, _noargs, optional
	end
end

--TODO
CLASS: AnimatorFSM ( FSMController )
	:MODEL{
		Field 'syncEntityState' :boolean() :no_edit();
	}

function AnimatorFSM:__init()
	self.animator = false
	self.currentAnimState = false
	self.syncEntityState = false
end

function AnimatorFSM:onStart( ent )
	local animator = ent:com( mock.Animator )
	self.animator = animator
	self:updateScheme()
	return AnimatorFSM.__super.onStart( self, ent )
end

function AnimatorFSM:updateScheme()
	local scheme = self.scheme
	if not scheme then return end
	for name, stateBody in pairs( scheme ) do
		if name ~= 0 and ( name:find( '@' ) ) then
			local stepName = stateBody.stepName
			self[ stepName ] = function( controller, dt )
				local animState = controller.currentAnimState
				if not animState then return true end
				return not animState:isBusy()
			end
		end
	end
end

function AnimatorFSM:setState( state )
	AnimatorFSM.__super.setState( self, state )
	local animator = self.animator
	if not animator then return end

	self.currentAnimState = false
	if state == 'start' or state == 'stop' then return end
	if state:endwith( '.start' ) or state:endwith( '.stop' ) then return end

	animator:stop()
	local name, args, optional = parseAnimatorFSMState( state )
	-- print( 'fsm switch', state, name, optional )
	if name then
		local hasClip = animator:hasClip( name )
		if not hasClip then
			if not optional then
				_error( '(FSM) no anim clip found', name, self:getEntityName() )
				self:getFSMUpdateThread():stop()
			end
			return
		end
		local state = animator:loadClip( name, true ) --make state active
		-- print( 'playing anim', name  )
		local range0 = args['start']
		local range1 = args['stop']
		state:setRange( range0, range1 )
		local duration = args['duration']
		local throttle = args['throttle']
		local mode = args['mode']
		if mode then
			state:setMode( mode )
		end
		if duration then
			state:setDuration( duration )
		end
		if throttle then
			state:setThrottle( throttle )
		end
		self.currentAnimState = state
		state:start()
	end

end

registerComponent( 'AnimatorFSM', AnimatorFSM )
