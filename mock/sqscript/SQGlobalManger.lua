module 'mock'

local _SQGlobalManger

function getSQGlobalManager()
	return _SQGlobalManger
end

--------------------------------------------------------------------
CLASS: SQGlobalManger ( GlobalManager )
 	:MODEL{} 

function SQGlobalManger:__init()
	_SQGlobalManger = self
end

function SQGlobalManger:postInit( game )
	for _, provider in pairs( getSQContextProviders() ) do
		provider:init()
	end
end

--------------------------------------------------------------------
SQGlobalManger()