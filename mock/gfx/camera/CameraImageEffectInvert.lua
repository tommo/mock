module 'mock'

local function buildInvertShader()
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
			gl_FragColor = vec4( 1.0 - color.r, 1.0 - color.g, 1.0 - color.b, color.a );
		}
	]]

	local prog = buildShaderProgramFromString( vsh, fsh )
	return prog:buildShader():getMoaiShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectInvert ( CameraImageEffect )
	:MODEL{}

function CameraImageEffectInvert:onBuild( prop, framebuffer, layer, passId )
	prop:setShader( assert( buildInvertShader() ) )
end


mock.registerComponent( 'CameraImageEffectInvert', CameraImageEffectInvert )