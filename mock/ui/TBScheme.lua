module 'mock'

--------------------------------------------------------------------
CLASS: TBScheme ()
	:MODEL{
		Field 'name';
		Field 'script';
	}

function TBScheme:__init()
	self.script = ''
	self.nodeTree = false
end

function TBScheme:getNodeTree()
	return self.nodeTree
end

function TBScheme:_load( path )
	self.script = loadTextData( path )
	self.nodeTree = MOAITBMgr.loadNodeTree( self.script )
end


--------------------------------------------------------------------
function TBSchemeLoader( node )
	local scheme = TBScheme()
	scheme:_load( node:getObjectFile( 'data' ) )
	return scheme
end

registerAssetLoader( 'tb_scheme', TBSchemeLoader )
