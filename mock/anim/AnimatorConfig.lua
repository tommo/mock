module 'mock'
local loadAnimatorConfig
CLASS: AnimatorConfig ()

--------------------------------------------------------------------
AnimatorConfig	:MODEL{
		Field 'name'    :string();
		'----';
		Field 'actions' :array( AnimatorClip ) :no_edit();		
		'----';
		Field 'baseConfig' :asset( 'character' );
	}

function AnimatorConfig:__init()
	self.name    = 'character'
	self.baseConfig = false
	self.actions = {}
	self.simpleSkeleton = false
	self.scale   = 1
end

function AnimatorConfig:getSpine()
	return self.spinePath
end

function AnimatorConfig:setSpine( path )
	self.spinePath = path
end

function AnimatorConfig:setBaseCharacter( baseCha )
	self.baseConfig = baseCha
	--unload previous ref actions
	local newActions = {}
	for i, act in ipairs( self.actions ) do
		if not act.inherited then
			table.insert( newActions, act )
		end
	end
	self.actions = newActions
	self:loadBaseCharacter()
end

function AnimatorConfig:loadBaseCharacter()
	--TODO: cyclic refer detection!!!
	local loadedConfig = { self }
	if not self.baseConfig then return end
	local baseConfig = loadAnimatorConfig( self.baseConfig )
	if not baseConfig then
		_error( 'failed to load parent character config')
		return
	end
	--clone track
	for i, act in ipairs( baseConfig.actions ) do
		local newAct = self:addAction()
		mock.clone( act, newAct )
		newAct.inherited = true
	end
end

function AnimatorConfig:addAction( name )
	if not self.actions then self.actions = {} end
	local action = AnimatorClip()
	action.name = name
	table.insert( self.actions, action )
	action.parent = self
	return action
end

function AnimatorConfig:removeAction( act )
	for i, a in ipairs( self.actions ) do
		if act == a then
			table.remove( self.actions, i )
			return
		end
	end
end

function AnimatorConfig:getAction( name )
	for i, act in ipairs( self.actions ) do
		if act.name == name then return act end
	end
	return nil
end

function AnimatorConfig:sortEvents() --pre-serialization
	for i, action in ipairs( self.actions ) do
		for _, track in ipairs( action.tracks ) do
			track:sortEvents()
		end
	end
end

--------------------------------------------------------------------
--------------------------------------------------------------------
function loadAnimatorConfig( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )
	if config then --set parent nodes
		for i, act in ipairs( config.actions ) do
			act.parent = config		
			for i, track in ipairs( act.tracks ) do
				track.parent = act
				for i, event in ipairs( track.events ) do
					event.parent = track
				end
			end
		end
	end
	return config
end

mock.registerAssetLoader( 'animation', loadAnimatorConfig )
