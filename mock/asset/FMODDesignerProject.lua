module 'mock'

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
		_stat( 'loaded fmod project', self.projectId )
	else
		_error( 'failed loading fmod project:', path )
	end
	return self.loaded
end

function FMODDesignerProject:unload()
	if not self.loaded then return end

	if MOAIFmodEventMgr.unloadProject( self.projectId ) then
		self.loaded = false
		_stat( 'unloaded fmod project', self.projectId )
		return true
	end
	_error( 'failed unload fmod project', self.projectId )
	return false
end

function FMODDesignerProject:loadGroup( id )
	local group = FMODEventGroup( self, id )
	group:load()
	return group
end

function FMODDesignerProject:isLoaded()
	return self.loaded
end

--------------------------------------------------------------------
CLASS: FMODEventGroup ()
	:MODEL{}

function FMODEventGroup:__init( project, id )
	self.project = project
	self.id      = id
	self.fullName = project.projectId .. '/' .. id
	self.loaded  = false
end

function FMODEventGroup:load()
	if self.project:isLoaded() then
		self.loaded = MOAIFmodEventMgr.loadGroup( self.fullName )
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

--------------------------------------------------------------------
function FMODProjectLoader( node )
	local proj = FMODDesignerProject()
	proj:load( node:getObjectFile('export'), node:getBaseName() )
	return proj
end

function FMODGroupLoader( node )
	local proj = loadAsset( node.parent )
	return proj and proj:loadGroup( node:getName() )
end

function FMODEventLoader( node )
	local group = loadAsset( node.parent )
	return group and group:getEvent( node:getName() )
end

registerAssetLoader( 'fmod_project', FMODProjectLoader )
registerAssetLoader( 'fmod_event', FMODEventLoader )
registerAssetLoader( 'fmod_group', FMODGroupLoader )
