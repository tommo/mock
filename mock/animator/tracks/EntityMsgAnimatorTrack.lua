module 'mock'


--------------------------------------------------------------------
CLASS: EntityMessageAnimatorKey ( AnimatorEventKey )
	:MODEL{
		Field 'msg'  :string();
		Field 'data' :string();
	}

function EntityMessageAnimatorKey:__init()
	self.msg  = ''
	self.data = ''
end

function EntityMessageAnimatorKey:toString()
	return self.msg
end


--------------------------------------------------------------------
CLASS: EntityMessageAnimatorTrack ( AnimatorEventTrack )
	:MODEL{
	}


function EntityMessageAnimatorTrack:getIcon()
	return 'track_msg'
end

function EntityMessageAnimatorTrack:toString()
	local pathText = self.targetPath:toString()
	return pathText..':(MSG)'
end


function EntityMessageAnimatorTrack:createKey( pos, context )
	local key = EntityMessageAnimatorKey()
	key:setPos( pos )
	self:addKey( key )
	return key
end

function EntityMessageAnimatorTrack:build( context )
	self.idCurve = self:buildIdCurve()
	context:updateLength( self:calcLength() )
end

function EntityMessageAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local entity = self.targetPath:get( rootEntity, scene )
	local playContext = { entity, 0 }
	state:addUpdateListenerTrack( self, playContext )
end

function EntityMessageAnimatorTrack:apply( state, playContext, t )
	local entity = playContext[1]
	local keyId = playContext[2]
	local newId = self.idCurve:getValueAtTime( t )
	if keyId ~= newId and newId > 0 then
		local key = self.keys[ newId ]
		playContext[2] = newId
		local msg  = key.msg
		local data = key.data
		entity:tell( msg, data )
	end
end

function EntityMessageAnimatorTrack:reset( state, playContext )
	-- playContext[2] = 0
end

--------------------------------------------------------------------
registerCustomAnimatorTrackType( Entity, 'Message', EntityMessageAnimatorTrack )
