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

local function affirmSceneGroupGUID( group )
	if not group.__guid then
		group.__guid = generateGUID()
	end
	for childGroup in pairs( group.childGroups ) do
		affirmSceneGroupGUID( childGroup )
	end
end

local function affirmSceneGUID( scene )
	--affirm entity guid
	for entity in pairs( scene.entities ) do
		affirmGUID( entity )
	end
	--affirm group guid
	for i, rootGroup in ipairs( scene.rootGroups ) do
		affirmSceneGroupGUID( rootGroup )
	end
end

local function _reallocObjectGUID( obj, replaceMap )
	local id0 = obj.__guid
	local id1
	if not id0 then
		id1 = generateGUID()
		replaceMap[ id0 ] = id1
	else
		local base, ns = id0:match( '(.*:)(%w+)$' )
		if not ns then
			id1 = generateGUID()
			replaceMap[ id0 ] = id1
		else
			local ns1 = replaceMap[ ns ]
			if ns1 then
				id1 = base .. ns1
				replaceMap[ id0 ] = id1
			else
				_error("???????")
				return
			end
		end
	end
	obj.__guid = id1
	return id0, id1
end

local function reallocGUID( entity, replaceMap )
	replaceMap = replaceMap or {}
	local id0, id1 = _reallocObjectGUID( entity, replaceMap )
	for child in pairs( entity.children ) do
		reallocGUID( child, replaceMap )
	end
	for com in pairs( entity.components ) do
		_reallocObjectGUID( com, replaceMap )
	end
end

--------------------------------------------------------------------
_M.affirmGUID      = affirmGUID
_M.affirmSceneGUID = affirmSceneGUID
_M.reallocGUID     = reallocGUID