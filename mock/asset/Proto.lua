module 'mock'

--------------------------------------------------------------------
CLASS: Proto ()
	:MODEL{}

function Proto:__init( id )
	self.id   = id
	self.source = false
	self.ready  = false
end

function Proto:loadData( dataPath )
	local data     = loadAssetDataTable( dataPath )
	self.data      = data
	self.ready     = true
end

function Proto:createInstance( name )
	local instance
	local data = self.data
	instance = deserializeEntity( data )

	local protoName = instance:getName()
	if not name then
		name = protoName..'_Instance'
	end
	instance:setName( name )

	instance.FLAG_PROTO_INSTANCE = self.id or true
	-- print( 'loading proto', name  )
	-- print( debug.traceback())
	return instance
end

function Proto:setSource( src )
	self.source = src
end

--------------------------------------------------------------------
CLASS: ProtoManager ()
	:MODEL{}

function ProtoManager:__init()
	self.protoMap = {}
end

function ProtoManager:getProto( node )
	local nodePath = node:getNodePath()
	local proto = self.protoMap[ nodePath ]
	if not proto then 
		proto = Proto( nodePath )
		self.protoMap[ nodePath ] = proto
	end
	if not proto.ready then
		proto:loadData( node:getObjectFile( 'def' ) )
	end
	return proto
end

function ProtoManager:removeProto( node )
	local nodePath = node:getNodePath()
	local proto = self.protoMap[ nodePath ]
	if proto then
		proto.ready = false
	end
end

protoManager = ProtoManager()

function createProtoInstance( path, name )
	local proto, node = loadAsset( path )
	if proto then
		return proto:createInstance( name )
	else
		_warn( 'proto not found:', path )
		return nil
	end
end

--------------------------------------------------------------------
local function ProtoLoader( node )
	return protoManager:getProto( node )
end

local function ProtoUnloader( node )
	protoManager:removeProto( node )
end

registerAssetLoader( 'proto',  ProtoLoader, ProtoUnloader )
