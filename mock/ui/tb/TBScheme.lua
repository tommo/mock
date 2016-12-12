module 'mock'

--------------------------------------------------------------------
local schemeCache = table.weak_v()

--------------------------------------------------------------------
CLASS: TBScheme ()
	:MODEL{
		Field 'name';
		Field 'script';
	}
	:SIGNAL{
		changed = ''
	}

function TBScheme:__init()
	self.script = ''
	self.nodeTree = false
end

function TBScheme:getNodeTree()
	return self.nodeTree
end

function TBScheme:_load( path )
	self.scriptPath = path
	self.script = loadTextData( path )
	self.nodeTree = MOAITBMgr.loadNodeTree( self.script )
	--emit signal
	self:changed()
end

function TBScheme:_reload()
	self:_load( self.scriptPath )
end


--------------------------------------------------------------------
function TBSchemeLoader( node )
	local path = node:getNodePath()
	local scheme = schemeCache[ path ]
	if not scheme then --avoid scheme recreation, so we can update it dynamically
		scheme = TBScheme()
		schemeCache[ path ] = scheme
	end
	scheme:_load( node:getObjectFile( 'data' ) )
	return scheme
end


registerAssetLoader( 'tb_scheme', TBSchemeLoader )
