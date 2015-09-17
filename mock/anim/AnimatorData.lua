module 'mock'


--------------------------------------------------------------------
CLASS: AnimatorData ()

AnimatorData	:MODEL{
		Field 'name'    :string();
		'----';
		Field 'clips'     :array( AnimatorClip ) :no_edit();
		Field 'rootGroup' :type( AnimatorClipGroup ) :no_edit();
	}

function AnimatorData:__init()
	self.name       = 'character'
	self.baseConfig = false
	self.clips      = {}
	self.simpleSkeleton = false
	self.scale   = 1
	self.groups  = {}
	self.rootGroup = AnimatorClipGroup()
	self.rootGroup.name = false
end

function AnimatorData:getRootGroup()
	return self.rootGroup
end

function AnimatorData:getSpine()
	return self.spinePath
end

function AnimatorData:setSpine( path )
	self.spinePath = path
end

function AnimatorData:createClipGroup( name, parentGroup )
	parentGroup = parentGroup or self.rootGroup
	local group = AnimatorClipGroup()
	parentGroup:addChildGroup( group )
	group.name = name
	return group
end

function AnimatorData:createClip( name, parentGroup )
	if not self.clips then self.clips = {} end
	local clip = AnimatorClip()
	clip.name = name
	return self:addClip( clip, parentGroup )	
end

function AnimatorData:addClip( clip, parentGroup )
	parentGroup = parentGroup or self.rootGroup
	--assert self:hasGroup( parentGroup )
	parentGroup:addChildClip( clip )
	table.insert( self.clips, clip )
	clip.parent = self
	return clip
end

function AnimatorData:addClipGroup( group, parentGroup )
	parentGroup = parentGroup or self.rootGroup
	--assert self:hasGroup( parentGroup )
	parentGroup:addChildGroup( group )
	return group
end

function AnimatorData:removeClipGroup( clipGroup )
	local parentGroup = clipGroup.parentGroup
	--remove all clips
	parentGroup:removeChildGroup( clipGroup )
	return true
end


function AnimatorData:removeClip( clip )
	local idx = table.index( self.clips )
	if idx then
		table.remove( self.clips, idx )
		if clip.parentGroup then
			clip.parentGroup:removeChildClip( clip )
		end
		return true
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
	if not self.rootGroup then
		self.rootGroup = AnimatorClipGroup()
		self.rootGroup.name = '__root'
	end

	for i, clip in ipairs( self.clips ) do --backward compatibilty
		if not clip.parentGroup then
			self.rootGroup:addChildClip( clip )
		end
		clip:getRoot():_load()
	end
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
	--set Group 
end


--------------------------------------------------------------------
--------------------------------------------------------------------
function loadAnimatorData( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('data') )
	local animatorData = mock.deserialize( nil, data )
	animatorData:_load()
	return animatorData
end

mock.registerAssetLoader( 'animator_data', loadAnimatorData )
