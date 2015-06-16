--[[
* MOCK framework for Moai

* Copyright (C) 2012 Tommo Zhou(tommo.zhou@gmail.com).  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining
* a copy of this software and associated documentation files (the
* "Software"), to deal in the Software without restriction, including
* without limitation the rights to use, copy, modify, merge, publish,
* distribute, sublicense, and/or sell copies of the Software, and to
* permit persons to whom the Software is furnished to do so, subject to
* the following conditions:
*
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
module 'mock'

--------------------------------------------------------------------
CLASS: MSprite ( RenderComponent )
	:MODEL {
		'----';
		Field 'sprite' :asset( 'msprite' ) :getset('Sprite');
		Field 'default' :string() :selection( 'getClipNames' ) :set('setDefaultClip');
		Field 'playFPS' :int() :getset('FPS');
		Field 'autoPlay' :boolean();
		Field 'autoPlayMode' :enum( EnumTimerMode );
		'----';
		Field 'flipX' :boolean() :set( 'setFlipX' );
		Field 'flipY' :boolean() :set( 'setFlipY' );

	}

wrapWithMoaiPropMethods( MSprite, 'prop' )

mock.registerComponent( 'MSprite', MSprite )
mock.registerEntityWithComponent( 'MSprite', MSprite )
--------------------------------------------------------------------

function MSprite:__init()
	self.prop        = MOAIProp.new()
	self.animState      = MOAIAnim.new()
	self.spriteData = false
	self.currentClip = false
	self.playFPS     = 10
	self.playSpeed   = 1
	self.animState:reserveLinks( 3 ) --offset x & offset y & frame index	
	self.featureMask = {}
	self.autoPlay    = false
	self.autoPlayMode= MOAITimer.LOOP 
	self.flipX = false
	self.flipY = false
end

function MSprite:onAttach( entity )
	return entity:_attachProp( self.prop, 'render' )
end

function MSprite:onDetach( entity )
	self:stop()
	return entity:_detachProp( self.prop )
end

function MSprite:onStart( entity )
	if self.autoPlay and self.default then
		self:play( self.default, self.autoPlayMode )
	end
end

function MSprite:setSprite( path )
	self:stop( true )
	self.spritePath = path 

	local spriteData, node = loadAsset( path )
	--TODO? assert asset node type
	if spriteData then
		self:stop( true )
		self.currentClip = false
		self.spriteData = spriteData
		local instance = MOAIGfxMaskedQuadListDeck2DInstance.new()
		instance:setSource( spriteData.frameDeck )
		self.deckInstance = instance
		-- self:_updateFeatureMask()
		self.prop:setDeck( instance )
		self.prop:setIndex( 1 )
		self.prop:forceUpdate()
	end

end
-- function MSprite:_updateFeatureMask()
-- 	if not self.deckInstance then return end
-- 	local instance = self.deckInstance
-- 	for i = 1, 64 do
-- 		instance:setMask( i, self.featureMask[ i ] ~= false )
-- 	end
-- end

function MSprite:getFeatureNames()
	if self.spriteData then
		return self.spriteData.featureNames
	end
	return {}
end

function MSprite:setFeatureHidden( featureName, value )
	if not self.deckInstance then return end
	local features = self.spriteData.features
	local bit = features and features[ featureName ] or 0
	self.deckInstance:setMask( bit, value ~= false )
	-- self.featureMask[ bit ] = value ~= false
	-- if not self.deckInstance then return end
end

function MSprite:setupFeatures( featureNames )
	if not self.deckInstance then return end
	local features = self.spriteData.features
	if not features then return end
	local instance = self.deckInstance
	for i = 1, 64 do --hide all
		instance:setMask( i, true )
	end
	for i, featureName in ipairs( featureNames ) do
		local bit = features[ featureName ]
		if bit then
			instance:setMask( bit, false ) --show target feature
		end
	end
end

--------------------------------------------------------------------
local defaultShader = MOAIShaderMgr.getShader( MOAIShaderMgr.DECK2D_SHADER )

function MSprite:setShader( shaderPath )
	self.shader = shaderPath	
	if shaderPath then
		local shader = mock.loadAsset( shaderPath )
		if shader then
			local moaiShader = shader:getMoaiShader()
			return self.prop:setShader( moaiShader )
		end
	end
	self.prop:setShader( defaultShader )
end


function MSprite:setBillboard( billboard )
	self.billboard = billboard
	self.prop:setBillboard( billboard )
end

function MSprite:setDepthMask( enabled )
	self.depthMask = enabled
	self.prop:setDepthMask( enabled )
end

function MSprite:setDepthTest( mode )
	self.depthTest = mode
	self.prop:setDepthTest( mode )
end


function MSprite:getSprite()
	return self.spritePath
end

function MSprite:getSpriteData()
	return self.spriteData
end

function MSprite:getClipNames()
	local data = self.spriteData
	if not data then return nil end
	local result = {}
	for k,i in pairs( data.animations ) do
		table.insert( result, { k, k } )
	end
	return result
end

function MSprite:setScissorRect( r )
	return self.prop:setScissorRect( r )
end

function MSprite:getClipTable()
	local data = self.spriteData
	if not data then 
		_error('animation not load', 2)
		return nil
	end
	return data.animations
end

function MSprite:getClip( name )
	local data = self.spriteData
	if not data then 
		_error('animation not load', 2)
		return nil
	end
	return data.animations[ name ]
end

function MSprite:hasClip( name )
	local data = self.spriteData
	return data and data.animations[ name ]~=nil
end

function MSprite:getClipLength( name )
	local clip = name and self:getClip( name ) or self.currentClip
	if clip then return clip.length * self.playFPS end
end

function MSprite:setDefaultClip( clipName )
	self.default = clipName
	if clipName then
		self:setClip( clipName )
	end
end

function MSprite:setClip( name, mode )
	-- if self.currentClip and self.currentClip.name == name then return true end
	local animState, clip = self:createAnimState( name, mode )
	if not animState then return false end

	if self.animState then self.animState:stop() end
	self.currentClip=clip
	self.animState = animState
	self:setFPS(self.playFPS)
	self:apply( 0 )
	self:setTime( 0 )
	return true
end

--------------------------------------------------------------------
function MSprite:setFlipY( flip )
	self.flipY = flip
	setSclY( self.prop, flip and -1 or 1 )
end

function MSprite:setFlipX( flip )
	self.flipX = flip
	setSclX( self.prop, flip and -1 or 1 )
end

-----------
function MSprite:setFPS( fps )
	self.playFPS = fps
	self:setSpeed( self.playSpeed )
end

function MSprite:getFPS()
	return self.playFPS
end

function MSprite:setSpeed( speed )
	speed = speed or 1
	self.playSpeed = speed
	if self.animState then
		self.animState:setSpeed( speed * self.playFPS )
	end
end

function MSprite:createAnimState( clipName, mode )
	local clip = self:getClip( clipName )
	if not clip then 
		_error( 'animation clip not found:'..clipName )
		return false
	end	
	---bind animcurve to animState
	local animState       = MOAIAnim.new()
	local indexCurve   = clip.indexCurve
	local offsetXCurve = clip.offsetXCurve
	local offsetYCurve = clip.offsetYCurve

	animState:reserveLinks( 3 )
	animState:setLink( 1, indexCurve,   self.prop, MOAIProp.ATTR_INDEX )
	-- animState:setLink( 2, offsetXCurve, self.prop, MOAIProp.ATTR_X_LOC )
	-- animState:setLink( 3, offsetYCurve, self.prop, MOAIProp.ATTR_Y_LOC )
	animState:setMode( mode or clip.mode or MOAITimer.NORMAL )
	return animState, clip
end

function MSprite:getSpeed()
	return self.playSpeed
end

function MSprite:setTime( time )
	return self.animState:setTime( time )
end

function MSprite:apply( time )
	return self.animState:apply( time / self.playFPS )
end

-----------Play control
function MSprite:play( clipName, mode )
	if self:setClip( clipName, mode ) then return self:start() end
end

function MSprite:resetAndPlay( clipName, mode )
	if self:setClip( clipName, mode ) then  --playing a new clip
		return self:start()
	else --same as playing clip
		self:setTime( 0 )
		self:apply( 0 )
		return self:start()
	end
end

function MSprite:start()
	self.animState:start()
	return self.animState
end

function MSprite:reset()
	self:setTime( 0 )
end

function MSprite:stop( reset )
	self.animState:stop()
	if reset then return self:reset() end
end

function MSprite:pause( paused )
	self.animState:pause( paused )
end

function MSprite:isPaused()
end

function MSprite:isPlaying()
	return self.animState:isBusy()
end

function MSprite:setBlend( b )
	self.blend = b	
	setPropBlend( self.prop, b )
end

function MSprite:setVisible( f )
	return self.prop:setVisible( f )
end

function MSprite:isVisible()
	return self.prop:isVisible()
end

function MSprite:drawBounds()
	GIIHelper.setVertexTransform( self.prop )
	local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end

function MSprite:getPickingProp()
	return self.prop
end

