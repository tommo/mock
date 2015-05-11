module 'mock'

local loadAnimatorData

CLASS: AnimatorData ()

--------------------------------------------------------------------
AnimatorData	:MODEL{
		Field 'name'    :string();
		'----';
		Field 'clips' :array( AnimatorClip ) :no_edit();
	}

function AnimatorData:__init()
	self.name    = 'character'
	self.baseConfig = false
	self.clips = {}
	self.simpleSkeleton = false
	self.scale   = 1
end

function AnimatorData:getSpine()
	return self.spinePath
end

function AnimatorData:setSpine( path )
	self.spinePath = path
end

function AnimatorData:createClip( name )
	if not self.clips then self.clips = {} end
	local clip = AnimatorClip()
	clip.name = name
	return self:addClip( clip )	
end

function AnimatorData:addClip( clip )
	table.insert( self.clips, clip )
	clip.parent = self
	return clip
end

function AnimatorData:removeClip( clip )
	for i, c in ipairs( self.clips ) do
		if clip == c then
			table.remove( self.clips, i )
			return true
		end
	end
	return false
end

function AnimatorData:getClip( name )
	for i, clip in ipairs( self.clips ) do
		if clip.name == name then return clip end
	end
	return nil
end

function AnimatorData:sortEvents() --pre-serialization
	for i, clip in ipairs( self.clips ) do
		for _, track in ipairs( clip.tracks ) do
			track:sortEvents()
		end
	end
end

function AnimatorData:_load() --post-serialization
	for i, clip in ipairs( self.clips ) do
		clip:getRoot():_load()
	end
end


--------------------------------------------------------------------
--------------------------------------------------------------------
function loadAnimatorData( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	local animatorData = mock.deserialize( nil, data )
	-- if animatorData then --set parent nodes
	-- 	for i, clip in ipairs( animatorData.clips ) do
	-- 		for i, track in ipairs( clip.tracks ) do
	-- 			track.parent = clip
	-- 			for i, event in ipairs( track.events ) do
	-- 				event.parent = track
	-- 			end
	-- 		end
	-- 	end
	-- end
	animatorData:_load()
	return animatorData
end

mock.registerAssetLoader( 'animator_data', loadAnimatorData )
