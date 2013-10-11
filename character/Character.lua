module 'character'
--------------------------------------------------------------------
CLASS: Character ( mock.Behaviour )
	:MODEL{
		Field 'config'  :asset('character') :getset( 'Config' );
		Field 'default' :string();
	}

function Character:__init()
	self.config  = false
	self.default = 'default'
	self.activeState = false
	self.spineSprite = mock.SpineSprite()
end

function Character:setConfig( configPath )
	self.configPath = configPath
	self.config = mock.loadAsset( configPath )
	self:updateConfig()
end

function Character:getConfig()
	return self.configPath
end

function Character:updateConfig()
	local config = self.config
	if not config then return end
	local path = config:getSpine()
	self.spineSprite:setSprite( path )
	--todo
end

function Character:playAction( name )
	if not self.config then
		_warn('character has no config')
		return false
	end
	local action = self.config:getAction( name )
	if not action then
		_warn( 'character has no action', name )
		return false
	end
	local actionState = action:createState( self )
	self.activeState = actionState
	actionState:start()
	return actionState
end

function Character:stop()
	if not self.activeState then return end
	self.activeState:stop()
	self.activeState = false
	self.spineSprite:stop()
end

-----
function Character:onStart( ent )
	ent:attach( self.spineSprite )
end

------
--EVENT ACTION:
function Character:playAnim( clip )
	self.spineSprite:play( clip, MOAITimer.LOOP )
end

function Character:stopAnim()
	self.spineSprite:stop()
end

--------------------------------------------------------------------
mock.registerComponent( 'Character', Character )
