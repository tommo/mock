module 'mock'

local match  = string.match
local trim   = string.trim
local gsplit = string.gsplit
local function calcIndent( l )
	local k = match( l, '^\t*' )
	if not k then return 0 end
	return #k
end

--------------------------------------------------------------------
local ParseContextProto = {}
local ParseContextMT = { __index = ParseContextProto }

function ParseContextProto:init()
	self.rootNode = { type = 'root', children = {}, indent = -1, parent = false }
	self.currentIndent = -1
	self.currentNode   = self.rootNode
	self.currentParent = false
	self.currentDecorationNode = false
end

local function printBTScriptNode( n, indent )
	io.write( string.rep( '\t', indent or 0 ) )
	print( string.format( '%s : %s >%d', tostring( n.type ), tostring( n.value ), n.indent or 0 ))
	for i, child in ipairs( n.children ) do
		printBTScriptNode( child, (indent or 0) + 1 )
	end
end


function ParseContextProto:addLineChild()
	local node = { type = false, children = {}, indent = self.currentIndent }
	node.parent = self.currentLineHead
	if self.currentLineHead then
		table.insert( self.currentLineHead.children, node )
		self.currentLineHead.lineEnd = true
	end
	self.currentNode = node
	return node
end

function ParseContextProto:add()
	local node = { type = false, children = {}, indent = self.currentIndent }
	node.parent = self.currentParent
	if self.currentParent then
		if self.currentParent.lineEnd then
			_warn( 'ambiguous child layout', self.currentLineNo )
		end
		table.insert( self.currentParent.children, node )
	end
	self.currentNode = node
	return node
end

function ParseContextProto:matchIndent( indent )
	-- if indent == self.currentIndent then --parent node no change
	-- 	return self:add()
	-- end

	if indent > self.currentIndent then --going deeper
		self.currentParent = self.currentNode	
		self.currentIndent = indent
		return self:add()
	end

	--find previous indent level
	local found = false
	local n = self.currentNode
	while n do
		if n.indent == indent and n.parent.indent < indent then found = n break end
		n = n.parent
	end

	if not found then
		error( 'indent no match' )
	end
	self.currentNode   = n
	self.currentParent = self.currentNode.parent
	self.currentIndent = indent
	return self:add()
end

function ParseContextProto:setErrorInfo( info )
	self.errorInfo = info
end

function ParseContextProto:set( type, value )
	if not self.currentLineHead then
		self.currentLineHead = self.currentNode
	else
		self:addLineChild()
		if self.decorateState == 'decorating' then
			self.decorateState = 'decorated'
			self.currentParent = self.currentNode
			self.currentLineHead = self.currentNode
			self.currentDecorationNode = false

		elseif self.decorateState == 'decorated' then
			-- self:setErrorInfo( 'decorator node can only have ONE target node' )
			-- return false
		end
	end
	self.currentNode.type     = type
	self.currentNode.value    = value or 'NONAME'
	return true
end

function ParseContextProto:setArguments( args )
	self.currentNode.arguments = args or false
end

function ParseContextProto:parseArguments( raw )
	local result = {}
	for part in string.gsplit( raw, ',', true ) do
		local k, v = string.match( part, '^%s*([%w_.]+)%s*=%s*([%w_.%+%-]+)%s*' )
		if k then
			result[ k ] = v
		else
			self:setErrorInfo( 'failed parsing arguments' )
			return nil
		end
	end
	return result
end

function ParseContextProto:parseCommon( content, pos, type, symbol )
	-- local content = content:sub( pos )
	local pattern = '^'..symbol..'%s*([%w_.]*)%s*'
	local s, e, match = string.find( content, pattern, pos )
	-- print( s,e,type,symbol, content:sub( pos, -1 ) )
	if not s then	return pos end
	if self:set( type, match ) then
		return e + 1
	else
		return pos
	end
end

function ParseContextProto:parseLineCommon( content, pos, type, symbol )
	-- local content = content:sub( pos )
	local s, e, match = string.find( content, '^'..symbol..'%s*(.*)%s*', pos )
	if not s then	return pos end
	if self:set( type, match ) then
		return e + 1
	else
		return pos
	end
end

function ParseContextProto:parseCommonWithArguments( content, pos, type, symbol )
	-- local content = content:sub( pos )
	local s, e, match = string.find( content, '^'..symbol..'%s*([%w_.]+)%s*', pos )
	if not s then	return pos end
	if self:set( type, match ) then
		local pos1 = e + 1
		
		--test empty arg first
		local s, e, match = string.find( content, '%(%s*%)%s*', pos1 )
		if s then return e + 1 end
		
		--test kvargs
		local s, e, match = string.find( content, '%(%s*(.*)s*%)%s*', pos1 )
		if s then
			local args = self:parseArguments( match )
			if not args then return pos end
			self:setArguments( args )
			return e + 1
		else
			return pos1
		end

	else
		return pos
	end
end

function ParseContextProto:parseDecorator( content, pos, type, symbol )
	-- local content = content:sub( pos )
	local s, e, match = string.find( content, '^'..symbol..'%s*', pos )
	if not s then	return pos end
	if self:set( type, type ) then
		self.decorateState = 'decorating'
		self.currentDecorationNode = self.currentNode
		return e + 1
	else
		return pos
	end
end

function ParseContextProto:parseDecoratorFor( content, pos, type, symbol )
	local s, e, match = string.find( content, '^'..symbol..'%s*', pos )
	if not s then	return pos end
	if self:set( type, type ) then
		local pos1 = e + 1
		local s, e, match = string.find( content, '%(%s*(.*)s*%)%s*', pos1 )
		if s then
			local argStrs = string.split( match, ',', true )
			local args = {}
			for i, v in ipairs( argStrs ) do
				args[ i ] = tonumber( v )
			end
			local minCount = args[ 1 ] or 1
			local maxCount = args[ 2 ] or 1
			self:setArguments( { min = minCount, max = maxCount } )
			return e + 1
		else
			self:setErrorInfo( '"for" decorator needs integer arguments' )
		end
		
		self.decorateState = 'decorating'
		self.currentDecorationNode = self.currentNode
		return e + 1
	else
		return pos
	end
end

function ParseContextProto:parseDecoratorSingleFloat( content, pos, type, symbol )
	local s, e, match = string.find( content, '^'..symbol..'%s*', pos )
	if not s then	return pos end
	if self:set( type, type ) then
		local pos1 = e + 1
		local s, e, match = string.find( content, '%(%s*(.*)s*%)%s*', pos1 )
		local num = s and tonumber( match )
		if num then
			self:setArguments( { value = num } )
			return e + 1
		else
			self:setErrorInfo( string.format( '"%s" decorator needs a number argument', type ) )
		end
		
		self.decorateState = 'decorating'
		self.currentDecorationNode = self.currentNode
		return e + 1
	else
		return pos
	end
end

function ParseContextProto:parse_condition ( content, pos )
	return self:parseCommon( content, pos, 'condition', '?' )
end

function ParseContextProto:parse_condition_not ( content, pos )
	return self:parseCommon( content, pos, 'condition_not', '!' )
end

function ParseContextProto:parse_action ( content, pos )
	return self:parseCommonWithArguments( content, pos, 'action', '@' )
end

function ParseContextProto:parse_msg ( content, pos )
	return self:parseCommonWithArguments( content, pos, 'msg', '$' )
end

function ParseContextProto:parse_log ( content, pos )
	return self:parseLineCommon( content, pos, 'log', '##' )
end

function ParseContextProto:parse_priority ( content, pos )
	return self:parseCommon( content, pos, 'priority', '+' )
end

function ParseContextProto:parse_sequence ( content, pos )
	return self:parseCommon( content, pos, 'sequence', '>' )
end

function ParseContextProto:parse_random ( content, pos )
	return self:parseCommon( content, pos, 'random', '~' )
end

function ParseContextProto:parse_shuffled ( content, pos )
	return self:parseCommon( content, pos, 'shuffled', '~>' )
end

function ParseContextProto:parse_concurrent_and ( content, pos )
	return self:parseCommon( content, pos, 'concurrent_and', '|&' )
end

function ParseContextProto:parse_concurrent_or ( content, pos )
	return self:parseCommon( content, pos, 'concurrent_or', '||' )
end

function ParseContextProto:parse_concurrent_either ( content, pos )
	return self:parseCommon( content, pos, 'concurrent_either', '|~' )
end

function ParseContextProto:parse_decorator_not ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_not', ':not' )
end

function ParseContextProto:parse_decorator_ok ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_ok', ':ok' )
end

function ParseContextProto:parse_decorator_ignore ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_ignore', ':pass' )
end

function ParseContextProto:parse_decorator_fail ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_fail', ':fail' )
end

function ParseContextProto:parse_decorator_for ( content, pos )
	return self:parseDecoratorFor( content, pos,  'decorator_for', ':for' )
end

function ParseContextProto:parse_decorator_repeat ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_repeat', ':repeat' )
end

function ParseContextProto:parse_decorator_while ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_while', ':while' )
end

function ParseContextProto:parse_decorator_forever ( content, pos )
	return self:parseDecorator( content, pos, 'decorator_forever', ':forever' )
end

function ParseContextProto:parse_decorator_weight ( content, pos )
	return self:parseDecoratorSingleFloat( content, pos,  'decorator_weight', ':weight' )
end

function ParseContextProto:parse_decorator_prob ( content, pos )
	return self:parseDecoratorSingleFloat( content, pos,  'decorator_prob', ':prob' )
end


function ParseContextProto:parse_commented ( content, pos )
	local s, e, match = string.find( content, '^//.*', pos )
	if s then
		self.currentNode.commented = true
		return e + 1
	end
	return pos
end

function ParseContextProto:parse_spaces ( content, pos )
	local s, e, match = string.find( content, '^%s*', pos )
	if s then return e + 1 end
	return pos
end


function ParseContextProto:parseLine( lineNo, l )
	
	local i = calcIndent( l )
	self:matchIndent( i )
	if self.decorateState == 'decorating' then
		if self.currentParent ~= self.currentDecorationNode then
			print( 'decorator node must have ONE sub node')
			local info = string.format( 'syntax error @ %d:%d', lineNo, i )
			print( info )
			error( 'fail parsing' )
		end
	end

	self.currentLineHead = false
	self.decorateState   = false
	
	local pos = i + 1
	local trailComment = l:find( '//' )
	if trailComment then
		l = l:sub( 1, trailComment - 1 )
	end
	pos = self:parse_action( l, pos )

	local length = #l
	while true do
		if pos > length then break end
		local pos0 = pos
		pos = self:parse_shuffled( l, pos )
		pos = self:parse_concurrent_and( l, pos )
		pos = self:parse_concurrent_or( l, pos )
		pos = self:parse_concurrent_either( l, pos )
		pos = self:parse_condition( l, pos )
		pos = self:parse_condition_not( l, pos )
		pos = self:parse_action( l, pos )
		pos = self:parse_msg( l, pos )
		pos = self:parse_log( l, pos )
		pos = self:parse_priority( l, pos )
		pos = self:parse_sequence( l, pos )
		pos = self:parse_random( l, pos )
		pos = self:parse_decorator_not( l, pos )
		pos = self:parse_decorator_ok( l, pos )
		pos = self:parse_decorator_fail( l, pos )
		pos = self:parse_decorator_ignore( l, pos )
		pos = self:parse_decorator_for( l, pos )
		pos = self:parse_decorator_weight( l, pos )
		pos = self:parse_decorator_prob( l, pos )
		pos = self:parse_decorator_while( l, pos )
		pos = self:parse_decorator_repeat( l, pos )
		pos = self:parse_decorator_forever( l, pos )
		pos = self:parse_commented( l, pos )
		pos = self:parse_spaces( l, pos )
		if pos0 == pos then 
			if self.errorInfo then
				print( self.errorInfo )
			end
			local info = string.format( 'syntax error @ %d:%d', lineNo, pos )
			print( info )
			error( 'fail parsing') end
	end
	-- if self.decorateState == 'decorating'  then
	-- 	print( 'decorator node must have ONE sub node')
	-- 	local info = string.format( 'syntax error @ %d:%d', lineNo, pos )
	-- 	print( info )
	-- 	error( 'fail parsing')
	-- end
	return true
end

function ParseContextProto:parseSource( src )
	self:init()
	local lineNo = 0
	for line in string.gsplit( src, '\n', true ) do
		lineNo = lineNo + 1
		self.currentLineNo = lineNo
		if line:trim() ~= '' then
			self:parseLine( lineNo, line )
		end
	end
	-- printBTScriptNode( self.rootNode )
	return self.rootNode
	-- for i, node in ipairs( self.rootNode.children ) do
	-- 	if node.value == 'root' then
	-- 		return node
	-- 	end
	-- end
	-- return false
end

--------------------------------------------------------------------
local function stripNode( n )
	local newChildren = {}
	for i, child in ipairs( n.children ) do
		if not ( child.commented or ( not child.type ) ) then
			table.insert( newChildren, child )
			stripNode( child )
		end
	end
	if #newChildren == 0 then
		n.children = nil
	else
		n.children = newChildren
	end
	n.parent = nil
	n.indent = nil
	n.lineEnd = nil
	return n
end

function loadBTScript( src, name )
	local context = setmetatable( {}, ParseContextMT )
	local outputNode =  try( function() return context:parseSource( src ) end )
	if not outputNode then
		_error( 'failed parsing behaviour tree or no root node specified', name or '<unknown>')
		return false
	end
	outputNode = stripNode( outputNode )
	local tree = BehaviorTree()
	tree:load( outputNode )
	return tree
end

function loadBTScriptFromFile( path )
	local f = io.open( path, 'r' )
	if f then
		local src = f:read( '*a' )
		return loadBTScript( src, path )
	end
	return false
end

function parseBTScriptFile( path )
	local f = io.open( path, 'r' )
	if f then
		local src = f:read( '*a' )
		local context = setmetatable( {}, ParseContextMT )
		local outputNode =  try( function() return context:parseSource( src ) end )
		if not outputNode then
			_error( 'failed parsing behaviour tree or no root node specified', path or '<unknown>')
			return false
		else
			printBTScriptNode( outputNode )
		end
	end
	return false
end

local function BTScriptLoader( node )
	local path = node:getObjectFile('def')
	return loadBTScriptFromFile( path )
end

--------------------------------------------------------------------
registerAssetLoader ( 'bt_script', BTScriptLoader )

