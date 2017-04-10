module 'mock'

local _SceneManagerFactoryRegistry = {}
--TODO: release on module refreshing
function registerSceneManagerFactory( key, factory )
	for i, fac0 in pairs( _SceneManagerFactoryRegistry ) do
		local key0 = fac0._key
		if key0 == key then
			_warn( 'duplicated scene config factory, overwrite', key )
			_SceneManagerFactoryRegistry[ i ] = factory
			return
		end
	end
	factory._key = key
	table.insert( _SceneManagerFactoryRegistry, factory )
	_stat( 'register scene manager', key )
end

function getSceneManagerFactoryRegistry()
	return _SceneManagerFactoryRegistry
end


--------------------------------------------------------------------
CLASS: SceneManagerFactory ()
	:MODEL{}

function SceneManagerFactory:__init()
	self._key = false
end

function SceneManagerFactory:create( scn )
	return false
end

function SceneManagerFactory:getKey()
	return self._key
end

function SceneManagerFactory:accept( scn )
	if scn.FLAG_EDITOR_SCENE then return false end
	return true
end

--------------------------------------------------------------------
CLASS: SceneManager ()
	:MODEL{}

function SceneManager:__init()
	self.scene = false
end

function SceneManager:init( scn )
	self.scene = scn
	self:onInit( scn )
end

function SceneManager:clear()
	self:onClear()
end

function SceneManager:reset()
	self:onReset()
end

function SceneManager:start()
	self:onStart()
end


function SceneManager:onClear()
end

function SceneManager:onReset()
end

function SceneManager:onLoad()
end

function SceneManager:onStart()
end

function SceneManager:postStart()
end

function SceneManager:getScene()
	return self.scene
end

function SceneManager:getKey()
	return self._key
end

function SceneManager:onInit( scene )
end

function SceneManager:serialize()
	return {}
end

function SceneManager:deserialize( data )
end

--------------------------------------------------------------------
