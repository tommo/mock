--------------------------------------------------------------------
-- @classmod SQNodeEntity
module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeEntity ( SQNode )
	:MODEL{
		
}

function SQNodeEntity:__init()
	self.cmd = false
end

function SQNodeEntity:load( data )
	local cmd = data.args[ 1 ]
	self.cmd = cmd
	if cmd == 'show' then
	elseif cmd == 'hide' then
	elseif cmd == 'destroy' then
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
			target:destroy()
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

