module 'character'

CLASS: CharacterActionEvent ()
CLASS: CharacterActionTrack ()
--------------------------------------------------------------------
CharacterActionEvent
:MODEL{		
		Field 'pos'    :range(0);
		Field 'length' :range(0);
		Field 'parent' :type( CharacterActionTrack ) :no_edit();		
	}

function CharacterActionEvent:__init()
	self.pos    = 0
	self.length = 10
end

function CharacterActionEvent:start()
end

function CharacterActionEvent:tostring()
end

--------------------------------------------------------------------

CharacterActionTrack
:MODEL{
		Field 'name' :string();		
		Field 'events' :array( CharacterActionEvent ) :no_edit();		
	}

function CharacterActionTrack:__init()
	self.name = 'track'
	self.events = {}
end

function CharacterActionTrack:addEvent( pos )
	local ev = CharacterActionEvent()
	table.insert( self.events, ev )
	ev.parent = self
	ev.pos = pos
	ev.length = 10
	return ev
end

function CharacterActionTrack:removeEvent( ev )
	for i, e in ipairs( self.events ) do
		if e == ev then return table.remove( self.events, i )  end
	end	
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

function CharacterAction:addTrack()
	local track = CharacterActionTrack()
	table.insert( self.tracks, track )
	return track
end

function CharacterAction:removeTrack( track )
	for i, t in ipairs( self.tracks ) do
		if t == track then return table.remove( self.tracks, i )  end
	end	
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
