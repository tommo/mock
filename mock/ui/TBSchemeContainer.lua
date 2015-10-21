module 'mock'

CLASS: TBSchemeContainer ( TBWidget )
	:MODEL{
		Field 'scheme' :asset('tb_scheme') :getset( 'Scheme' );
	}

function TBSchemeContainer:createInternalWidget() --called before __init
	local widget = MOAITBWidget.new()
	local inner = MOAITBWidget.new()
	widget:addChild( inner )

	widget:setGravity( MOAITBWidget.WIDGET_GRAVITY_ALL )
	inner:setGravity( MOAITBWidget.WIDGET_GRAVITY_ALL )
	self.innerWidget = inner
	return widget
end

function TBSchemeContainer:__init()
	self.schemePath = false
	self.scheme = false
end

function TBSchemeContainer:onLoad()
	if self.shceme then self:updateContent() end
end

function TBSchemeContainer:getScheme()
	return self.schemePath
end

function TBSchemeContainer:setScheme( schemePath )
	self.schemePath = schemePath
	if self.scheme then
		self:disconnect( self.scheme.changed )
	end

	if schemePath then
		self.scheme = loadAsset( schemePath )
	else
		self.scheme = false
	end

	if self.scheme then
		self:connect( self.scheme.changed, 'onSchemeChanged' )
	end

	self:updateContent()
end

function TBSchemeContainer:onSchemeChanged()
	return self:updateContent()
end

function TBSchemeContainer:updateContent()
	local inner = self.innerWidget
	if not inner then return end

	local scheme = self.scheme
	inner:deleteAllChildren()
	if scheme then
		MOAITBMgr.loadWidgetsFromNodeTree( inner, scheme:getNodeTree() )
	end
	self:refreshCanvas()
end

registerEntity( 'TBSchemeContainer', TBSchemeContainer )
