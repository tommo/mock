
CLASS: TempoMusic ()
	:MODEL{
		Field 'music' :asset( 'fmod_event' );
		Field 'BPM' :meta{ step = 0.5 };
		Field 'slice' :int();
		Field 'offset' :meta{ step = 0.01 };
		Field 'accentOffset' :int();
		Field 'beatPoints': array( 'number' ) :no_edit();
	}

function TempoMusic:__init()
	self.music      = false
	self.BPM        = 120
	self.offset     = 0
	self.slice      = 4
	self.beatPoints = {}
	self.accentOffset = 0
end

--------------------------------------------------------------------
local function loadTempoMusic( node )
	local data   = mock.loadAssetDataTable( node:getObjectFile('config') )
	local config = mock.deserialize( nil, data )	
	return config
end

mock.registerAssetLoader( 'tempo_music', loadTempoMusic )
