module 'character'
--------------------------------------------------------------------
CLASS: Character ()
	:MODEL{
		Field 'config': asset('character');
		Field 'default' : string();
	}

function Character:__init()
	self.config  = false
	self.default = 'default'
end

--------------------------------------------------------------------
mock.registerComponent( 'Character', Character )
