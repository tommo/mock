module 'mock'

CLASS: SpineSpriteBase ()
	:MODEL{
		Field 'sprite' :asset('spine') :getset('Sprite') :label('Sprite');
	}

function SpineSpriteBase:__init()
	self.skeleton  = MOAISpineSkeleton.new()
	self.propInserted  = false
end

function SpineSpriteBase:onAttach( entity )
	entity:_attachProp( self.skeleton )
end

function SpineSpriteBase:onDetach( entity )
	entity:_detachProp( self.skeleton )
	self.skeleton:forceUpdateSlots()
end

function SpineSpriteBase:setSprite( path )
	self.spritePath = path	
	self.skeletonData = loadAsset( path )
	if self.skeletonData  then
		local entity = self._entity
		if entity then
			entity:_detachProp( self.skeleton )		
			self.skeleton  = MOAISpineSkeleton.new()
			self.skeleton:load( self.skeletonData, 0.001 )
			entity:_attachProp( self.skeleton )
		else
			self.skeleton:load( self.skeletonData, 0.001 )
		end
	end
end

function SpineSpriteBase:getSprite()
	return self.spritePath
end


function SpineSpriteBase:setMixTable( t )
	self.mixTable = t
end

function SpineSpriteBase:getMixTable()
	return self.mixTable
end

function SpineSpriteBase:affirmClip( name )
	local t = self.skeletonData._animationTable
	return t[ name ]
end

function SpineSpriteBase:getClipLength( name )
	--TODO
	return 1
end
