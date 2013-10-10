module 'character'


--------------------------------------------------------------------
CLASS: CharacterActionEvent ()
	:MODEL{		
	}

function CharacterActionEvent:__init()
	self.actions = {}
end

function CharacterActionEvent:start()
end

function CharacterActionEvent:tostring()
end

--------------------------------------------------------------------
CLASS: CharacterActionTrack ()
	:MODEL{
		Field 'name' :string();		
		Field 'events' :array( CharacterActionEvent ) :no_edit();		
	}

function CharacterActionTrack:__init()
	self.name = 'track'
	self.actions = {}
end


--------------------------------------------------------------------
CLASS: CharacterAction ()
	:MODEL{
		Field 'name' :string();		
		Field 'tracks' :array( CharacterActionTrack ) :no_edit();		
	}

function CharacterAction:__init()
	self.name = 'action'
	self.tracks = {}
end

function CharacterAction:start()
end

--------------------------------------------------------------------
CLASS: CharacterConfig ()
	:MODEL{
		Field 'name'    :string();
		Field 'spine'   :asset('spine');
		Field 'actions' :array( CharacterAction ) :no_edit();		
	}

function CharacterConfig:__init()
	self.name    = 'character'
	self.actions = {}
end

function CharacterConfig:addAction( name )
	if not self.actions then self.actions = {} end
	local action = CharacterAction()
	action.name = name
	table.insert( self.actions, action )
	return action
end

function CharacterConfig:removeAction( act )
	for i, a in ipairs( self.actions ) do
		if act == a then
			table.remove( self.actions, i )
			return
		end
	end
end

--------------------------------------------------------------------

local function loadCharacterConfig( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )
	return config
end

mock.registerAssetLoader( 'character', loadCharacterConfig )
