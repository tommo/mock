module 'mock'

CLASS: JoystickConfig ()
	:MODEL{}

function JoystickConfig:__init( data )
	local buttonIdToName = {}
	local buttonNameToId = {}
	for name, id in pairs( data.buttons ) do
		buttonIdToName[ id ] = name
		buttonNameToId[ name ] = id
	end
	self.buttonIdToName = buttonIdToName
	self.buttonNameToId = buttonNameToId

	local axisIdToName = {}
	local axisNameToId = {}
	for name, id in pairs( data.axises or {} ) do
		axisIdToName[ id ] = name
		axisNameToId[ name ] = id
	end
	self.axisIdToName = axisIdToName
	self.axisNameToId = axisNameToId

end

function JoystickConfig:getBtnName( id )
	return self.buttonIdToName[ id ] or nil
end

function JoystickConfig:getBtnId( name )
	return self.buttonNameToId[ name ] or nil
end

function JoystickConfig:getAxisName( id )
	return self.axisIdToName[ id ] or nil
end

function JoystickConfig:getAxisId( name )
	return self.axisNameToId[ name ] or nil
end

--------------------------------------------------------------------
JoystickConfigPS3 = JoystickConfig {
	axises  = {
		['L.x'   ]   = 1   ;
		['L.y'   ]   = 2   ;
		['R.x'   ]   = 3   ;
		['R.y'   ]   = 4   ;
	};
	buttons = {
		['select']   = 0   ;
		['L3'    ]   = 1   ;
		['R3'    ]   = 2   ;
		['start' ]   = 3   ;
		['up'    ]   = 4   ;
		['right' ]   = 5   ;
		['down'  ]   = 6   ;
		['left'  ]   = 7   ;
		['a'     ]   = 14  ;
		['b'     ]   = 13  ;
		['x'     ]   = 15  ;
		['y'     ]   = 12  ;
		['L1'    ]   = 10  ;
		['R1'    ]   = 11  ;
		['L2'    ]   = 8   ;
		['R2'    ]   = 9   ;
	}
}


--------------------------------------------------------------------
JoystickConfigXBox360 = JoystickConfig {
	axises  = {
		['L.x'   ] = 0  ;
		['L.y'   ] = 1  ;
		['R.x'   ] = 5  ;
		['R.y'   ] = 4  ;
		['LT'    ] = 2  ;
		['RT'    ] = 3  ;
	};
	buttons = {
		['up'    ] = 11 ;
		['right' ] = 14 ;
		['down'  ] = 12 ;
		['left'  ] = 13 ;
		['x'     ] = 2  ;
		['y'     ] = 3  ;
		['a'     ] = 0  ;
		['b'     ] = 1  ;
		['L1'    ] = 4  ;
		['R1'    ] = 5  ;
		['L3'    ] = 6  ;
		['R3'    ] = 7  ;
		['back'  ] = 9  ;
		['start' ] = 8  ;
		['xbox'  ] = 10 ;
	}
}