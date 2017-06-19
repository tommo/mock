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
	self:initRPC()
	self:onInit()
end

function GIISyncHost:initRPC()
	local RPCTell = MOCKNetworkRPC.new()
	RPCTell:init(
		'TELL', 
		function( msg, dataString )
			local data = MOAIMsgPackParser.decode( dataString )
			return self:onMsg( msg, data ) 
		end,
		MOCKNetworkRPC.RPC_MODE_ALL
	)
	RPCTell:setArgs( 'ss' )
	self.host:registerRPC( RPCTell )
	self.RPCTell = RPCTell
end

function GIISyncHost:tellPeer( peer, msg, data )
	local dataString = MOAIMsgPackParser.encode( data )
	return self.host:sendRPCTo( peer, self.RPCTell, msg, dataString )
end

function GIISyncHost:onMsg( msg, data )
end

--------------------------------------------------------------------
CLASS: GIISyncEditorHost ( GIISyncHost )
	:MODEL{}

function GIISyncEditorHost:__init()
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



--------------------------------------------------------------------
CLASS: GIISyncGameHost ( GIISyncHost )
	:MODEL{}

function GIISyncGameHost:__init()
	self.connected = false
end

function GIISyncGameHost:onInit()
	self.host:setListener( MOCKNetworkHost.EVENT_CONNECTION_ACCEPTED, function()
		_log( 'connected to gii' )
		self.connected = true
	end )
	self.host:connectServer( '127.0.0.1', PORT )
end

function GIISyncGameHost:onMsg( msg, data )
	local scene = game:getMainScene()
	if msg == 'entity.modified' then
		local id = data.id
		local objData = data.objData
		local ent = scene:findEntityByGUID( id )
		if ent then
			_deserializeObject( ent, objData, nil, nil, SYNC_FIELDS )
		end
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
	else
		self.gameHost = GIISyncGameHost()
		self.gameHost:init()
	end
end

GIISyncManager()
