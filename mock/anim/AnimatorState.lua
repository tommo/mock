module 'mock'

local function _onAnimUpdate( anim )
	local t = anim:getTime()
	local state = anim.source
	return state:onUpdate( t )
end

local function _onAnimKeyFrame( timer, keyId, timesExecuted, time, value )
	local state  = timer.source
	local keys= state.keyEventMap[ keyId ]
	local time   = timer:getTime()
	for i, key in ipairs( keys ) do
		key:executeEvent( state, time )
	end
end

--------------------------------------------------------------------
CLASS: AnimatorState ()
	:MODEL{}

function AnimatorState:__init()
	self.anim = MOAIAnim.new()
	self.anim.source = self
	self.anim:setListener( MOAIAnim.EVENT_ACTION_POST_UPDATE, _onAnimUpdate )
	self.anim:setListener( MOAIAnim.EVENT_TIMER_KEYFRAME, _onAnimKeyFrame )
	self.trackContexts = {}
	self.updateListenerTracks = {}
	self.attrLinks = {}
	self.attrLinkCount = 0
	self.throttle = 1
	self.trackTargets = {}
	self.stopping = false
	self.previewing = false
end

function AnimatorState:setThrottle( t )
	self.throttle = t or 1
	self.anim:throttle( t )
end

function AnimatorState:getThrottle()
	return self.throttle
end

function AnimatorState:start()
	self.anim:start()
end

function AnimatorState:stop()
	self.stopping = true
	self.anim:stop()
end

function AnimatorState:isActive()
	return self.anim:isActive()
end

function AnimatorState:isDone()
	return self.anim:isDone()
end 

function AnimatorState:isPaused()
	return self.anim:isPaused()
end 

function AnimatorState:isBusy()
	return self.anim:isBusy()
end 

function AnimatorState:isDone()
	return self.anim:isDone()
end 

function AnimatorState:setMode( mode )
	self.anim:setMode( mode or MOAITimer.NORMAL )
end

function AnimatorState:pause( paused )
	self.anim:pause( paused )
end

function AnimatorState:resume()
	self.anim:resume()
end

function AnimatorState:getTime()
	return self.anim:getTime()
end

function AnimatorState:apply( t )
	local anim = self.anim
	local t0 = anim:getTime()
	anim:setTime( t )
	anim:apply( t0, t )
	-- t = anim:getTime()
	-- self:onUpdate( t, t0 )
end

function AnimatorState:onUpdate( t, t0 )
	for track, target in pairs( self.updateListenerTracks ) do
		if self.stopping then return end --edge case: new clip started in apply
		track:apply( self, target, t, t0 )
	end
end

function AnimatorState:loadClip( animator, clip )
	self.animator    = animator
	self.targetRoot  = animator._entity
	self.targetScene = self.targetRoot.scene
	self.clip        = clip

	local anim = self.anim
	local context = clip:getBuiltContext()
	anim:setSpan( context.length )
	
	local previewing = self.previewing
	for track in pairs( context.playableTracks ) do
		if track:isLoadable( self ) then
			if ( not previewing ) or track:isPreviewable() then
				track:onStateLoad( self )
			end
		end
	end

	anim:reserveLinks( self.attrLinkCount )
	for i, linkInfo in ipairs( self.attrLinks ) do
		local track, curve, target, attrId, asDelta  = unpack( linkInfo )
		if target then
			if ( not previewing ) or track:isPreviewable() then
				anim:setLink( i, curve, target, attrId, asDelta )
			end
		end
	end


	--event key
	anim:setCurve( context.eventCurve )
	self.keyEventMap = context.keyEventMap

end

function AnimatorState:addUpdateListenerTrack( track, context )
	self.updateListenerTracks[ track ] = context
end

function AnimatorState:addAttrLink( track, curve, target, id, asDelta )
	self.attrLinkCount = self.attrLinkCount + 1
	self.attrLinks[ self.attrLinkCount ] = { track, curve, target, id, asDelta or false }
end

function AnimatorState:findTarget( targetPath )
	local obj = targetPath:get( self.targetRoot, self.targetScene )
	return obj
end

function AnimatorState:getTargetRoot()
	return self.targetRoot, self.targetScene
end

function AnimatorState:setTrackTarget( track, target )
	self.trackTargets[ track ] = target
end

function AnimatorState:getTrackTarget( track )
	return self.trackTargets[ track ]
end

function AnimatorState:setListener( evId, func )
	self.anim:setListener( evId, func )
end


-- function AnimatorState:addEventKey( track )
-- end
