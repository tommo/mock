module 'mock'

CLASS: MsgBroadcast ( mock.Behaviour )
	:MODEL{
		Field 'targets' :array( mock.Entity );
	}

mock.registerComponent( 'MsgBroadcast', MsgBroadcast )

--------------------------------------------------------------------
function MsgBroadcast:__init()
	self.targets = {}
end

--------------------------------------------------------------------
function MsgBroadcast:onMsg( msg, data, source )
	for i, target in ipairs( self.targets ) do
		if target then
			target:tell( msg, data, source )
		end
	end
end

--------------------------------------------------------------------
function MsgBroadcast:onBuildGizmo()
	return mock_edit.IconGizmo( 'split.png' )
end

