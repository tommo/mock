module 'mock'

--TODO


--------------------------------------------------------------------
CLASS: PlayerProfile ()
	:MODEL{}

function PlayerProfile:__init()
	self.modules = {}
end

function PlayerProfile:addModule( id, m )
	local queue = table.affirm( self.modules, id, {} )
	table.insert( queue, m )
	return m
end

function PlayerProfile:save()
	for id, queue in pairs( self.modules ) do
		local section = {}
		for i, m in ipairs( queue ) do
		end
	end
end

--------------------------------------------------------------------
CLASS: PlayerProfileModule ()
	:MODEL{}

function PlayerProfileModule:getPriority()
	return 1
end

function PlayerProfileModule:getVersion()
	return 1
end

function PlayerProfileModule:load( version, data )
end

function PlayerProfileModule:save()
	return {

	}
end

function PlayerProfileModule:_load( pack )
	local version = pack.version
	local data = pack.data
	self:load( version, data )
end

function PlayerProfileModule:_save()
	local data = {
		version = self:getVersion(),
		data = self:save()
	}
	return data
end


local playerProfileModuleRegistry = {}
function registerPlayerProfileModule( id, clas )
	playerProfileModuleRegistry[ id ] = clas
end
