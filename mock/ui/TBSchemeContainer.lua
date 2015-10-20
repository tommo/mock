module 'mock'

CLASS: TBSchemeContainer ( TBWidget )
	:MODEL{
		Field 'scheme' :asset('tb_scheme') :getset( 'Scheme' );
	}

function TBSchemeContainer:__init()
	self.schemePath = false
end

function TBSchemeContainer:createInternalWidget()
	local widget = MOAITBWidget.new()
	widget:setGravity( MOAITBWidget.WIDGET_GRAVITY_ALL );
	return widget
end

function TBSchemeContainer:getScheme()
	return self.schemePath
end

function TBSchemeContainer:setScheme( schemePath )
	self.schemePath = schemePath
	if schemePath then
		self.scheme = loadAsset( schemePath )
	else
		self.scheme = false
	end
	self:updateScheme()
end

function TBSchemeContainer:updateScheme()
	local scheme = self.scheme
	local internal = self:getInternalWidget()
	--TODO: remove previously loaded widgets 
	if scheme then
		MOAITBMgr.loadWidgetsFromNodeTree( internal, scheme:getNodeTree() )
	end
end

registerEntity( 'TBSchemeContainer', TBSchemeContainer )
