--------------------------------------------------------------------
-- @classmod SQNodeScene
module 'mock'

--------------------------------------------------------------------
CLASS: SQNodeScene ( SQNode )
	:MODEL{
		
}

function SQNodeScene:__init()
	self.cmd = false
end

function SQNodeScene:load( data )
	self.cmd = data.args[ 1 ]
	self.path = data.args[ 2 ]
end

function SQNodeScene:enter( state, env )
	local cmd = self.cmd
	local path = self.path
	if cmd == 'open' then
		if not hasAsset( path ) then
			path = game.scenes[ path ]
			if not ( path and hasAsset( path ) ) then
				path = false
			end
		end
		
		if not path then
			if self.path then
				return self:_error( 'no scene found for name:', self.path )
			else
				return self:_warn( 'no scene specified' )
			end
		end
		game:scheduleOpenSceneByPath( path )

	elseif cmd == 'add' then
		game:openSceneByPath( path, true )

	end
end


registerSQNode( 'scene', SQNodeScene )

