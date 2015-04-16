module 'character'

--------------------------------------------------------------------
local _messageKeyTypes = {}

function registerActionMessageKeyType( t, clas )
	if _messageKeyTypes[ t ] then
		_error( 'duplicated action message key type', t )
	end
	_messageKeyTypes[ t ]	 = clas
end

--------------------------------------------------------------------
CLASS: TrackMessage ( CharacterActionTrack )
	:MODEL{}

function TrackMessage:__init()
	self.name = 'message'
end

function TrackMessage:getType()
	return 'message'
end

function TrackMessage:getDefaultKeyType()
	return 'simple'
end

function TrackMessage:getKeyTypes()
	local names = {}
	for k,clas in pairs( _messageKeyTypes ) do
		table.insert( names, k )
	end
	table.sort( names )
	return names
end

function TrackMessage:createKey( evType )
	local clas = _messageKeyTypes[ evType ]
	assert( clas )
	return clas()
end

function TrackMessage:toString()
	return '<msg>' .. tostring( self.name )
end


--------------------------------------------------------------------
CLASS: KeyMessage ( CharacterActionKey )
	:MODEL{
		Field 'message' :string();
		Field 'arg'     :string()
	}
function KeyMessage:__init()
	self.length = 0
	self.name   = 'message'
	self.arg    = false
end

function KeyMessage:isResizable()
	return true
end

function KeyMessage:start( state, pos )	
	state.target:tell( self.message, self )
end

function KeyMessage:toString()
	return tostring( self.message )
end


--------------------------------------------------------------------
registerCharacterActionTrackType( 'Message', TrackMessage )
registerActionMessageKeyType( 'simple', KeyMessage )

