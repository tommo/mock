module 'mock'

local PORT = 201103
local BroadcastPORT = 200637


local SYNC_FIELDS = {
	'loc',
	'scl',
	'rot',
	'piv',
	'visible',
	'color',
}

CLASS: GIISyncHost ()
--------------------------------------------------------------------
function GIISyncHost:__init()
	self.host = MOCKNetworkMgr.createHost()
end

function GIISyncHost:init()
	self.localPeer = self.host:getLocalPeer()
	self:initRPC()
	self:onInit()
end

function GIISyncHost:initRPC()
	local RPCTell = MOCKNetworkRPC.new()
	RPCTell:init(
		'TELL', 
		function( peer, msg, dataString )
			local data = MOAIMsgPackParser.decode( dataString )
			return self:onRemoteMsg( peer, msg, data ) 
		end,
		MOCKNetworkRPC.RPC_MODE_ALL
	)
	RPCTell:setArgs( 'pss' )
	self.host:registerRPC( RPCTell )
	print( 'register rpc' )
	self.RPCTell = RPCTell
end

function GIISyncHost:tellPeer( peer, msg, data )
	local dataString = MOAIMsgPackParser.encode( data )
	return self.host:sendRPCTo( peer, self.RPCTell, self.localPeer, msg, dataString )
end

function GIISyncHost:onRemoteMsg( peer, msg, data )
end

--------------------------------------------------------------------
CLASS: GIISyncEditorHost ( GIISyncHost )
	:MODEL{}

function GIISyncEditorHost:__init()
	self.queryId = 0
	self.queries = {}
	self.connectedGames = {}
end

function GIISyncEditorHost:addConnectedGame( peer )
	self.connectedGames[ peer ] = true
end

function GIISyncEditorHost:removeConnectedGame( peer )
	self.connectedGames[ peer ] = nil
end

function GIISyncEditorHost:onInit()
	-- gii.connectPythonSignal( 'entity.modified', 
	-- 	function( entity )
	-- 		return self:onEntityModified( entity )
	-- 	end
	-- )
	-- self.broadcastServer:init( BroadcastPORT, 'GiiSync' )
	self.host:setListener( MOCKNetworkHost.EVENT_CONNECTION_ACCEPTED, 
		function( host, client )
			_log( 'connected to gii' )
			self:addConnectedGame( client )
		end
	)

	self.host:setListener( MOCKNetworkHost.EVENT_CONNECTION_CLOSED, 
		function( host, client )
			_log( 'connection closed' )
			self:removeConnectedGame( client )
		end
	)
	self.host:startServer( 0, PORT )
end


function GIISyncEditorHost:onEntityModified( entity )
	local objData = _serializeObject( entity, nil, nil, SYNC_FIELDS )
	local data = {
		id = entity.__guid,
		objData = objData
	}
	for peer in pairs( self.connectedGames ) do
		self:tellPeer( peer, 'entity.modified', data )
	end
end

function GIISyncEditorHost:queryGame( key, callback )
	local qid = self.queryId + 1
	self.queryId = qid
	local query = {
		queryId = qid,
		key = key,
		callback = callback,
		time = os.clock()
	}
	self.queries[ qid ] = query
	for peer in pairs( self.connectedGames ) do
		self:tellPeer( peer, 'query.start', query )
	end
end

function GIISyncEditorHost:tellConnectedPeers( msg, data )
	for peer in pairs( self.connectedGames ) do
		self:tellPeer( peer, msg, data )
	end
end

function GIISyncEditorHost:onRemoteMsg( peer, msg, data )
	if msg == 'query.answer' then
		return self:onQueryAnswer( peer, msg, data )
	end
end

function GIISyncEditorHost:onQueryAnswer( peer, msg, data )
	local result = data.result or false
	local queryId = data.queryId
	local query = self.queries[ queryId ]
	if query then
		local callback = query.callback
		if callback then
			callback( peer, result )
		end 
		self.queries[ queryId ] = nil
	end
end

--------------------------------------------------------------------
CLASS: GIISyncGameHost ( GIISyncHost )
	:MODEL{}

function GIISyncGameHost:__init()
	self.serverPeer = false
	self.connected = false
end

function GIISyncGameHost:onInit()
	self.host:setListener( MOCKNetworkHost.EVENT_CONNECTION_ACCEPTED, function()
		_log( 'connected to gii' )
		self.connected = true
		self.serverPeer = self.host:getServerPeer()
	end )
	self.host:connectServer( '127.0.0.1', PORT )
end

function GIISyncGameHost:onRemoteMsg( peer, msg, data )
	local scene = game:getMainScene()
	if msg == 'entity.modified' then
		local id = data.id
		local objData = data.objData
		local ent = scene:findEntityByGUID( id )
		if ent then
			_deserializeObject( ent, objData, nil, nil, SYNC_FIELDS )
		end

	elseif msg == 'query.start' then
		local result = self:onQuery( data )
		local queryId = data[ 'queryId' ]
		local output = {
			queryId = queryId,
			result = result,
		}
		self:tellPeer( peer, 'query.answer', output )

	elseif msg == 'command.open_scene' then
		local path = data
		if path then
			return game:openSceneByPath( path )
		end
	end

end

function GIISyncGameHost:tellServer( msg, data )
	if not self.serverPeer then
		_error( 'sync server not connected' )
		return false
	end
	return self:tellPeer( self.serverPeer, msg, data )
end

function GIISyncGameHost:onQuery( data )
	local key = data.key
	if key == 'scene.info' then
		local info = {
			path = game:getMainScene():getPath(),
		}
		return info
	end
end

--------------------------------------------------------------------

CLASS: GIISyncManager ( GlobalManager )
	:MODEL{}

function GIISyncManager:__init()
	self.host = false
	self.editorHost = false
	self.gameHost   = false
end

function GIISyncManager:postInit( game )
	if game:isEditorMode() then
		self.editorHost = GIISyncEditorHost()
		self.editorHost:init()
		self.host = self.editorHost
	else
		self.gameHost = GIISyncGameHost()
		self.gameHost:init()
		self.host = self.gameHost
	end
end

function GIISyncManager:getHost()
	return self.host
end

--------------------------------------------------------------------
GIISyncManager()


--------------------------------------------------------------------
function getGiiSyncHost()
	local sync = game:getGlobalManager( 'GIISyncManager' )
	return sync:getHost()
end


