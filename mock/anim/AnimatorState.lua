module 'mock'

local function _onAnimUpdate( anim )
	local t = anim:getTime()
	local state = anim.source
	return state:onUpdate( t )
end

local function _onAnimKeyFrame( timer, keyId, timesExecuted, time, value )
	local state  = timer.source
	local keys   = state.keyEventMap[ keyId ]
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
end

function AnimatorState:setThrottle( t )
	self.throttle = t
	self.anim:throttle( t )
end

function AnimatorState:start()
	self.anim:start()
end

function AnimatorState:stop()
	self.anim:stop()
end

function AnimatorState:setMode( mode )
	self.anim:setMode( mode )
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
	t = anim:getTime()
	self:onUpdate( t )
end

function AnimatorState:onUpdate( t )
	for track, target in pairs( self.updateListenerTracks ) do
		track:apply( self, target, t )
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
	
	local trackContexts = self.trackContexts
	for track in pairs( context.playableTracks ) do
		track:onStateLoad( self )
	end

	anim:reserveLinks( self.attrLinkCount )
	for i, linkInfo in ipairs( self.attrLinks ) do
		local track, curve, target, attrId, asDelta  = unpack( linkInfo )
		anim:setLink( i, curve, target, attrId, asDelta )
	end

	--event key
	anim:setCurve( context.eventCurve )
	self.keyEventMap = context.keyEventMap

end

function AnimatorState:addUpdateListenerTrack( track, target )
	self.updateListenerTracks[ track ] = target
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

-- function AnimatorState:addEventKey( track )
-- end
