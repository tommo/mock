module 'mock'

local function buildGreyscaleShader()
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

		void main () {
			LOWP vec4 color = texture2D ( sampler, uvVarying );
			float gray = dot( color.rgb, vec3( 0.299, 0.587, 0.144 ) );
			gl_FragColor = vec4( gray, gray, gray, color.a );
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh )
	return prog:buildShader():getMoaiShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectGrayScale ( CameraImageEffect )
	:MODEL{}

function CameraImageEffectGrayScale:onBuild( prop, layer )
	prop:setShader( assert( buildGreyscaleShader() ) )
end


mock.registerComponent( 'CameraImageEffectGrayScale', CameraImageEffectGrayScale )