module 'mock'

CLASS: StoryNodeFlag ( StoryNode )
	:MODEL{}

function StoryNodeFlag:__init()
	self.exprFunc = false
end

function StoryNodeFlag:onStateUpdate( state )
	local flag = self.exprFunc( state )
	if flag then
		if self.hasYesRoute then return true end
	else
		if self.hasNotRoute then return false end
	end
	return 'running' --block until flag changed
end

function StoryNodeFlag:onStateExit( state )
end

function StoryNodeFlag:onLoad( nodeData )
	--TODO:parse expression
	local text = self.text
	local scope, flagName
	if text:startwith( '$$' ) then
		scope = 'global'
		flagName = text:sub(3)
	elseif text:startwith( '$' ) then
		scope = 'scope'
		flagName = text:sub(2)
	else
		scope = 'local'
		flagName = text
	end
	
	self.exprFunc = function( state )
		local dict
		if scope == 'local' then
			dict = state:getLocalFlagDict( self )
		elseif scope == 'global' then
			dict = state:getGlobalFlagDict()
		elseif scope == 'scope' then
			dict = state:getScopeFlagDict( self )
		end
		local value = dict:get( flagName )
		return value
	end

	local hasNotRoute, hasYesRoute = false, false
	for i, r in pairs( self.routesOut ) do
		if r.type == 'NOT' then
			hasNotRoute = true
		else
			hasYesRoute = true
		end
	end
	self.hasNotRoute = hasNotRoute
	self.hasYesRoute = hasYesRoute
end


--------------------------------------------------------------------
CLASS: StoryNodeFlagSet ( StoryNode )
	:MODEL{}

function StoryNodeFlagSet:__init()
	self.setterFunc = false
end

function StoryNodeFlagSet:onStateEnter( state, prevNode, prevResult )
	self.setterFunc( state )
end

function StoryNodeFlagSet:onLoad( nodeData )
	--TODO:parse expression
	local text = self.text
	local scope, flagName
	if text:startwith( '$$' ) then
		scope = 'global'
		flagName = text:sub(3)
	elseif text:startwith( '$' ) then
		scope = 'scope'
		flagName = text:sub(2)
	else
		scope = 'local'
		flagName = text
	end
	
	self.setterFunc = function( state )
		local dict
		if scope == 'local' then
			dict = state:getLocalFlagDict( self )
		elseif scope == 'global' then
			dict = state:getGlobalFlagDict()
		elseif scope == 'scope' then
			dict = state:getScopeFlagDict( self )
		end
		dict:set( flagName, true )
	end
end


--------------------------------------------------------------------
CLASS: StoryNodeFlagRemove ( StoryNode )
	:MODEL{}

function StoryNodeFlagRemove:__init()
	self.removerFunc = false
end

function StoryNodeFlagRemove:onStateEnter( state, prevNode, prevResult )
	self.removerFunc( state )
end

function StoryNodeFlagRemove:onLoad( nodeData )
	--TODO:parse expression
	local text = self.text
	local scope, flagName
	if text:startwith( '$$' ) then
		scope = 'global'
		flagName = text:sub(3)
	elseif text:startwith( '$' ) then
		scope = 'scope'
		flagName = text:sub(2)
	else
		scope = 'local'
		flagName = text
	end
	
	self.removerFunc = function( state )
		local dict
		if scope == 'local' then
			dict = state:getLocalFlagDict( self )
		elseif scope == 'global' then
			dict = state:getGlobalFlagDict()
		elseif scope == 'scope' then
			dict = state:getScopeFlagDict( self )
		end
		dict:set( flagName, false )
	end
end

registerStoryNodeType( 'FLAG', StoryNodeFlag  )
registerStoryNodeType( 'FLAG_SET', StoryNodeFlagSet  )
registerStoryNodeType( 'FLAG_REMOVE', StoryNodeFlagRemove  )
