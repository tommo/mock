module 'mock'

--------------------------------------------------------------------
function buildShaderProgramFromString( vsh, fsh, variables )
	local prog = ShaderProgram()
	if variables then
		prog.uniforms = variables.uniforms or {}
		prog.globals  = variables.globals or {}
	end
	prog.vsh = vsh
	prog.fsh = fsh
	prog:build()
	return prog
end

--------------------------------------------------------------------


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
local loadedShaderPrograms = table.weak_k{}

function getLoadedShaderPrograms()
	return loadedShaderPrograms
end


function ShaderProgram:__init()
	self.prog =  MOAIShaderProgram.new()
	self.uniformTable = {}
	self.built = false

	self.vsh = false
	self.fsh = false
	self.gsh = false
	self.tsh = false

	self.vshPath = false
	self.fshPath = false
	self.gshPath = false
	self.tshPath = false

	self.uniforms   = {}
	self.attributes = false
	self.shaders    = table.weak_k()

	self.masterConfig = false
end

function ShaderProgram:getMoaiShaderProgram()
	return self.prog
end

function ShaderProgram:build( force )
	if self.built and not force then return end
	loadedShaderPrograms[ self ] = true

	local prog  = self.prog

	local vshSource = self.vsh
	local fshSource = self.fsh
	
	local attributes = self.attributes or {'position',  'uv', 'color'}
	local uniforms   = self.uniforms
	local globals    = self.globals

	prog:purge()
	assert( 
		type( vshSource ) == 'string' and type( fshSource ) == 'string',
		'invalid shader source type'
	)
	prog:load( vshSource, fshSource )

	prog._source = self

	--setup variables
	for i, a in ipairs(attributes) do
		assert( type(a)=='string' )
		prog:setVertexAttribute( i, a )
	end
	
	local uniformTable = {}
	self.uniformTable = uniformTable
	
	local gcount = ( globals and #globals or 0 ) 
	local ucount = ( uniforms and #uniforms or 0 )

	if ( gcount + ucount ) > 0 then
		prog:reserveUniforms( gcount + ucount )
		if gcount > 0 then
			prog:reserveGlobals( gcount )
			for i, g in ipairs( globals ) do
				local idx = i
				local name = g.name
				local tt = g.type
				if tt == 'GLOBAL_PEN_COLOR' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_VECTOR_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_PEN_COLOR )
				elseif tt == 'GLOBAL_VIEW_PROJ' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_PROJ )
				elseif tt == 'GLOBAL_VIEW_WIDTH' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_FLOAT )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_WIDTH )
				elseif tt == 'GLOBAL_VIEW_HEIGHT' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_FLOAT )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_VIEW_HEIGHT )
				elseif tt == 'GLOBAL_WORLD' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD )
				elseif tt == 'GLOBAL_WORLD_VIEW' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW )
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ_NORM' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F3 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ_NORM )
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ )
				elseif tt == 'GLOBAL_WORLD_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_INV )				
				elseif tt == 'GLOBAL_WORLD_VIEW_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_INV )				
				elseif tt == 'GLOBAL_WORLD_VIEW_PROJ_INV' then
					prog:declareUniform( idx, name, MOAIShaderProgram.UNIFORM_MATRIX_F4 )
					prog:setGlobal( idx, idx, MOAIShaderProgram.GLOBAL_WORLD_VIEW_PROJ_INV )				
				else
					error( 'unkown shader global uniform type:' .. tostring( tt ) )
				end
				-- uniformTable[ name ] = idx
			end
		end

		if ucount > 0 then
			for i, u in ipairs(uniforms) do
				local idx = i + gcount
				local utype  = u.type
				local uvalue = u.value
				local name   = u.name
				if     utype == 'float' then
					prog:declareUniformFloat( idx, name, uvalue or 0 )

				elseif utype == 'int' then
					prog:declareUniformInt( idx, name, uvalue or 0 )	

				elseif utype == 'vec' then
					_warn( 'TODO' )

				elseif utype == 'color' then
					prog:declareUniform( idx, name, MOAIShader.UNIFORM_COLOR )

				elseif utype == 'sampler' then
					prog:declareUniformSampler( idx, name, uvalue or 1 )

				elseif utype == 'transform' then
					prog:declareUniform( idx,name, MOAIShader.UNIFORM_TRANSFORM )

				elseif utype == 'pen_color' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_PEN_COLOR )

				elseif utype == 'view_proj' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_VIEW_PROJ )

				elseif utype == 'world_view_proj' then
					prog:declareUniform( idx,name,MOAIShader.UNIFORM_WORLD_VIEW_PROJ )

				end
				uniformTable[ name ] = idx
			end
		end
	
	end

	self.built = true
	self:refreshShaders()

end

function ShaderProgram:refreshShaders()
	for key, shader in pairs( self.shaders ) do
		shader:setProgram( self )
	end
end

function ShaderProgram:buildShader( key )	
	if not self.built then self:build() end
	local shader = Shader()
	shader:setProgram( self )
	shader._id = key
	key = key or shader
	self.shaders[ key ] = shader
	return shader
end

function ShaderProgram:findShader( key )	
	return self.shaders[ key ]
end

function ShaderProgram:releaseShader( id )
	local shader = self.shaders[ id ]
	if not shader then
		-- _warn( 'no shader found', id )
		return false
	end
	self.shaders[ id ] = nil
end

function ShaderProgram:affirmShader( key )	
	local shader = self:findShader( key )
	if not shader then
		return self:buildShader( key )
	end
	return shader
end


--------------------------------------------------------------------
--class shader
--------------------------------------------------------------------
local shaders = table.weak()
function reportShader()
	print( 'remaining shaders:')
	for shader in pairs( shaders ) do
		local id = shader._id
		if type( id ) == 'table' then
			print( '>>', id.__name, shader.released )
		else
			-- print( shader._id )
		end
	end
end

function Shader:__init()
	self.shader = MOAIShader.new()
	self.shader.parent = self
	shaders[ self ] = true
end

function Shader:release()
	if self.prog then
		self.prog:releaseShader( self._id )
	end
	if self.config then
		self.config:releaseShader( self._id )
	end
	self.shader.parent = nil
	self.released = true
end

function Shader:setProgram( prog )
	if prog == self.prog then return end
	if self.prog then
		self.prog:releaseShader( self._id )
	end
	self.prog = prog
	self.shader:setProgram( prog:getMoaiShaderProgram() )
end

function Shader:getProgram()
	return self.prog
end

function Shader:getMoaiShader()
	return self.shader
end

function Shader:getAttrId( name )	
	return self.prog.uniformTable[ name ]
end

function Shader:hasAttr( name )
	return self:getAttrId( name ) and true or false
end

function Shader:setAttr( name, v )
	local id = self.prog.uniformTable[ name ]
	if not id then error('undefined uniform:'..name, 2) end
	return self.shader:setAttr( id, v )
end

function Shader:setAttrById( id, v )
	return self.shader:setAttr( id, v )
end

function Shader:setAttrByIdUnsafe( id, v )
	return self.shader:setAttrUnsafe( id, v )
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
CLASS: MultiShader ( Shader )
	:MODEL{}

function MultiShader:__init()
	self.shader = MOAIMultiShader.new()
	self.shader.parent = self
	self.subShaders = {}
end

function MultiShader:init( maxPass )
	self.shader:reserve( maxPass + 1 )
end

function MultiShader:release()
	for k, sub in pairs( self.subShaders ) do
		sub:release()
	end
	if self.config then
		self.config:releaseShader( self._id )
	end
	self.shader.parent = nil
end

function MultiShader:setSubShader( pass, shader )
	self.subShaders[ pass ] = shader
	self.shader:setSubShader( pass + 1, shader:getMoaiShader() )
	-- if pass == 0 then
	-- 	self:setDefaultShader( shader )
	-- end
end

function MultiShader:getSubShader( pass )
	return self.subShaders[ pass ]
end

function MultiShader:setDefaultShader( shader )
	self.defautlSubShader = shader
	self.shader:setDefaultShader( shader:getMoaiShader() )
end

function MultiShader:getDefaultShader()
	return self.defautlSubShader
end

function MultiShader:getSingleSubShader( pass )
	local shader = self:getSubShader( pass )
	if shader:isInstance( MultiShader ) then
		return shader:getDefaultShader()
	elseif shader:isInstance( Shader ) then
		return shader
	end
	return false
end