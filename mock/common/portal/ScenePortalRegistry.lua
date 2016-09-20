module 'mock'

local PORTAL_DATA_NAME  = 'portal_data.json'


local _scenePortalRegistry

function getScenePortalRegistry()
	_scenePortalRegistry:update()
	return _scenePortalRegistry
end

--------------------------------------------------------------------
CLASS: ScenePortalInfo ()
	:MODEL{}

function ScenePortalInfo:__init()
	self.id    = false
	self.name  = false
	self.scene = false
	self.data  = false
end

function ScenePortalInfo:getConnectedPortal( context )
	return self.connections[ 1 ]
end


--------------------------------------------------------------------
CLASS: ScenePortalRegistry ( GlobalManager )
	:MODEL{}

function ScenePortalRegistry:__init()
	self.portals = {}
	self.connections = {}
	self.graphs  = {}
	self.dirty   = true
end

function ScenePortalRegistry:getPortalInfo( id )
	return self.portals[ id ] or false
end

function ScenePortalRegistry:addGraph( graphPath )
	local graph = loadAsset( graphPath )
	if graph then
		self.graphs[ graphPath ] = graph
	end
	return graph
end

function ScenePortalRegistry:removeGraph( graphPath )
	self.graphs[ graphPath ] = nil
end

function ScenePortalRegistry:hasGraph( path )
	if self.graphs[ path ] then return true end
	return false
end

function ScenePortalRegistry:findConnectedPortal( id )
	local info = self:getPortalInfo( id )
	if not info then
		_warn( 'no portal info found:', id )
		return false
	end
	
	for path, graph in pairs( self.graphs ) do
		local targetId = graph:findConnection( id )
		if targetId then
			return targetId
		end
	end
	return false
end

function ScenePortalRegistry:markDirty()
	self.dirty = true
end

function ScenePortalRegistry:update()
	if self.dirty then
		self:reload()
	end
	return self
end

function ScenePortalRegistry:reload()
	self.dirty = false
	local data = loadGameConfig( PORTAL_DATA_NAME )
	if not data then
		_warn( 'cannot load portal registry' )
		return {} 
	end
	local portals = {}
	for key, itemData in pairs( data ) do
		local info = ScenePortalInfo()
		info.id = key
		info.fullname = itemData[ 'fullname' ]
		info.scene    = itemData[ 'scene' ]
		info.data     = itemData[ 'data' ]
		portals[ key ] = info
	end
	self.portals = portals
end

function ScenePortalRegistry:saveConfig()
	local graphPaths = {}
	for path, graph in pairs( self.graphs ) do
		table.insert( graphPaths, path )
	end
	return {
		graphs = graphPaths
	}
end

function ScenePortalRegistry:loadConfig( data )
	self.graphs = {}
	for i, path in ipairs( data.graphs or {} ) do
		if not self:addGraph( path ) then
			_warn( 'scene portal graph missing', path )
		end
	end
end


--------------------------------------------------------------------
--singleton
_scenePortalRegistry = ScenePortalRegistry()

