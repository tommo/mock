module 'mock'

local find = string.find
local ssub = string.sub
local insert = table.insert

local function _parseCmdSpan( text )
	local colon = text:find( ':' )
	local head, body
	head = text:sub( 1, colon and colon-1 or -1 )
	body = colon and text:sub( colon + 1, -1 ) or false
	head = head:trim()
	local args = {}
	if body then
		for part in body:gsplit( ',', true ) do
			part = part:trim()
			insert( args, part )
		end
	end
	return {
		tag  = 'cmd',
		cmd  = head,
		args = args
	}
end

local function _insertPunctuation( symbol, cmd, text, i, collection )
	local p, p1 = text:find( symbol, i )
	if not p then	return false end
	-- insert( collection, { tag = 'text', text = text:sub( i, p1 ) } )
	-- insert( collection, { tag = 'cmd',  cmd = cmd, args = {} } )
	return p, p1, cmd
end

local symbolToPuctuation = {
	{ '%.%d+', false };
	{ ',',   ','  };
	{ ';',   ',,'  };
	{ '[!%?][!%?]+',  ',,,' };
	{ '%. ',  ',,' };
	{ '%.',  ',' };
	{ '!',  ',,' };
	{ '%?',  ',,' };
	--Chinese
	{ '，',   ','  };
	{ '；',   ',,'  };
	{ '！？',  ',,,' };
	{ '？！',  ',,,' };
	{ '？？',  ',,,' };
	{ '？？？',  ',,,' };
	{ '！！！',  ',,,' };
	{ '。',  ',,' };
	{ '！',  ',,' };
	{ '？',  ',,' };
	{ '、',  ',' };
}

local function _insertText( text, collection )
	--replace suspensions
	text = text:gsub( '……', '...' )
	text = text:gsub( '…', '...' )
	--
	local i = 1
	while true do
		local found = false
		local fp0, fp1, fcmd
		for _, entry in ipairs( symbolToPuctuation ) do
			local symbol, cmd = unpack( entry )
			local p, p1 = text:find( symbol, i )
			if p1 then
				if not found then
					found = true
					fp0 = p
					fp1 = p1
					fcmd = cmd
				else
					if p < fp0 then
						fp0 = p
						fp1 = p1
						fcmd = cmd
					end
				end
			end
		end

		if found then
			insert( collection, { tag = 'text', text = text:sub( i, fp1 ) } )
			if fcmd then
				insert( collection, { tag = 'cmd',  cmd = fcmd, args = {} } )
			end
			i = fp1 + 1
		else
			return insert( collection, { tag = 'text', text = text:sub( i, -1 ) } )
		end
	end
end

local function _parse( text, pos, collection )
	local p0, p01 = find( text, '{', pos )
	if p0 then
		if p0 > pos then
			local span = ssub( text, pos, p0 - 1 )
			_insertText( span, collection )
		end
		local p1, p11 = find( text, '}', p01 )
		local cmdSpan = ssub( text, p01 + 1, p1 and (p1-1) or -1 )
		insert( collection, _parseCmdSpan( cmdSpan ) )
		if p11 then
			return _parse( text, p11 + 1, collection )
		end
	else
		local span = ssub( text, pos, -1 )
		if #span > 0 then
			_insertText( span, collection )
		end
		return
	end
end

local function parseDialogScript( text )
	local spans = {}
	local prevLineHasText = false
	for line in text:gsplit( '\n', true ) do
		if prevLineHasText then
			insert( spans, { tag = 'text', text = '\n' } )
			insert( spans, { tag = 'cmd', cmd = ',,' } )
		end
		prevLineHasText = false
		local lineSpans = {}
		_parse( line, 1, lineSpans )
		for i, span in ipairs( lineSpans ) do
			if span.tag == 'text' then
				prevLineHasText = true
			end
			insert( spans, span )
		end
	end
	return spans
end

--------------------------------------------------------------------
CLASS: DialogScript ()
	:MODEL{}

function DialogScript:__init( str )
	self.spans = {}
	if type( str ) == 'string' then
		self:parse( str )
	end
end

function DialogScript:parse( text )
	local spans = parseDialogScript( text )
	self.spans = spans
end

function DialogScript:toPlainText()
	local text = ''
	for i, span in ipairs( self.spans ) do
		local tag = span.tag
		if tag == 'text' then
			text = text .. span.text
		end
	end
	return text
end

function DialogScript:getSpans()
	return self.spans
end

function DialogScript:getSpan( i )
	return self.spans[ i ]
end
