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
	self.clipSpeed = 1
	self.actualThrottle = 1
	self.trackTargets = {}
	self.stopping = false
	self.previewing = false
	self.length = 0
	self.clip   = false
	
	self.startPos = 0
	self.endPos   = 0

	self.duration = 0

end

function AnimatorState:getMoaiAction()
	return self.anim
end
---
function AnimatorState:isActive()
	return self.anim:isActive()
end

function AnimatorState:setThrottle( t )
	self.throttle = t or 1
	self:updateThrottle()
end

function AnimatorState:getThrottle()
	return self.throttle
end

function AnimatorState:setClipSpeed( speed )
	self.clipSpeed = speed
	self:updateThrottle()
end

function AnimatorState:updateThrottle()
	local t = self.throttle * self.clipSpeed
	self.actualThrottle = t
	self.anim:throttle( self.actualThrottle )
end

function AnimatorState:resetRange()
	self:setRange( 0, self.length )
end

function AnimatorState:setRange( startPos, endPos )
	local p0, p1
	
	if not startPos then --current time
		p0 = self:getTime()
	else
		p0 = self:affirmPos( startPos )
	end
	
	if not endPos then --end time
		p1 = self.clipLength
	else
		p1 = self:affirmPos( endPos )
	end

	self.startPos = p0
	self.endPos   = p1
	self.anim:setSpan( p0, p1 )
end

function AnimatorState:getRange()
	return self.startPos, self.endPos
end

function AnimatorState:setDuration( duration )
	self.duration = duration or 0
end

function AnimatorState:getDuration()
	return self.duration
end

function AnimatorState:setMode( mode )
	self.anim:setMode( mode or MOAITimer.NORMAL )
end

function AnimatorState:getMode()
	return self.anim:getMode()
end 	

function AnimatorState:play( mode )
	if mode then
		self:setMode( mode )
	end
	return self:start()
end

function AnimatorState:playRange( startPos, endPos, mode )
	self:setRange( startPos, endPos )
	return self:resetAndPlay( mode )
end

function AnimatorState:playUntil( endPos )
	self:setRange( nil, endPos )
	return self:start()
end

function AnimatorState:seek( pos )
	local t = self:affirmPos( pos )
	self:setRange( t )
	self:apply( t )
end


function AnimatorState:start()
	self.anim:start()
	self.anim:pause( false )
	return self.anim
end

function AnimatorState:stop()
	self.stopping = true
	self.anim:stop()
	return self.anim
end

function AnimatorState:reset()
	self:seek( 0 )
end

function AnimatorState:resetAndPlay( mode )
	self:reset()
	return self:play( mode )
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

function AnimatorState:pause( paused )
	self.anim:pause( paused )
end

function AnimatorState:resume()
	local anim = self.anim
	if not anim:isBusy() then
		anim:start()
	end
	anim:pause( false )
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

function AnimatorState:findMarker( id )
	return self.clip:findMarker( id )
end

function AnimatorState:affirmPos( pos )
	local tt = type( pos )
	if tt == 'string' then
		local marker = self:findMarker( pos )
		pos = marker and marker:getPos()
	elseif tt == 'nil' then
		return 0
	end
	return clamp( pos, 0, self.clipLength )
end

--
function AnimatorState:onUpdate( t, t0 )
	for track, target in pairs( self.updateListenerTracks ) do
		if self.stopping then return end --edge case: new clip started in apply
		track:apply( self, target, t, t0 )
	end
	local duration = self.duration
	if duration > 0 and t >= duration then
		self:stop()
	end
end

function AnimatorState:loadClip( animator, clip )
	self.animator    = animator
	self.targetRoot  = animator._entity
	self.targetScene = self.targetRoot.scene

	local context = clip:getBuiltContext()
	self.clip        = clip
	self.clipLength  = context.length

	local anim = self.anim
	
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
	
	--range init
	anim:setSpan( self.clipLength )

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

