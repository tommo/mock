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
CLASS: MSprite ( GraphicsPropComponent )
	:MODEL {
		'----';
		Field 'sprite' :asset_pre( 'msprite' ) :getset('Sprite');
		Field 'default' :string() :selection( 'getClipNames' ) :set('setDefaultClip');
		Field 'autoPlay' :boolean();
		Field 'autoPlayMode' :enum( EnumTimerMode );
		'----';
		Field 'hiddenFeatures' :collection( 'string' ) :selection( 'getAvailFeatures' ) :getset( 'HiddenFeatures' );
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
	self.animState   = MOAIAnim.new()
	self.spriteData  = false
	self.currentClip = false
	self.playSpeed   = 1
	self.animState:reserveLinks( 3 ) --offset x & offset y & frame index	
	self.featureMask = {}
	self.autoPlay    = false
	self.autoPlayMode= MOAITimer.LOOP 
	self.flipX = false
	self.flipY = false
	self.hiddenFeatures = {}
	self.listenerOnStop = false
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
		self.prop:setDeck( instance )
		self.prop:setIndex( 1 )
		self.prop:forceUpdate()
		self:updateFeatures()
	end

end


function MSprite:getAvailFeatures()
	local result = {
		{ '__base__', '__base__' }
	}
	if self.spriteData then
		for i, n in ipairs( self.spriteData.featureNames ) do
			result[ i+1 ] = { n, n }
		end
	end
	return result
end

function MSprite:getFeatureNames()
	if self.spriteData then
		return self.spriteData.featureNames
	end
	return {}
end

function MSprite:setHiddenFeatures( hiddenFeatures )
	self.hiddenFeatures = hiddenFeatures or {}
	--update hiddenFeatures
	if self.spriteData then return self:updateFeatures() end
end

function MSprite:getHiddenFeatures()
	return self.hiddenFeatures
end

function MSprite:updateFeatures()
	if not self.deckInstance then return end
	local featureTable = self.spriteData.features
	if not featureTable then return end
	local instance = self.deckInstance
	for i = 0, 64 do --hide all
		instance:setMask( i, false )
	end
	for i, featureName in ipairs( self.hiddenFeatures ) do
		local bit
		if featureName == '__base__' then
			bit = 0
		else
			bit = featureTable[ featureName ]
		end
		if bit then
			instance:setMask( bit, true ) --show target feature
		end
	end
end


function MSprite:setBaseFeatureHidden( value )
	if not self.deckInstance then return end
	return self.deckInstance:setMask( 0, value ~= false )
end

function MSprite:setFeatureHidden( featureName, value )
	if not self.deckInstance then return end
	local features = self.spriteData.features
	local bit = features and features[ featureName ]
	if bit then
		return self.deckInstance:setMask( bit, value ~= false )
	end
	-- self.featureMask[ bit ] = value ~= false
	-- if not self.deckInstance then return end
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

function MSprite:getCurrentClip() --TODO
	return self.currentClip
end

function MSprite:getCurrentFrameIndex()
	return self.prop:getIndex()	
end

function MSprite:getCurrentFrameMetaData( key, default )
	local data = self.spriteData 
	if not data then return nil end
	local index = self:getCurrentFrameIndex()
	local clip = self.currentClip
	if not clip then return nil end
	if index > 0 then
		local t = data.indexToMetaData[ index ]
		if not key then return t end
		if not t then return default end
		local v = t[ key ]
		if v == nil then return default end
		return v
	end
	return nil
end

function MSprite:hasClip( name )
	local data = self.spriteData
	return data and data.animations[ name ]~=nil
end

function MSprite:getClipLength( name )
	local clip
	if name then
		clip = self:getClip( name )
	else
		clip = self.currentClip
	end
	return clip.length
end

function MSprite:getClipFrameCount( name )
	local clip
	if name then
		clip = self:getClip( name )
	else
		clip = self.currentClip
	end
	if clip then return clip.length end
end

function MSprite:setFrame( frame )
	if not self.animState then return end
	local time = clamp( frame, 0, self.currentClip.length )
	self:apply( frame )
	self:setTime( frame )
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

function MSprite:setSpeed( speed )
	speed = speed or 1
	self.playSpeed = speed
	if self.animState then
		self.animState:setSpeed( speed )
	end
end


function MSprite:createAnimState( clipName, mode )
	local clip = self:getClip( clipName )
	if not clip then 
		_warn( 'msprite animation clip not found:'..clipName, self.spritePath )
		return false
	end	
	---bind animcurve to animState
	local animState    = MOAIAnim.new()
	 
	if self.listenerOnStop then
		animState:setListener(MOAITimer.EVENT_TIMER_END_SPAN, listener)
	end
	local indexCurve   = clip.indexCurve
	-- local offsetXCurve = clip.offsetXCurve
	-- local offsetYCurve = clip.offsetYCurve
	animState:reserveLinks( 1 )
	animState:setLink( 1, indexCurve,   self.prop, MOAIProp.ATTR_INDEX )
	-- animState:setLink( 2, offsetXCurve, self.prop, MOAIProp.ATTR_X_LOC )
	-- animState:setLink( 3, offsetYCurve, self.prop, MOAIProp.ATTR_Y_LOC )
	animState:setMode( mode or clip.mode or MOAITimer.NORMAL )
	animState.length = clip.length
	animState.clip   = clip

	return animState, clip
end

function MSprite:getSpeed()
	return self.playSpeed
end

function MSprite:setTime( time )
	return self.animState:setTime( time )
end

function MSprite:apply( time )
	return self.animState:apply( time )
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

function MSprite:getAnimState()
	return self.animState
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


function MSprite:drawBounds()
	GIIHelper.setVertexTransform( self.prop )
	local x1,y1,z1, x2,y2,z2 = self.prop:getBounds()
	MOAIDraw.drawRect( x1,y1,x2,y2 )
end

function MSprite:getPickingProp()
	return self.prop
end

function MSprite:setListenerOnStop( listener )
	self.listenerOnStop = listener or false
	if self.animState then
		self.animState:setListener(MOAITimer.EVENT_TIMER_END_SPAN, listener)
	end
end
