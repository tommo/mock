package.path = ''
	.. '../../?.lua;'
	.. '../../?/init.lua;'
	.. package.path

require 'mock'


--------------------------------------------------------------------
CLASS: Main ( mock.Entity )
	:MODEL{}

function Main:onThread()
	self.camera = self:addSibling( mock.Entity() )
	self.camera:attach( mock.Camera() )
	local tex = mock.Texture()
end

--------------------------------------------------------------------
game:init{
	graphics = {
		width  = 500,
		height = 400
	}
}
scene = mock.Scene()
scene:start()
scene:addEntity( Main() )
