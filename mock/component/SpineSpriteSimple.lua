module 'mock'

CLASS: SpineSpriteSimple ( SpineSprite )
	:MODEL{
	}

registerComponent( 'SpineSpriteSimple', SpineSpriteSimple )

function SpineSpriteSimple:_createSkeleton()
	return MOAISpineSkeletonSimple.new()
end

--todo: hide some unavailabe functions