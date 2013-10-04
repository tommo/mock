module 'mock'


function SpineJSONLoader( node )
	local jsonPath  = node:getAbsObjectFile( 'json'  )
	local atlasPath = node:getAbsObjectFile( 'atlas' )
	local jsonData  = loadAssetDataTable( jsonPath )
	local skeletonData = MOAISpineSkeletonData.new()
	skeletonData:load( jsonPath, atlasPath )
	skeletonData._jsonData = assert( jsonData )
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

function findSpineEventFrame( data, animName, eventName )
	local found = {}
	local jsonData = data._jsonData
	local animations = jsonData['animations']
	local anim = animations[ animName ]
	if not anim then return nil end
	local events = anim['events']
	if not events then return nil end
	for i, f in ipairs( events ) do
		if f['name'] == eventName then
			table.insert( found, f )
		end
	end
	return unpack( found )
end

registerAssetLoader( 'spine', SpineJSONLoader )