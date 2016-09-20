module 'mock'

--------------------------------------------------------------------
CLASS: ScenePortal ( Component )
	:MODEL{
		Field 'name' :string();
		Field 'comment' :string();
	}

mock.registerComponent( 'ScenePortal', ScenePortal )


function ScenePortal:__init()
	self.name = ''
	self.comment = ''
end

function ScenePortal:getScenePortalManager()
	local scn = self:getScene()
	return scn and scn:getManager( 'ScenePortalManager' )
end

function ScenePortal:onAttach( ent )
	local manager = self:getScenePortalManager()
	manager:registerPortal( self )
end

function ScenePortal:onDetach( ent )
	local manager = self:getScenePortalManager()
	manager:unregisterPortal( self )
end

function ScenePortal:_enter( session )
	self:tell( 'scene_portal.enter', session )
	return self:onEnter( session )
end

function ScenePortal:_exit( session )
	self:tell( 'scene_portal.exit', session )
	return self:onExit( session )
end

function ScenePortal:onEnter( session )
end

function ScenePortal:onExit( session )
end

function ScenePortal:exportData()
	local ent = self:getEntity()
	local data = {
		id          = self:getFullname(),
		name        = self.name,
		guid        = ent.__guid,
		--
		loc         = { ent:getLoc() },
		entityName  = ent:getName(),
		comment     = self.comment
	}
	return data
end

function ScenePortal:goto( targetId )
	local manager = self:getScenePortalManager()
	local fullname = self:getFullname()
	manager:startPorting( fullname, targetId )
end

function ScenePortal:gotoConnectedPortal()
	local targetId = self:findConnectedPortal()
	if not targetId then
		_warn( 'no connected portal found:', self:getFullname() )
		return false
	end
	return self:goto( targetId )
end

function ScenePortal:findConnectedPortal()
	local registry = getScenePortalRegistry()
	local fullname = self:getFullname()
	local info = registry:getPortalInfo( fullname )
	if not info then return false end
	
end

function ScenePortal:getFullname()
	local manager = self:getScenePortalManager()
	local fullId = self.name
	local namespace = manager.portalNameSpace
	if namespace and namespace ~= '' then
		fullId = namespace .. '.' .. fullId
	end
	return fullId
end
