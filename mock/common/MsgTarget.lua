module 'mock'

CLASS: MsgTarget ()
	:MODEL{
		Field 'targets' :array( Entity ) :ref();
	}

mock.registerComponent( 'MsgTarget', MsgTarget )

function MsgTarget:__init()
	self.targets = {}
	self.includeChildren = false
end

function MsgTarget:sendMsg( msg, data, source )
	source = source or self
	for i, target in ipairs( self.targets ) do
		if target then
			target:tell( msg, data, source )
		end
	end
end

-- function MsgTarget:pendMsg( msg, data, source )
-- 	self:getEntity()
-- end

