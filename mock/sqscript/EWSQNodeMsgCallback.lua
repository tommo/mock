--------------------------------------------------------------------
CLASS: EWSQNodeMsgCallback ( mock.SQNodeMsgCallback )


function EWSQNodeMsgCallback:enter( state, env )
	if self:hasTag('cutscene') then
		emitGlobalSignal( 'ew.cutscene.on' )
	end
end

function EWSQNodeMsgCallback:exit( state, env )
	if self:hasTag('cutscene') then
		emitGlobalSignal( 'ew.cutscene.off' )
	end
end

--------------------------------------------------------------------
-- mock.registerSQNode( 'on', EWSQNodeMsgCallback )