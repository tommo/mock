require 'socket'
--------------------------------------------------------------------
local rootPath = _G[ 'MOCK_ROOT_PATH' ] or _G[ 'GII_PROJECT_SCRIPT_LIB_PATH' ] or '.'
package.path = ''
	.. ( rootPath .. '/3rdparty/?.lua' .. ';'  )
	.. ( rootPath .. '/3rdparty/?/init.lua' .. ';'  )
	.. package.path

--------------------------------------------------------------------
require 'QuadTree'
require 'i18n'
require 'utf8'
