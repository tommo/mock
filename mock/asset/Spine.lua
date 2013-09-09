module 'mock'


function SpineJSONLoader( node )
	local jsonPath = node:getAbsObjectFile('json')
	local atlasPath = node:getAbsObjectFile('atlas')
	--todo
	local skeletonData = MOAISpineSkeletonData.new()
	skeletonData:load( jsonPath, atlasPath )
	return skeletonData
end

registerAssetLoader( 'spine', SpineJSONLoader )