module 'mock'

---DEAD LOCK DEBUG HELPER
local DEADLOCK_THRESHOLD = 100
local DEADLOCK_TRACK     = 10
local DEADLOCK_TRACK_ENABLED = true
--------------------------------------------------------------------
local function buildFSMScheme( scheme )
	-- assert(targetClass,'Target Class required')
	assert( scheme, 'FSM Data required' )
	
	--for deadlock detection
	local trackedStates = {}

	--
	local stateFuncs    = {}

	for name, stateBody in pairs( scheme ) do
		local id         = stateBody.id     --current state id
		local jump       = stateBody.jump   --transition trigger by msg
		local outStates  = stateBody.next   --transition trigger by state return value

		local localName  = stateBody.localName		
		local stepname   = id .. '__step'
		local exitname   = id .. '__exit'
		local entername  = id .. '__enter'
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
				local step = controller[ stepname ]
				local out  = true
				--step return name of next state
				if step then 
					out = step( controller, dt )
					dt = 0 --delta time is consumed
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
						print( "state switch deadlock:", switchCount )
						for i, s in ipairs( trackedStates ) do 
							print( i, s )
						end
						if debugstop then
							debugStop()
						end
						-- game:debugStop()
						error('TERMINATED') --terminate
					end
				end
			end
			
			local nextStateBody
			local nextStateName
			--TRANSITION
			local tt = type( nextState )
			if tt == 'string' then --direct transition
				nextStateName = nextState
				local exit = controller[ exitname ]
				if exit then --exit previous state
					exit( controller, nextStateName, transMsg, transMsgArg )
				end

			else --group transitions
				local l = #nextState
				nextStateName = nextState[l]
				local exit = controller[ exitname ]
				if exit then --exit previous state
					exit( controller, nextStateName, transMsg, transMsgArg )
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
			local enter = controller[ nextStateBody.entername ]
			if enter then --entering new state
				enter( controller, name, transMsg, transMsgArg )
			end
			--activate and enter new state handler
			local nextFunc = nextStateBody.func
			controller.currentStateFunc = nextFunc
			return nextFunc( controller, dt, switchCount )
			
		end

		stateBody.func      = stateStep
		stateBody.entername = entername
		stateBody.exitname  = exitname

	end
	local startEnterName = scheme['start'].entername
	local startFunc      = scheme['start'].func
	scheme[0] = function( controller, dt )
		local f = controller[ startEnterName ]
		if f then
			f( controller ) --fsm.start:enter
		end
		controller.currentStateFunc = startFunc
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
