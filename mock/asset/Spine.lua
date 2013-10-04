module 'mock'


function SpineJSONLoader( node )
	local jsonPath  = node:getAbsObjectFile( 'json'  )
	local atlasPath = node:getAbsObjectFile( 'atlas' )
	print( jsonPath, atlasPath )
	--todo
	local skeletonData = MOAISpineSkeletonData.new()
	skeletonData:load( jsonPath, atlasPath )
	local animations = { skeletonData:getAnimationNames() }
	local skins      = { skeletonData:getSkinNames() }
	local animationTable = {}	
	for i, n in ipairs( animations ) do
		animationTable[ n ] = i
	end
	local skinTable = {}
	for i, n in ipairs( skins ) do
		skinTable[ n ] = i
	end
	skeletonData._animationTable = animationTable
	skeletonData._skinTable      = skinTable
	return skeletonData
end

registerAssetLoader( 'spine', SpineJSONLoader )