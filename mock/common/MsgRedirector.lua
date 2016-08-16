module 'mock'

CLASS: MsgParentRedirector ()
	:MODEL{		
	}

mock.registerComponent( 'MsgParentRedirector', MsgParentRedirector )

function MsgParentRedirector:__init()
end

function MsgParentRedirector:onAttach( ent )	
	self.msgListener = ent:addMsgListener( 
		function( msg, data, source )
			local p = ent.parent
			if p then
				return p:tell( msg, data, source )
			end			
		end
	)
end

function MsgParentRedirector:onDetach( ent )
	ent:removeMsgListener( self.msgListener )
end
