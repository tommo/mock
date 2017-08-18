module 'mock'

CLASS: MsgCapture ( Behaviour )
	:MODEL{
		Field 'target' :type( Entity ) :getset( 'Target' );
		Field 'msgCapture' :string();
}

registerComponent( 'MsgCapture', MsgCapture )

function MsgCapture:__init()
	self.target = false
	self.msgCapture = 'msg.capture'
	self._listener = function ( msg, data, source )
		self:onCaptureMsg( msg, data, source )
	end
end

function MsgCapture:onAttach( ent )
	MsgCapture.__super.onAttach( self, ent )
	self:setTarget( self.target )
end

function MsgCapture:onDetach( ent )
	MsgCapture.__super.onDetach( self, ent )
	self:setTarget( false )
end

function MsgCapture:setTarget( target )
	local target0 = self.target
	if target0 == target then return end
	if target0 then
		target0:removeMsgListener( self._listener )
	end
	self.target = target
	if target then
		target:addMsgListener( self._listener )
	end
end

function MsgCapture:getTarget()
	return self.target
end

function MsgCapture:onCaptureMsg( msg, data, source )
	local packed = {
		target = self.target,
		msg    = msg,
		data   = data,
		source = source
	}
	self:tell( self.msgCapture, packed )
end

