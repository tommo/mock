module 'mock'


local _DEFAULT_VSH = [[
	vec4 position;
	vec2 uv;
	vec4 color;

	varying MEDP vec2 uvVarying;
	void main () {
		gl_Position = position;
		uvVarying = uv;
	}
]]


local _DEFAULT_FSH = [[
	varying MEDP vec2 uvVarying;
	uniform sampler2D sampler;

	void main () {
		gl_FragColor = texture2D ( sampler, uvVarying );
	}
]]

--------------------------------------------------------------------
CLASS: ShaderProgram ()
	:MODEL{
		Field 'vsh' :asset( 'vsh' );
		Field 'fsh' :asset( 'fsh' );
	}

--------------------------------------------------------------------
CLASS: Shader ()
	:MODEL{}

--------------------------------------------------------------------
--class shader program
--------------------------------------------------------------------
function ShaderProgram:__init()
	self.prog =  MOAIShaderProgram.new()
	self.uniformTable = {}
	self.built = false

	self.vsh = false
	self.fsh = false
	
	self.vshSrc = false
	self.fshSrc = false

	self.uniforms   = {}
	self.attributes = false
end

function ShaderProgram:getMoaiShaderProgram()
	return self.prog
end

function ShaderProgram:build( force )
	if self.built and not force then return end
	local vshSource
	local fshSource

	if self.vsh == '__default_vsh__' then
		vshSource = _DEFAULT_VSH
	else
		vshSource = mock.loadAsset( self.vsh )
	end

	if self.fsh == '__default_fsh__' then
		fshSource = _DEFAULT_FSH
	else
		fshSource = mock.loadAsset( self.fsh )
	end
	
	return self:buildFromSource( vshSource, fshSource )
end

function ShaderProgram:buildFromSource( vshSource, fshSource )
	local prog  = self.prog

	self.vshSource = vshSource
	self.fshSource = fshSource

	prog:load( vshSource, fshSource )
	prog._source = self

	--setup variables
	local attrs = self.attributes or {'position', 'uv', 'color'}
	if attrs then
		for i, a in ipairs(attrs) do
			assert( type(a)=='string' )
			prog:setVertexAttribute( i, a )
		end
	end

	local uniforms = self.uniforms
	local uniformTable = {}
	if uniforms then
		local count = #uniforms
		prog:reserveUniforms(count)
		for i, u in ipairs(uniforms) do
			local utype  = u.type
			local uvalue = u.value
			local name   = u.name

			if     utype == 'float' then
				prog:declareUniformFloat( i, name, uvalue or 0 )

			elseif utype == 'int' then
				prog:declareUniformInt( i, name, uvalue or 0 )	

			elseif utype == 'color' then
				prog:declareUniform( i, name, MOAIShader.UNIFORM_COLOR )

			elseif utype == 'sampler' then
				prog:declareUniformSampler( i, name, uvalue or 1 )

			elseif utype == 'transform' then
				prog:declareUniform( i,name, MOAIShader.UNIFORM_TRANSFORM )

			elseif utype == 'pen_color' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_PEN_COLOR )

			elseif utype == 'view_proj' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_VIEW_PROJ )

			elseif utype == 'world_view_proj' then
				prog:declareUniform( i,name,MOAIShader.UNIFORM_WORLD_VIEW_PROJ )

			end
			uniformTable[ name ] = i
		end
	end
	
	self.uniformTable = uniformTable
	self.built = true
end

function ShaderProgram:buildShader( data )	
	if not self.built then self:build() end
	local shader = Shader()
	shader:setProgram( self )
	--TODO:set uniforms from data
	return shader
end


--------------------------------------------------------------------
--class shader
--------------------------------------------------------------------
function Shader:__init()
	self.shader = MOAIShader.new()
end

function Shader:setProgram( prog )
	self.prog = prog
	self.shader:setProgram( prog:getMoaiShaderProgram() )
end

function Shader:getMoaiShader()
	return self.shader
end

function Shader:getAttrId( name )	
	return self.prog.uniformTable[ name ]
end

function Shader:setAttr( name, v )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	self.shader:setAttr( id, v )
end

function Shader:setAttrLink( name, node, id1 )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	self.shader:setAttrLink( id, node, id1 )
end

function Shader:seekAttr( name, v, duration, ease )
	--Future...
	-- local id = self.prog.uniformTable[ name ]
	-- if not id then error('undefined uniform:'..name, 2) end
	-- return self.shader:seekAttr( id, v, duration, ease )
end

function Shader:moveAttr( name, v, duration, ease )
	--Future...
	-- local id = self.prog.uniformTable[ name ]
	-- if not id then error('undefined uniform:'..name, 2) end
	-- return self.shader:moveAttr( id, v, duration, ease )
end

--------------------------------------------------------------------
--------------------------------------------------------------------

function buildShaderProgramFromString( vsh, fsh )
	local prog = ShaderProgram()
	prog:buildFromSource( vsh, fsh )
	return prog
end

local shaderPrograms = {}

function affirmShaderProgram( vshPath, fshPath )
	local key = vshPath .. '|' .. fshPath
	local prog = shaderPrograms[ key ]
	if prog then return prog end
	prog = ShaderProgram()
	prog.vsh = vshPath
	prog.fsh = fshPath
	prog:build()
	prog._key = key
	shaderPrograms[ key ] = prog
	return prog
end

function releaseShaderProgram( vshPath, fshPath )
	local term = (vshPath or '') .. '|' .. (fshPath or '')
	local torelease = {}
	for key, prog in pairs( shaderPrograms ) do
		if key:find( term ) then 
			torelease[ key ] = true
		end
	end

	for key in pairs( torelease ) do
		local prog = shaderPrograms[ key ]
		shaderPrograms[ key ] = nil
		--TODO: release shaders?
	end
end

local function shaderLoader( node )
	local data = loadAssetDataTable( node:getObjectFile('def') )
	local vsh = data['vsh'] or '__default_vsh__'
	local fsh = data['fsh'] or '__default_fsh__'
	local prog = affirmShaderProgram( vsh, fsh )
	if prog then
		return prog:buildShader( data )
	end
end

local function shaderSourceLoader( node )
	local data = loadTextData( node:getObjectFile('src') )
	return data
end

registerAssetLoader ( 'shader', shaderLoader   )
registerAssetLoader ( 'vsh', shaderSourceLoader )
registerAssetLoader ( 'fsh', shaderSourceLoader )

