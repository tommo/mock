module 'mock'

local generateGUID = MOAIEnvironment.generateGUID

--------------------------------------------------------------------
local function affirmGUID( entity )
	if not entity.__guid then
		entity.__guid = generateGUID()
	end
	for com in pairs( entity.components ) do
		if not com.__guid then
			com.__guid = generateGUID()
		end
	end
	for child in pairs( entity.children ) do
		affirmGUID( child )
	end
end

local function affirmSceneGUID( scene )
	--affirm guid
	for entity in pairs( scene.entities ) do
		affirmGUID( entity )
	end
end

local function reallocGUID( entity )
	for com in pairs( entity.components ) do
		com.__guid = generateGUID()
	end
	for child in pairs( entity.children ) do
		reallocGUID( child )
	end
end


_M.affirmGUID      = affirmGUID
_M.affirmSceneGUID = affirmSceneGUID
_M.reallocGUID     = reallocGUID