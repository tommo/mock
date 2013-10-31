module 'character'

--------------------------------------------------------------------
CLASS: EventSpineAnimation ( CharacterActionEvent )
	:MODEL{
		Field 'clip'  :string();
		Field 'loop'  :boolean();
		Field 'resetOnPlay'  :boolean();
	}

function EventSpineAnimation:__init()
	self.length = 1
	self.clip   = ''
	self.loop   = false
	self.resetOnPlay = true
end

function EventSpineAnimation:isResizable()
	return true
end

function EventSpineAnimation:toString()
	local clip = self.clip
	if not clip or clip == '' then return '<nil>' end
	if self.loop then
		return '<loop> '..clip
	else
		return clip
	end
end

function EventSpineAnimation:setClip( name )
	self.clip = name
end


--------------------------------------------------------------------
CLASS: TrackSpineAnimation ( CharacterActionTrack )
	:MODEL{}

function TrackSpineAnimation:__init()
	self.name = 'animation'
end

function TrackSpineAnimation:createEvent()
	return EventSpineAnimation()
end

function TrackSpineAnimation:hasKeyFrames()
	return false
end

function TrackSpineAnimation:getType()
	return 'spine'
end

function TrackSpineAnimation:toString()
	return '<spine>' .. tostring( self.name )
end

function TrackSpineAnimation:start( state )
	--build MOAISpineAnimationTrack
	local target      = state.target
	local spineTracks = state.spineTracks
	if not spineTracks then 
		spineTracks = {}
		state.spineTracks = spineTracks
	end
	local spineState = target.spineState
	if not spineState then
		spineState = target.spineSprite:createState()
		spineState:setSpan( 100000 )
		target.spineState = spineState
	end

	spineState:pause( false )
	spineState:setTime( 0 )
	spineState:apply( 0 )
	spineState:start()
	local animTrack = spineState:addTrack()
	spineTracks[ self ] = animTrack
	for i, ev in ipairs( self.events ) do
		local l = ev.length/1000
		animTrack:addSpan( ev.pos/1000, ev.clip, ev.loop, l>0 and l or nil )
	end

end

function TrackSpineAnimation:stop( state )	
	local spineTracks = state.spineTracks
	if not spineTracks then return end
	local spineState = state.target.spineState
	local track = spineTracks[ self ]
	spineState:removeTrack( track )
	spineState:stop()
	spineTracks[ self ] = nil
end


function TrackSpineAnimation:pause( state, paused )
	local spineState = state.target.spineState
	spineState:pause( paused )
end

function TrackSpineAnimation:setThrottle( state, t )
	local spineState = state.target.spineState
	if spineState then
		spineState:throttle( t )
	end
end

function TrackSpineAnimation:apply( state, t )
	local spineState = state.target.spineState
	if spineState then
		spineState:apply( t )
	end
end

--------------------------------------------------------------------
registerCharacterActionTrackType( 'Spine Animation', TrackSpineAnimation )
