module 'mock'
if not MOAIFmodEventMgr then return end

local loadedFMODDesignerProjects = {}
--------------------------------------------------------------------
CLASS: FMODDesignerProject ()

function FMODDesignerProject:__init()
	self.loaded = false
	self.projectId = false
	self.groups = {}
end

function FMODDesignerProject:load( path, id )
	if self.loaded then return false end
	_stat( 'loading fmod project from', path )
	self.loaded = MOAIFmodEventMgr.loadProject( path .. '/'.. id ..'.fev' )
	self.projectId = id

	if self.loaded then
		loadedFMODDesignerProjects[ id ] = self
		_stat( 'loaded fmod project', self.projectId )
	else
		_error( 'failed loading fmod project:', path )
	end
	return self.loaded
end

function FMODDesignerProject:reload( path, id )
	self:unload()
	return self:load( path, id )
end

function FMODDesignerProject:unload()
	if not self.loaded then return end

	if loadedFMODDesignerProjects[ id ] == self then
		loadedFMODDesignerProjects[ id ] = nil
	end
	
	for id, group in pairs( self.groups ) do
		group:unload()
	end

	if MOAIFmodEventMgr.unloadProject( self.projectId ) then
		self.loaded = false
		_stat( 'unloaded fmod project', self.projectId )
		return true
	end
	_error( 'failed unload fmod project', self.projectId )
	return false
end

function FMODDesignerProject:loadGroup( id )
	local group = FMODEventGroup( self, nil, id )
	self.groups[ id ] = group
	group:load()
	return group
end

function FMODDesignerProject:isLoaded()
	return self.loaded
end

--------------------------------------------------------------------
CLASS: FMODEventGroup ()
	:MODEL{}

function FMODEventGroup:__init( project, parentGroup, id )
	self.project     = project
	self.parentGroup = parentGroup
	self.id          = id
	if parentGroup then
		self.fullName = parentGroup.fullName .. '/' .. id
	else
		self.fullName    = project.projectId .. '/' .. id
	end
	self.loaded      = false
	self.groups = {}
end

function FMODEventGroup:loadSubGroup( id )
	local group = FMODEventGroup( self.project, self, id )
	self.groups[ id ] = group
	group:load()
	return group
end

function FMODEventGroup:load()
	if self.project:isLoaded() then
		self.loaded = MOAIFmodEventMgr.loadGroup( self.fullName, true, true )
	else
		self.loaded = false
	end
	return self.loaded
end

function FMODEventGroup:isLoaded()
	return self.loaded
end

function FMODEventGroup:getEvent( id )
	local event = FMODEvent( self, id )
	return event
end

function FMODEventGroup:unload()
	if self.loaded then
		MOAIFmodEventMgr.unloadGroup( self.fullName )
		self.loaded = false
	end
end

function FMODEventGroup:unloadPendingUnloads()
	MOAIFmodEventMgr.unloadPendingUnloads( self.fullName )
end

--------------------------------------------------------------------
CLASS: FMODEvent ()
	:MODEL{}

function FMODEvent:__init( group, id )
	self.group = group
	self.id    = id
	self.fullName = group.fullName ..'/'..id
end

function FMODEvent:isLoaded()
	return self.group and self.group:isLoaded()
end

function FMODEvent:getFullName()
	return self.fullName
end

function FMODEvent:getSystemID()
	return self.fullName
end

function FMODEvent:unload()	
end

--------------------------------------------------------------------
local function FMODDesignerProjectLoader( node )
	local id = node:getBaseName()
	local proj = loadedFMODDesignerProjects[ id ]
	if proj then
		proj:reload( node:getObjectFile('export'), id )
		return proj
	end
	proj = FMODDesignerProject()
	proj:load( node:getObjectFile('export'), id )
	return proj
end

local function FMODDesignerProjectUnloader( node )
	
end


local function FMODGroupLoader( node )
	local p = node.parent
	local pAsset, pNode = loadAsset( p )
	if pNode.type == 'fmod_project' then
		local proj = pAsset
		return proj:loadGroup( node:getName() )
	elseif pNode.type == 'fmod_group' then
		local group = pAsset
		return group:loadSubGroup( node:getName() )
	else
		error( 'bad fmod designer project asset:'..node:getNodePath() )
	end
end

local function FMODEventLoader( node )
	local group = loadAsset( node.parent )
	return group and group:getEvent( node:getName() )
end

registerAssetLoader( 'fmod_project', FMODDesignerProjectLoader, FMODDesignerProjectUnloader )
registerAssetLoader( 'fmod_event', FMODEventLoader )
registerAssetLoader( 'fmod_group', FMODGroupLoader )

addSupportedSoundAssetType( 'fmod_event' )
