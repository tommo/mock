--------------------------------------------------------------------
-- @classmod SQNodeEntity
module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeEntity ( SQNode )
	:MODEL{
		
}

function SQNodeEntity:__init()
	self.cmd = false
	self.proto = false
	self.spawnName = ''
end

function SQNodeEntity:load( data )
	local cmd = data.args[ 1 ]
	self.cmd = cmd
	if cmd == 'show' then
	elseif cmd == 'hide' then
	elseif cmd == 'destroy' then
	elseif cmd == 'deactivate' then
	elseif cmd == 'activate' then
	elseif cmd == 'add' then
		self.proto = data.args[ 2 ]
		self.spawnName = data.args[ 3 ]
	end
end

function SQNodeEntity:enter( state, env )
	local targets = self:getContextEntities( state )
	local cmd = self.cmd
	if cmd == 'show' then
		for i, target in ipairs( targets ) do
			target:show()
		end
	elseif cmd == 'hide' then
		for i, target in ipairs( targets ) do
			target:hide()
		end
	elseif cmd == 'destroy' then
		for i, target in ipairs( targets ) do
			if target.scene then
				target:tryDestroy()
			else
				self:_warn( 'entity destroyed already', target:getName() )
			end
		end
	elseif cmd == 'deactivate' then
		for i, target in ipairs( targets ) do
			target:setActive( false )
		end
	elseif cmd == 'activate' then
		for i, target in ipairs( targets ) do
			target:setActive( true )
		end
	elseif cmd == 'add' then
		local instance
		if self.proto then
			instance = createProtoInstance( self.proto )
			if instance then
				instance:setName( self.spawnName )
				state:getActor():getScene():addEntity(instance)
			else
				self:_error('on found the proto path', self.proto)
			end
		end
	end
end


registerSQNode( 'entity', SQNodeEntity   )


-- --------------------------------------------------------------------
-- CLASS: SQNodeEntitySubCommand ()
-- 	:MODEL{}

-- --class
-- function SQNodeEntitySubCommand.register( class, id )
-- 	return class
-- end

-- function SQNodeEntitySubCommand:load( data )
-- end

-- function SQNodeEntitySubCommand:enter( state, env, dt )
-- end

-- function SQNodeEntitySubCommand:step( state, env, dt )
-- end

-- function SQNodeEntitySubCommand:exit( state, env )
-- end

