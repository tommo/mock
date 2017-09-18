module 'mock'

--------------------------------------------------------------------
CLASS: MovieClipSource ()
	:MODEL{}

function MovieClipSource:__init()
	self.mode = false
	self.path = false
end

function MovieClipSource:load( path )
	self.path = path
	self.mode = 'file'
end

function MovieClipSource:buildClipInstance( option )
	if self.mode == 'file' then
		local clip = MOAIMovieClip.new()
		clip:load( self.path )
		return clip
	end
	return nil
end

--------------------------------------------------------------------
local function MovieLoader( node )
	local format = node:getProperty( 'format' )
	local src = MovieClipSource()
	src:load( node:getObjectFile( 'data' ) )
	return src
end

registerAssetLoader( 'movie', MovieLoader )