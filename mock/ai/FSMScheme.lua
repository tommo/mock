module 'mock'

---DEAD LOCK DEBUG HELPER
local DEADLOCK_THRESHOLD = 100
local DEADLOCK_TRACK     = 10
local DEADLOCK_TRACK_ENABLED = true

local function tovalue( v )
	v = v:trim()
	if value == 'true' then
		return true, true
	elseif value == 'false' then
		return true, false
	elseif value == 'nil' then
		return true, nil
	else
		local n = tonumber( v )
		if n then return true, n end
		local s = v:match( [[^'(.*)'$]])
		if s then return true, s end
		local s = v:match( [[^"(.*)"$]])
		if s then return true, s end
	end
	return false
end

--------------------------------------------------------------------
local function buildFSMScheme( scheme )
	-- assert(targetClass,'Target Class required')
	assert( scheme, 'FSM Data required' )
	
	--for deadlock detection
	local trackedStates = {}

	--
	local stateFuncs    = {}

	---
	local function parseExprJump( msg )
		local content = msg:match('%s*if%s*%((.*)%)%s*')
		if not content then return nil end
		content = content:trim()

		local valueFunc, err = loadEvalScriptWithEnv( content )
		if not valueFunc then
			_warn( 'failed compiling condition expr:', err )
			return false
		else
			return valueFunc
		end
	end

	--build state funcs
	for name, stateBody in pairs( scheme ) do
		local id         = stateBody.id     --current state id
		local jump       = stateBody.jump   --transition trigger by msg
		local outStates  = stateBody.next   --transition trigger by state return value

		local localName  = stateBody.localName		
		local stepName   = id .. '__step'
		local exitName   = id .. '__exit'
		local enterName  = id .. '__enter'

		local exprJump = false
		if jump then
			for msg, target in pairs( jump ) do
				local exprFunc = parseExprJump( msg )
				if exprFunc then
					if not exprJump then exprJump = {} end
					exprJump[ msg ] = exprFunc
				end
			end
			if exprJump then
				for msg, exprFunc in pairs( exprJump ) do
					--replace msg
					local target = jump[ msg ]
					jump[ msg ] = nil
					jump[ exprFunc ] = target
				end
			end
		end
		--generated function
		local function stateStep( controller, dt, switchCount )
			----PRE STEP TRANSISTION
			local nextState
			local transMsg, transMsgArg
			
			local forceJumping = controller.forceJumping
			if forceJumping then
				controller.forceJumping = false
				nextState, transMsg, transMsgArg = unpack( forceJumping )
			else
				---STEP
				local step = controller[ stepName ]
				local out  = true
				--step return name of next state
				if step then 
					out = step( controller, dt )
					dt = 0 --delta time is consumed
				elseif step == nil then
					controller[ stepName ] = false
				end
				
				----POST STEP TRANSISTION
				if out and outStates then --approach next state
					nextState = outStates[ out ]
					if not nextState then
						_error( '! error in state:'..name )
						if type( out ) ~= 'string' then
							return error( 'output state name expected' )
						end
						error( 'output state not found:'..tostring( out ) )
					end
				else
					--find triggering msg (post phase)
					while true do
						transMsg, transMsgArg = controller:pollMsg()
						if not transMsg then return end
						nextState = jump and jump[ transMsg ]
						if nextState then break end
					end				
				end

			end

			if DEADLOCK_TRACK_ENABLED then
				--DEADLOCK DETECTOR
				switchCount = switchCount + 1
				if switchCount == DEADLOCK_THRESHOLD then 
					trackedStates = {}
				elseif switchCount > DEADLOCK_THRESHOLD then
					table.insert( trackedStates, name )
					if switchCount > DEADLOCK_THRESHOLD + DEADLOCK_TRACK then
						--state traceback
						_log( "state switch deadlock:", switchCount )
						for i, s in ipairs( trackedStates ) do 
							_log( i, s )
						end
						if getG( 'debugstop' ) then
							debugStop()
						end
						-- game:debugStop()
						error('TERMINATED') --terminate
					end
				end
			end
			
			local nextStateBody
			local nextStateName

			if controller:acceptStateChange( nextState ) == false then
				return
			end
			--TRANSITION
			local tt = type( nextState )
			if tt == 'string' then --direct transition
				nextStateName = nextState
				local exit = controller[ exitName ]
				if exit then --exit previous state
					exit( controller, nextStateName, transMsg, transMsgArg )
				elseif exit == nil then
					controller[ exitName ] = false
				end

			else --group transitions
				local l = #nextState
				nextStateName = nextState[l]
				local exit = controller[ exitName ]
				if exit then --exit previous state
					exit( controller, nextStateName, transMsg, transMsgArg )
				elseif exit == nil then
					controller[ exitName ] = false
				end
				--extra state group exit/enter
				for i = 1, l-1 do
					local funcName = nextState[ i ]
					local func = controller[ funcName ]
					if func then
						func( controller, name, nextStateName, transMsg, transMsgArg )
					end
				end				
			end

			controller:setState( nextStateName )
			nextStateBody = scheme[ nextStateName ]
			if not nextStateBody then
				error( 'state body not found:' .. nextStateName, 2 )
			end
			local enterName = nextStateBody.enterName
			--activate and enter new state handler
			local nextFunc = nextStateBody.func
			controller.currentStateFunc = nextFunc
			controller.currentExprJump  = nextStateBody.exprJump
			local enter = controller[ enterName ]
			if enter then --entering new state
				enter( controller, name, transMsg, transMsgArg )
			elseif enter == nil then
				controller[ enterName ] = false
			end
			controller:updateExprJump()
			return nextFunc( controller, dt, switchCount )
			
		end

		stateBody.func      = stateStep
		stateBody.stepName  = stepName
		stateBody.enterName = enterName
		stateBody.exitName  = exitName
		stateBody.exprJump  = exprJump

	end

	local startFunc      = scheme['start'].func
	local startEnterName = scheme['start'].enterName
	local startExprJump  = scheme['start'].exprJump
	scheme[0] = function( controller, dt )
		controller.currentStateFunc = startFunc
		controller.currentExprJump  = startExprJump
		local f = controller[ startEnterName ]
		if f then
			f( controller ) --fsm.start:enter
		end
		controller:updateExprJump()
		return startFunc( controller, dt, 0 )
	end
end

--------------------------------------------------------------------
function FSMSchemeLoader( node )
	local path = node:getObjectFile('def')
	local scheme = dofile( path )
	buildFSMScheme( scheme )
	return scheme
end

registerAssetLoader ( 'fsm_scheme', FSMSchemeLoader )
