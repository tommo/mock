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

luaExtName = luaExtName or '.lua'
--------------------------------------------------------------------
module( 'mock',  package.seeall )

local _WARNED = {}
setmetatable( _G, { 
	__index = function(t, k)
		if t == _G then
			if k == 'mock_edit' then return end
			if k:find( 'MOAI' ) then return end
			if _WARNED[ k ] then return nil end
			_WARNED[ k ] = true
			_error( 'undefined global:', k )
		end
		return nil
	end
})

require 'mock.core'
--------------------------------------------------------------------

----------------Asset Loaders
--FIXME: removed this when finished porting
require 'mock.gfx.asset.resloader'

--------------------------------------------------------------------
----tools
require 'mock.tools'
require 'mock.common'

require 'mock.common.portal'
require 'mock.common.shape'

--------------------------------------------------------------------
--PACKAGES
--------------------------------------------------------------------
------Animator?
require 'mock.animator'

------Graphics
require 'mock.gfx'

------Phyics
require 'mock.physics'

------Audio
require 'mock.audio'

----Entity
require 'mock.entity'

------GUI system
require 'mock.gui'

------STORY
require 'mock.story'
require 'mock.quest'

------Sequence
require 'mock.sqscript'

------AI
require 'mock.ai'

----UI
require 'mock.ui'

----Effects
require 'mock.effect'

----Extra
require 'mock.extra'

---------------------------------------------------------------------
----Editor
require 'mock.editor'




--------------------------------------------------------------------
----Let's POLLUTE THE GLOBAL ENV
--------------------------------------------------------------------
function mock.injectGlobalSymbols( env )
	local globalSymbols = {
		'Entity',
		'GlobalEntity',
		'SingleEntity',
		'Scene',
		'game',
		'_DebugDraw'
	}	
	env = env or _G
	for i, k in ipairs( globalSymbols ) do
		rawset( env, k, mock[ k ] )
	end
end

mock.injectGlobalSymbols( _G )

--------------------------------------------------------------------
----INIT
--------------------------------------------------------------------
function mock.init( configPath, fromEditor, extra )
	mock.game:loadConfig( configPath, fromEditor, extra )
end

function mock.start( option )
	mock.game:openEntryScene( option )
end

function mock.printtable( t )
	for k,v in pairs( t ) do
		print (k,v)
	end
end

local shit = MOAIProp.new()
function mock.getShit()
	return {[shit] = true }
end