module 'mock'
--------------------------------------------------------------------
CLASS: MovieClipPlane ( GraphicsPropComponent )
	:MODEL{
		Field 'texture' :no_edit();
		Field 'movie' :asset( 'movie' ) :getset( 'Movie' );
		Field 'autoplay' :boolean();
		Field 'playMode' :enum( EnumTimerMode );
		'----';
		Field 'size'    :type('vec2') :getset('Size');
}

registerComponent( 'MovieClipPlane', MovieClipPlane )

function MovieClipPlane:__init( )
	self.moviePath = false
	self.clip = false
	self.autoplay = false
	self.playMode = MOAITimer.NORMAL
	self.quad = MOAIGfxQuad2D.new()
	self.quad:setUVRect( 0,0,1,1 )
	self.quad:setRect( 0,0,0,0 )
	self.prop:setDeck( self.quad )
	self.w = 100
	self.h = 100
end

function MovieClipPlane:onStart( )
	if self.autoplay and self.moviePath then
		self:playClip( self.moviePath )
	end
end

function MovieClipPlane:playClip( clipPath, fitSize )
	local movieSrc = loadAsset( clipPath )
	if not movieSrc then return false end
	self:stop()
	local clip = movieSrc:buildClipInstance( self )
	if not clip then return false end
	local tex = clip:getTexture()
	self.clip = clip
	self.quad:setTexture( tex )
	clip:start()
	local w, h = clip:getSize()
	local tw, th = tex:getSize()
	local u = w/tw
	local v = h/th
	self.quad:setUVRect( 0,v,u,0 )
	if fitSize then
		self:fitSize()
	end
	return true
end

function MovieClipPlane:setMovie( moviePath )
	self.moviePath = moviePath
end

function MovieClipPlane:getMovie()
	return self.moviePath
end

function MovieClipPlane:fitSize()
	if not self.clip then return end
	local w, h = self.clip:getSize()
	self:setSize( w, h )
end

function MovieClipPlane:stop()
	-- body
	if self.clip then
		self.clip:stop()
	end
end

function MovieClipPlane:seek( t )
	--TODO
end

function MovieClipPlane:getSize()
	return self.w, self.h
end

function MovieClipPlane:setSize( w, h )
	self.w = w
	self.h = h
	self.quad:setRect( -w/2,-h/2,w/2,h/2 )
	self.prop:forceUpdate()
end
