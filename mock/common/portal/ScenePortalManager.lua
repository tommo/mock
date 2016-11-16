module 'mock'

--------------------------------------------------------------------
CLASS: ScenePortalManagerFactory ( mock.SceneManagerFactory )
	:MODEL{} 

function ScenePortalManagerFactory:create( scn )
	return ScenePortalManager()
end

function ScenePortalManagerFactory:accept( scn )
	return scn:isMainScene()
end

mock.registerSceneManagerFactory( 'ScenePortalManager', ScenePortalManagerFactory() )


--------------------------------------------------------------------
CLASS: ScenePortalManager ( SceneManager )
	:MODEL{
		Field 'portalNameSpace' :string()
	}

function ScenePortalManager:__init()
	self.portalNameSpace = ''
	self.portals         = {}
	self.portalMap       = false
end

function ScenePortalManager:registerPortal( portal )
	self.portals[ portal ] = true
	self.portalMap = false
end

function ScenePortalManager:unregisterPortal( portal )
	self.portals[ portal ] = nil
	self.portalMap = false
end

function ScenePortalManager:affirmPortalMap()
	if self.portalMap then return self.portalMap end
	local map = {}
	for portal in pairs( self.portals ) do
		local fullname = portal:getFullname()
		if map[ fullname ] then
			_warn( 'duplicated portal:', fullname )
		else
			map[ fullname ] = portal
		end
	end
	self.portalMap = map
	return map
end

function ScenePortalManager:findPortalInCurrentScene( id )
	local map = self:affirmPortalMap()
	return map[ id ] or false
end


local function nameSortFunc( a, b )
	return ( a.name or '') < ( b.name or '' )
end
function ScenePortalManager:serialize()
	local data = {}
	local portalDatas = {}
	local namespace = ( self.portalNameSpace or '' ):trim()
	if namespace == '' then namespace = false end
	for portal in pairs( self.portals ) do
		local portalData = portal:exportData()
		if portalData then
			local name = portalData[ 'name' ]
			local fullname = namespace and ( namespace .. '.' .. name ) or name
			portalData[ 'fullname' ] = fullname
			table.insert( portalDatas, portalData )
		end
	end
	table.sort( portalDatas, nameSortFunc )
	data[ 'portals' ] = portalDatas
	data[ 'namespace' ] = self.portalNameSpace
	return data
end

function ScenePortalManager:deserialize( data )
	--no deserialize from portal data
	self.portalNameSpace = data [ 'namespace' ] or ''
end

function ScenePortalManager:startPorting( portalId0, portalId1, options )
	local scene = self:getScene()
	local scenePath = scene.assetPath
	
	local registry = getScenePortalRegistry()
	if not registry then
		return error( 'cannot load portal registry' )
	end
	local portalInfo0 = getScenePortalRegistry():getPortalInfo( portalId0 )
	local portalInfo1 = getScenePortalRegistry():getPortalInfo( portalId1 )
	
	if not ( portalInfo0 and portalInfo1 ) then
		if not portalInfo0 then
			_error( 'cannot find portal:', portalId0 )
		end
		if not portalInfo1 then
			_error( 'cannot find portal:', portalId1 )
		end
		return false
	end

	local portingSession = {
		from    = portalInfo0,
		to      = portalInfo1,
		options = options
	}
	
	local portal0 = self:findPortalInCurrentScene( portalId0 )
	if portal0 then
		portal0:_exit( portingSession )
	end
	
	local toScenePath = portalInfo1.scene
	if scenePath == toScenePath then
		--same scene
		self.portingSession = portingSession
		return self:finishPorting()
	else
		--open scene
		game:scheduleOpenSceneByPath( toScenePath, false, {
				portingSession = portingSession
			}
		)
	end

end

function ScenePortalManager:onLoad()
	local scene = self:getScene()
	if not scene:isMainScene() then return end
	local portingSession = scene:getArgument( 'portingSession', false )
	if portingSession then
		_stat( 'porting session found', 
			portingSession.from.id, portingSession.from.scene,
			portingSession.to.id, portingSession.to.scene
		)
		self.portingSession = portingSession
		return self:finishPorting()
	end
end

function ScenePortalManager:finishPorting()
	local portingSession = self.portingSession
	if not portingSession then return end
	self.portingSession = false
	local targetPortalId = portingSession.to.id
	local targetPortal = self:findPortalInCurrentScene( targetPortalId )
	if not targetPortal then
		return _error( 'failed to find target portal', targetPortalId )
	end
	targetPortal:_enter( portingSession )
end

