module 'mock'

local EVENT_SPINE_ANIMATION_START    = MOAISpineAnimationState.EVENT_SPINE_ANIMATION_START
local EVENT_SPINE_ANIMATION_END      = MOAISpineAnimationState.EVENT_SPINE_ANIMATION_END
local EVENT_SPINE_ANIMATION_COMPLETE = MOAISpineAnimationState.EVENT_SPINE_ANIMATION_COMPLETE
local EVENT_SPINE_ANIMATION_EVENT    = MOAISpineAnimationState.EVENT_SPINE_ANIMATION_EVENT

CLASS: SpineSprite ()
	:MODEL{
		Field 'sprite' :asset('spine') :getset('Sprite') :label('Sprite');
		Field 'defaultClip' :string() :label('Default');
		Field 'autoPlay'    :boolean() :label('Auto Play');
	}

registerComponent( 'SpineSprite', SpineSprite )

function SpineSprite:__init()
	self.skeleton  = MOAISpineSkeleton.new()
	self.propInserted  = false
	self.animState     = false
	self.defaultClip   = ''
	self.autoPlay      = true
	self._onAnimationEvent  = false
	self.throttle      = 1
end

function SpineSprite:onAttach( entity )
	entity:_attachProp( self.skeleton )
end

function SpineSprite:onDetach( entity )
	entity:_detachProp( self.skeleton )
end

function SpineSprite:onStart( entity )
	local default = self.defaultClip
	if self.autoPlay and default and default ~= '' then
		self:play( default )
	end
end

function SpineSprite:setSprite( path )
	self.spritePath = path	
	self.skeletonData = loadAsset( path )
	if self.skeletonData  then
		local entity = self._entity
		if entity then
			entity:_detachProp( self.skeleton )		
			self.skeleton  = MOAISpineSkeleton.new()
			self.skeleton:load( self.skeletonData )
			entity:_attachProp( self.skeleton )
		else
			self.skeleton:load( self.skeletonData )
		end
	end
end

function SpineSprite:getSprite()
	return self.spritePath
end

local function _onSpineAnimationEvent( state, trackId, name, varInt, varFloat, varString )
	return state.owner:onAnimationEvent( trackId, name, varInt, varFloat, varString )
end

local function _onSpineAnimationComplete( state, trackId, loopCount )
	return state.owner:onAnimationComplete( trackId, loopCount )
end

function SpineSprite:play( clipName, mode )
	if self.animState  then
		self.animState:stop()
	end
	mode = mode or MOAITimer.NORMAL
	local state = MOAISpineAnimationState.new()
	state:init( self.skeletonData )
	state:setSkeleton( self.skeleton )
	state:setMode( mode )
	state:throttle( self.throttle )
	if not self:affirmClip( clipName ) then
		_traceback()
		_warn( 'spine anim clip not found:', clipName )
		return false
	end
	self.skeleton:setToSetupPose()
	local loop = mode == MOAITimer.LOOP
	state:setAnimation( 0, clipName, loop )
	state:setSpan( 1000000 )
	state:start()
	state.owner = self
	state:setListener( EVENT_SPINE_ANIMATION_EVENT, _onSpineAnimationEvent )
	-- state:setListener( EVENT_SPINE_ANIMATION_COMPLETE, _onSpineAnimationComplete )
	self.animState = state 
	return state
end

function SpineSprite:setThrottle( th )
	self.throttle = th
	if self.animState then
		self.animState:throttle( th )
	end
end

function SpineSprite:affirmClip( name )
	local t = self.skeletonData._animationTable
	return t[ name ]
end

function SpineSprite:getClipLength( name )
	--TODO
	return 1
end

function SpineSprite:stop()
	if self.animState then
		self.animState:stop()
	end
	self.skeleton:setToSetupPose()
end

function SpineSprite:setAnimationEventListener( listener )
	self._onAnimationEvent = listener
end

function SpineSprite:onAnimationEvent( trackId, evName, varInt, varFloat, varString )
	local callback = self._onAnimationEvent
	if callback then
		return callback( evName, varInt, varFloat, varString )
	end
end
