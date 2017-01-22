module 'mock'

local MASTER_BANK_NAME        = 'Master Bank.bank'
local MASTER_BANK_STRING_NAME = 'Master Bank.strings.bank'

local loadedFMODStudioProjects = {}

--------------------------------------------------------------------
CLASS: FMODStudioProject ()
	:MODEL{}

function FMODStudioProject:__init()
	self.loaded    = false
	self.projectId = false
	self.rootPath  = false
	
	self.targetPlatform = 'Desktop'

	self.strings         = {}
	self.eventStrings    = {}
	self.snapshotStrings = {}
	self.busStrings      = {}

	self.objectCache     = {}
	self.eventCache = {}

	self.banks = {}

	self.eventRootFolder   = FMODStudioProjectFolder()
	self.eventRootFolder.itemType = 'event'
	
	self.snapshotRootFolder = FMODStudioProjectFolder()
	self.snapshotRootFolder.itemType = 'snapshot'
	
	self.busRootFolder = FMODStudioProjectFolder()
	self.busRootFolder.itemType = 'bus'

	self.bankRootFolder = FMODStudioProjectFolder()
	self.bankRootFolder.itemType = 'bank'

end

function FMODStudioProject:getEventRootFolder()
	return self.eventRootFolder
end

function FMODStudioProject:getSnapshotRootFolder()
	return self.snapshotRootFolder
end

function FMODStudioProject:getBusRootFolder()
	return self.busRootFolder
end

function FMODStudioProject:getBankRootFolder()
	return self.bankRootFolder
end

function FMODStudioProject:load( path, id )
	if self.loaded then return false end
	_stat( 'loading fmod studio banks', path )
	self.rootPath = path .. '/Build/' .. self.targetPlatform
	self:loadStringBank()
	self:loadAllBanks()
end

function FMODStudioProject:updateChildAssetFromBanks( node )
	local basePath = node:getPath()
	local lib = getAssetLibrary()
	for fmodPath, guid in pairs( self.strings ) do
		local t, subPath = fmodPath:match( '(%w+):/(.*)' )
		if t == 'event' then
			local assetPath = basePath .. '/event/' .. subPath
			if not lib[ assetPath ] then
				local data ={
					filePath = false,
					type = 'fs_event',
					deploy = false,
					properties = {
						path = fmodPath,
						guid = guid,
					},
					fileTime = 0,
					dependency = false,
					objectFiles = {},
				}
				local node = registerAssetNode( assetPath, data )
				node.parent = false
				print( 'add extra fmod event:', assetPath)
			end
		end
	end
end

function FMODStudioProject:unloadBank( bankPath )
	local bank = self.banks[ bankPath ]
	if not bank then
		_warn( 'no bank to unload', bankPath )
		return false
	end
	bank:unload()
	self.banks[ bankPath ] = nil
end

function FMODStudioProject:unloadAllBanks()
	for path, bank in pairs( self.banks ) do
		bank:unload()
	end
	self.banks = {}
end

function FMODStudioProject:isLoading()
	for path, bank in pairs( self.banks ) do
		local s = bank:getLoadingState()
		if s ~= 3 then return true end
	end
	return false
end

function FMODStudioProject:loadBank( bankPath, blocking )
	if self.banks[ bankPath ] then
		_warn( 'bank already in loading', bankPath )
		return false
	end
	local fullPath = self.rootPath .. '/' ..bankPath
	print( 'loading bank', fullPath, blocking )
	sys = AudioManager.get():getSystem()
	local bank = sys:loadBankFile( fullPath, blocking == true )

	if bank then
		self.banks[ bankPath ] = bank
		return bank
	else
		_error( 'no bank found', fullPath )
		return false
	end
end

function FMODStudioProject:loadStringBank()
	local stringBank = self:loadBank( MASTER_BANK_STRING_NAME, true )
	if not stringBank then return false end
	local strings = {}
	local count = stringBank:getStringCount()
	for i = 1, count do
		local guid, path = stringBank:getStringInfo( i - 1 )
		strings[ path ] = guid
	end
	self.strings = strings
end

function FMODStudioProject:loadAllBanks()
	local files = MOAIFileSystem.listFiles( self.rootPath )
	for i, f in ipairs( files ) do
		if f:endwith( '.bank' ) then
			if not self.banks[ f ] then
				self:loadBank( f, true )
			end
		end
	end
end

function FMODStudioProject:getStrings()
	return self.strings
end

function FMODStudioProject:pathToId( path )
	return self.strings[ path ]
end

function FMODStudioProject:eventToId( path )
	local v = self.eventStrings[ path ]
	if v == nil then
		local eventPath = 'event:/' .. path
		v = self.strings[ eventPath ] or false
		self.eventStrings[ path ] = v
	end
	return v
end

function FMODStudioProject:busToId( path )
	local v = self.busStrings[ path ]
	if v == nil then
		local busPath = 'bus:/' .. path
		v = self.strings[ busPath ] or false
		self.busStrings[ path ] = v
	end
	return v
end

function FMODStudioProject:snapshotToId( path )
	local v = self.snapshotStrings[ path ]
	if v == nil then
		local snapshotPath = 'snapshot:/' .. path
		v = self.strings[ snapshotPath ] or false
		self.snapshotStrings[ path ] = v
	end
	return v
end

function FMODStudioProject:getEventDescription( path )
	local ev = self.eventCache[ path ]
	if ev == nil then
		local id = self:eventToId( path )
		local sys = AudioManager.get():getSystem()
		ev = id and sys:getEventByID( id ) or false
		self.eventCache[ path ] = ev
	end
	return ev
end

-- function FMODStudioProject:getSnapshot( path )
-- 	local ev = self.snapshotCache[ path ]
-- 	if ev == nil then
-- 		local id = self:eventToId( path )
-- 		local sys = AudioManager.get():getSystem()
-- 		ev = id and sys:getEventByID( id ) or false
-- 		self.snapshotCache[ path ] = ev
-- 	end
-- 	return ev
-- end

--------------------------------------------------------------------
CLASS: FMODStudioItem ()
function FMODStudioItem:__init()
	self.parent = false
end

--------------------------------------------------------------------
CLASS: FMODStudioEvent ( FMODStudioItem )
	:MODEL{}

function FMODStudioEvent:__init()
	self.guid = false
	self.path = false
end

function FMODStudioEvent:getSystemID()
	return self.guid
end

--------------------------------------------------------------------
CLASS: FMODStudioProjectFolder ( FMODStudioItem )
	:MODEL{}

function FMODStudioProjectFolder:__init()
	self.id = false
	self.itemType = false
end

function FMODStudioProjectFolder:getFullPath()
	return self.fullPath
end

--------------------------------------------------------------------
local function FMODStudioProjectLoader( node )
	nodePath = node:getPath()
	
	local prevProj = loadedFMODStudioProjects[ nodePath ]
	if prevProj then
		prevProj:unloadAllBanks()
		loadedFMODStudioProjects[ nodePath ] = nil
	end

	local proj = FMODStudioProject()
	local dataPath = node:getObjectFile( 'data' )
	proj:load( dataPath )
	if not game.editorMode then
		proj:updateChildAssetFromBanks( node )
	end

	loadedFMODStudioProjects[ nodePath ] = proj
	return proj
end

local function FMODStudioProjectUnLoader( node, asset )
	local path = node:getPath()
	local proj = loadedFMODStudioProjects[ path ]
	if proj then
		proj:unloadAllBanks()
		loadedFMODStudioProjects[ path ] = nil
	end
	-- print( 'unloading fmod studio project', node:getPath()
	-- local proj = asset
	-- proj:unloadAllBanks()
end

local function FMODStudioFolderLoader( node )
	local folder = FMODStudioProjectFolder()
	return folder
	-- local group = pAsset
	-- local p = node.parent
	-- local pAsset, pNode = loadAsset( p )

	-- if pNode.type == 'fs_project' then
	-- 	local name = node:getName()
	-- 	if name == 'event' then
	-- 		return proj:getEventRootFolder()

	-- 	elseif name == 'snapshot' then
	-- 		return proj:getSnapshotRootFolder()

	-- 	else
	-- 		--TODO
	-- 		_warn( 'not implemented' )
	-- 	end

	-- elseif pNode.type == 'fs_folder' then
	-- 	local folder = FMODStudioProjectFolder()
	-- 	local group = pAsset
	-- 	-- return group:loadSubGroup( node:getName() )

	-- else
	-- 	error( 'bad fmod designer project asset:'..node:getNodePath() )

	-- end
end

local function FMODStudioEventLoader( node )
	local event = FMODStudioEvent()
	event.path = node:getProperty( 'path' )
	event.guid = node:getProperty( 'guid' )
	return event
end

registerAssetLoader( 'fs_project', FMODStudioProjectLoader, FMODStudioProjectUnloader )
registerAssetLoader( 'fs_event',   FMODStudioEventLoader  )
registerAssetLoader( 'fs_folder',  FMODStudioFolderLoader )

--------------------------------------------------------------------
addSupportedSoundAssetType( 'fs_event' )
