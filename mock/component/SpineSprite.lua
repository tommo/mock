module 'mock'

CLASS: SpineSprite ()
	:MODEL{
		Field 'sprite' :asset('spine') :getset('Sprite') :label('Sprite');
		Field 'defaultClip' :string() :label('Default');
		Field 'autoPlay'    :boolean() :label('Auto Play');
	}

registerComponent( 'SpineSprite', SpineSprite )

function SpineSprite:__init()
	self.skeleton  = MOAISpineSkeleton.new()
	self.propInserted = false
	self.animState = false
	self.defaultClip = ''
	self.autoPlay    = true
end

function SpineSprite:onAttach( entity )
	entity:_attachProp( self.skeleton )
	self:insertSlots()
end

function SpineSprite:onDetach( entity )
	self:removeSlots()
	entity:_detachProp( self.skeleton )
end

function SpineSprite:insertSlots()
	if not self.propInserted then
		local entity = self._entity
		if not entity then return end
		self.skeleton:insertIntoPartition( entity.layer:getPartition() )
		self.propInserted = true
	end
end

function SpineSprite:removeSlots()
	if self.propInserted then
		self.skeleton:removeFromPartition()
		self.propInserted = false
	end
end

function SpineSprite:onStart( entity )
	if self.autoPlay and self.defaultClip then
		self:play( self.defaultClip )
	end
end

function SpineSprite:setSprite( path )
	self.spritePath = path	
	self.skeletonData = loadAsset( path )
	if self.skeletonData  then
		self.skeleton:load( self.skeletonData )
		self:insertSlots()
	else
		self:removeSlots()		
	end
end

function SpineSprite:getSprite()
	return self.spritePath
end

function SpineSprite:play( clipName, mode )
	local state = MOAISpineAnimationState.new()
	state:init( self.skeletonData )
	state:setSkeleton( self.skeleton )
	state:setMode( MOAITimer.CONTINUE  )
	state:setAnimation( clipName, true, 0 )
	state:start()
	self.animState = state 
end

function SpineSprite:stop()
	self.animState:stop()
end



