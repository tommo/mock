module 'mock'


--------------------------------------------------------------------
CLASS: SoundSourceAnimatorKey ( AnimatorEventKey )
	:MODEL{
		Field 'clip' :asset('fmod_event') :set( 'setClip' );
	}

function SoundSourceAnimatorKey:__init()
	self.clip   = ''
end

function SoundSourceAnimatorKey:setClip( clip )
	self.clip = clip
end

function SoundSourceAnimatorKey:toString()
	local clip = self.clip
	if not clip then return '<nil>' end
	return stripdir( clip )
end

--------------------------------------------------------------------
CLASS: SoundSourceAnimatorTrack ( AnimatorEventTrack )
	:MODEL{
	}

function SoundSourceAnimatorTrack:getIcon()
	return 'track_audio'
end

function SoundSourceAnimatorTrack:toString()
	local pathText = self.targetPath:toString()
	return pathText..'<clips>'
end

function SoundSourceAnimatorTrack:isPreviewable()
	return false
end

function SoundSourceAnimatorTrack:createKey( pos, context )
	local key = SoundSourceAnimatorKey()
	key:setPos( pos )
	self:addKey( key )
	local target = context.target --SoundSource
	key.clip     = target:getDefaultClip()
	return key
end

function SoundSourceAnimatorTrack:build( context )
	self.idCurve = self:buildIdCurve()
	context:updateLength( self:calcLength() )
end

function SoundSourceAnimatorTrack:onStateLoad( state )
	local rootEntity, scene = state:getTargetRoot()
	local soundSource = self.targetPath:get( rootEntity, scene )
	local playContext = { soundSource, 0 }
	state:addUpdateListenerTrack( self, playContext )
end

function SoundSourceAnimatorTrack:apply( state, playContext, t )
	local soundSource = playContext[1]
	local keyId = playContext[2]
	local newId = self.idCurve:getValueAtTime( t )
	if keyId ~= newId then
		playContext[2] = newId
		if newId > 0 then
			local key = self.keys[ newId ]
			local clip = key.clip
			if clip then
				if soundSource.is3D then
					soundSource:playEvent3D( clip, soundSource.follow )
				else
					soundSource:playEvent2D( clip )
				end
			end
		end
	end
end

function SoundSourceAnimatorTrack:reset( state, playContext )
	-- playContext[2] = 0
end



--------------------------------------------------------------------
registerCustomAnimatorTrackType( SoundSource, 'clips', SoundSourceAnimatorTrack )
