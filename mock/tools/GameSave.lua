module 'mock'

--------------------------------------------------------------------
local GameSaveModuleRegistry = {}
function registerGameSaveModule( id, clas, option )
	option = option or {}
	local version  = option['version'] or 0
	local priority = option['priority'] or 0
	assert( type( version ) == 'number' and type( id ) == 'string' )
	local fullkey = string.format( '%s{version=%d}', id, version )
	if GameSaveModuleRegistry[ fullkey ] then
		error( 'duplicated GameSaveModule:' .. fullkey )
	end
	GameSaveModuleRegistry[ fullkey ] = {
		id       = id,
		clas     = clas,
		version  = version,
		priority = priority
	}
end

--------------------------------------------------------------------
CLASS: GameSaveModule ()
	:MODEL{}

--class method
function GameSaveModule.register( clas, id, option )
	return registerGameSaveModule( id, clas, option )
end


function GameSaveModule:__init( gamesave )
	self.gamesave = gamesave
	--set by registry
	self.id       = false 
	self.version  = false
	self.priority = false
	---
end

function GameSaveModule:getGameSave()
	return self.gamesave
end

function GameSaveModule:getVersion()
	return self.version
end

function GameSaveModule:getId()
	return self.id
end

function GameSaveModule:save()
	return false
end

function GameSaveModule:load( data )
	return true
end

function GameSaveModule:loadDefault()
	return true
end

--TODO: postsave/preload for data patching
function GameSaveModule:postsave()
end

function GameSaveModule:preLoad( data )
end

function GameSaveModule:postLoad()

end

function GameSaveModule:validatePack( pack )
	local version = pack.version
	local id      = pack.id
	local data    = pack.data
	if id ~= self.id then
		_warn( 'game save module id mismatched', self.id, id )
		return false
	end
	if version ~= self.version then
		_warn( 'game save module version mismatched', self.id, version, self.version )
		return false
	end
	return true
end


function GameSaveModule:_loadDefault()
	return self:loadDefault()
end

function GameSaveModule:_load( pack )
	if not self:validatePack( pack ) then
		return false
	end
	return self:load( pack.data )
end

function GameSaveModule:_save()
	local data = {
		id      = self.id,
		version = self.version,
		data = self:save()
	}
	return data
end


--------------------------------------------------------------------
local function _sortGameSaveFileModule( a, b )
	local pa, pb = a.priority, b.priority
	local va, vb = a.version, b.version
	local ida, idb = a.id, b.id
	if pa == pb then
		if ida == idb then
			return va < vb
		else
			return ida < idb
		end
	else
		return pa < pb
	end
end

--------------------------------------------------------------------
--TODO
--------------------------------------------------------------------
CLASS: GameSaveFile ()
	:MODEL{}

function GameSaveFile:__init()
	self.modules = false
end

function GameSaveFile:affirmModules()
	if not self.modules then
		local modules = {}
		for fullkey, entry in pairs( GameSaveModuleRegistry ) do
			local id       = entry.id
			local clas     = entry.clas
			local version  = entry.version
			local priority = entry.provider
			local m = clas( self )
			m.version  = version
			m.priority = priority
			m.id       = id
			m.fullkey  = fullkey
			table.insert( modules, m )
		end
		table.sort( modules, _sortGameSaveFileModule )
		self.modules = modules
	end
	return self.modules
end

function GameSaveFile:save()
	local modules = self:affirmModules()
	local data = {}
	for i, m in ipairs( modules ) do
		local mdata = m:_save()
		data[ m.fullkey ] = mdata
	end
	return data
end

function GameSaveFile:load( data )
	local modules = self:affirmModules()

	for i, m in ipairs( modules ) do
		local mdata = data[ m.fullkey ]
		m:preLoad( mdata )
	end

	for i, m in ipairs( modules ) do
		local mdata = data[ m.fullkey ]
		local res
		if mdata then
			res = m:_load( mdata )
		else
			res = m:_loadDefault()
		end
		if res == false then --error
			_error( 'failed loading gamesave data', m.fullkey )
			return false
		end
	end

	for i, m in ipairs( modules ) do
		m:postLoad()
	end

	return true
end

