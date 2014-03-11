module 'mock'

--------------------------------------------------------------------

EnumTextureSize = {
	{ '16',   16   },
	{ '32',   32   },
	{ '64',   64   },
	{ '128',  128  },
	{ '256',  256  },
	{ '512',  512  },
	{ '1024', 1024 },
	{ '2048', 2048 },
	{ '4096', 4096 },
	{ '8192', 8192 }
}

--------------------------------------------------------------------
EnumTimerMode = {
	{ 'normal'            , MOAITimer.NORMAL           } ,
	{ 'reverse'           , MOAITimer.REVERSE          } ,
	{ 'continue'          , MOAITimer.CONTINUE         } ,
	{ 'continue_reverse'  , MOAITimer.CONTINUE_REVERSE } ,
	{ 'loop'              , MOAITimer.LOOP             } ,
	{ 'loop_reverse'      , MOAITimer.LOOP_REVERSE     } ,
	{ 'ping_pong'         , MOAITimer.PING_PONG        } ,
}

--------------------------------------------------------------------
EnumTextureFilter = {
	{ 'Linear',    'linear'  },
	{ 'Nearest',   'nearest' }
}

--------------------------------------------------------------------
EnumTextureAtlasMode = {
	{ 'No Atlas',  false },
	{ 'Multiple',  'multiple' },
	{ 'Single',    'single' }
}

--------------------------------------------------------------------
EnumBlendMode = {
	{ 'Alpha',     'alpha'    },
	{ 'Add',       'add'      },
	{ 'Multiply',  'multiply' },
	{ 'Normal',    'normal'   },
	{ 'Solid',     'solid'    },
}

--------------------------------------------------------------------
EnumLayerSortMode = {
	{ "none"                , false },
	{ "iso"                 , 'iso'                  },
	{ "priority_ascending"  , 'priority_ascending'   },
	{ "priority_descending" , 'priority_descending'  },
	{ "x_ascending"         , 'x_ascending'          },
	{ "x_descending"        , 'x_descending'         },
	{ "y_ascending"         , 'y_ascending'          },
	{ "y_descending"        , 'y_descending'         },
	{ "z_ascending"         , 'z_ascending'          },
	{ "z_descending"        , 'z_descending'         },
	{ "vector_ascending"    , 'vector_ascending'     },
	{ "vector_descending"   , 'vector_descending'    },
}


--------------------------------------------------------------------
EnumEaseType={
	{	'ease_in'		     , MOAIEaseType.EASE_IN        },
	{	'ease_out'	     , MOAIEaseType.EASE_OUT       },
	{	'flat'		       , MOAIEaseType.FLAT           },
	{	'linear'		     , MOAIEaseType.LINEAR         },
	{	'sharp_ease_in'  , MOAIEaseType.SHARP_EASE_IN  },
	{	'sharp_ease_out' , MOAIEaseType.SHARP_EASE_OUT },
	{	'sharp_smooth'   , MOAIEaseType.SHARP_SMOOTH   },
	{	'smooth'		     , MOAIEaseType.SMOOTH         },
	{	'soft_ease_in'   , MOAIEaseType.SOFT_EASE_IN   },
	{	'soft_ease_out'  , MOAIEaseType.SOFT_EASE_OUT  },
	{	'soft_smooth'	   , MOAIEaseType.SOFT_SMOOT     },
	{	'back_in'        , MOAIEaseType.BACK_IN        },
	{	'back_out'       , MOAIEaseType.BACK_OUT       },
	{	'back_smooth'	   , MOAIEaseType.BACK_SMOOT     },
	{	'elastic_in'     , MOAIEaseType.ELASTIC_IN     },
	{	'elastic_out'    , MOAIEaseType.ELASTIC_OUT    },
	{	'elastic_smooth' , MOAIEaseType.ELASTIC_SMOOT  },
}

--------------------------------------------------------------------
EnumCameraViewportMode = {
	{ 'EXPANDING', 'expanding' }, --expand to full screen
	{ 'FIXED',     'fixed' },     --fixed size, in device unit
	{ 'RELATIVE',  'relative' },  --relative size, in ratio
}


--------------------------------------------------------------------
EnumTextAlignment = {
	{ 'left'   , 'left'   },
	{ 'center' , 'center' },
	{ 'right'  , 'right'  },
}

--------------------------------------------------------------------
EnumTextAlignmentV = {
	{ 'top'   , 'top'   },
	{ 'center' , 'center' },
	{ 'bottom'  , 'bottom'  },
	{ 'baseline'  , 'baseline'  },
}

--------------------------------------------------------------------
EnumParticleForceType = {
	{ 'force',   MOAIParticleForce. FORCE   },
	{ 'gravity', MOAIParticleForce. GRAVITY },
	{ 'offset',  MOAIParticleForce. OFFSET  },
}
