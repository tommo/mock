module 'mock'

CLASS: MsgTranslator ()
	:MODEL{		
	}

mock.registerComponent( 'MsgTranslator', MsgTranslator )

function MsgTranslator:__init()
end

function MsgTranslator:onAttach( ent )	
	self.msgListener = ent:addMsgListener( 
		function( msg, data, source )
			local p = ent.parent
			if p then
				return p:tell( msg, data, source )
			end			
		end
	)
end

function MsgTranslator:onDetach( ent )
	ent:removeMsgListener( self.msgListener )
end
