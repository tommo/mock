module 'mock'

local function buildLUTShader()
	local vsh = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		void main () {
			gl_Position = position;
			uvVarying = uv;
			colorVarying = color;
		}
	]]

	local fsh = [[	
		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;

		uniform sampler2D sampler;
		uniform sampler2D samplerLUT;

		vec4 sampleAs3DTexture( sampler2D texture, vec3 uv, float width ) {
			float sliceSize = 1.0 / width;              // space of 1 slice
			float slicePixelSize = sliceSize / width;           // space of 1 pixel
			float sliceInnerSize = slicePixelSize * (width - 1.0);  // space of width pixels
			float zSlice0 = min(floor(uv.z * width), width - 1.0);
			float zSlice1 = min(zSlice0 + 1.0, width - 1.0);
			float xOffset = slicePixelSize * 0.5 + uv.x * sliceInnerSize;
			float s0 = xOffset + (zSlice0 * sliceSize);
			float s1 = xOffset + (zSlice1 * sliceSize);
			vec4 slice0Color = texture2D(texture, vec2(s0, uv.y));
			vec4 slice1Color = texture2D(texture, vec2(s1, uv.y));
			float zOffset = mod(uv.z * width, 1.0);
			vec4 result = mix(slice0Color, slice1Color, zOffset);
			return result;
		}

		void main () {
			LOWP vec4 pixel = texture2D ( sampler, uvVarying );
			vec4 gradedPixel = sampleAs3DTexture( samplerLUT, pixel.rgb, 32.0 );
			gradedPixel.a = pixel.a;
			gl_FragColor = gradedPixel;
		}

	]]

	local vars = {
		uniforms = {
			{
				name  = "sampler",
				type  = "sampler",
				value = 1
			},
			{
				name  = "samplerLUT",
				type  = "sampler",
				value = 2
			},
		}
	}
	local prog = buildShaderProgramFromString( vsh, fsh, vars )
	return prog:buildShader():getMoaiShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectColorGrading ( CameraImageEffect )
	:MODEL{
		Field 'LUT' :asset( 'texture' ) :getset( 'LUTPath')
}

function CameraImageEffectColorGrading:__init()
	self.lutPath = false
	self.tex = MOAIMultiTexture.new()
	self.tex:reserve( 2 )
end

function CameraImageEffectColorGrading:onBuild( prop, texture, layer, passId )
	self.tex:setTexture( 1, texture )
	prop:setTexture( self.tex )
	prop:setShader( assert( buildLUTShader() ) )
end

function CameraImageEffectColorGrading:setLUTPath( path )
	self.lutPath = path
	local texture = mock.loadAsset( path )
	if texture then
		self.tex:setTexture( 2, texture:getMoaiTexture() )
	end
end

function CameraImageEffectColorGrading:getLUTPath()
	return self.lutPath
end

mock.registerComponent( 'CameraImageEffectColorGrading', CameraImageEffectColorGrading )

