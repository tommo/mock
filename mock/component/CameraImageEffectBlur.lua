module 'mock'

local function buildBlurShader( passId )

	local vshH = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;
		varying MEDP vec2 v_blurTexCoords[14]; //OUT

		uniform float viewWidth;
		uniform float viewHeight;

		void main () {
			float du = 1.0/viewWidth;
			gl_Position = position;
			uvVarying = uv;
			colorVarying = color;
			v_blurTexCoords[ 0] = uv + vec2(-du*7.0, 0.0);
			v_blurTexCoords[ 1] = uv + vec2(-du*6.0, 0.0);
			v_blurTexCoords[ 2] = uv + vec2(-du*5.0, 0.0);
			v_blurTexCoords[ 3] = uv + vec2(-du*4.0, 0.0);
			v_blurTexCoords[ 4] = uv + vec2(-du*3.0, 0.0);
			v_blurTexCoords[ 5] = uv + vec2(-du*2.0, 0.0);
			v_blurTexCoords[ 6] = uv + vec2(-du*1.0, 0.0);
			v_blurTexCoords[ 7] = uv + vec2( du*1.0, 0.0);
			v_blurTexCoords[ 8] = uv + vec2( du*2.0, 0.0);
			v_blurTexCoords[ 9] = uv + vec2( du*3.0, 0.0);
			v_blurTexCoords[10] = uv + vec2( du*4.0, 0.0);
			v_blurTexCoords[11] = uv + vec2( du*5.0, 0.0);
			v_blurTexCoords[12] = uv + vec2( du*6.0, 0.0);
			v_blurTexCoords[13] = uv + vec2( du*7.0, 0.0);
		}
	]]


	local vshV = [[
		attribute vec4 position;
		attribute vec2 uv;
		attribute vec4 color;

		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;
		varying MEDP vec2 v_blurTexCoords[14]; //OUT

		uniform float viewWidth;
		uniform float viewHeight;

		void main () {
			float dv = 1.0/viewHeight;
			gl_Position = position;
			uvVarying = uv;
			colorVarying = color;
			v_blurTexCoords[ 0] = uv + vec2( 0.0, -dv*7.0 );
			v_blurTexCoords[ 1] = uv + vec2( 0.0, -dv*6.0 );
			v_blurTexCoords[ 2] = uv + vec2( 0.0, -dv*5.0 );
			v_blurTexCoords[ 3] = uv + vec2( 0.0, -dv*4.0 );
			v_blurTexCoords[ 4] = uv + vec2( 0.0, -dv*3.0 );
			v_blurTexCoords[ 5] = uv + vec2( 0.0, -dv*2.0 );
			v_blurTexCoords[ 6] = uv + vec2( 0.0, -dv*1.0 );
			v_blurTexCoords[ 7] = uv + vec2( 0.0,  dv*1.0 );
			v_blurTexCoords[ 8] = uv + vec2( 0.0,  dv*2.0 );
			v_blurTexCoords[ 9] = uv + vec2( 0.0,  dv*3.0 );
			v_blurTexCoords[10] = uv + vec2( 0.0,  dv*4.0 );
			v_blurTexCoords[11] = uv + vec2( 0.0,  dv*5.0 );
			v_blurTexCoords[12] = uv + vec2( 0.0,  dv*6.0 );
			v_blurTexCoords[13] = uv + vec2( 0.0,  dv*7.0 );
		}
	]]

	local fsh = [[	
		varying LOWP vec4 colorVarying;
		varying MEDP vec2 uvVarying;
		varying MEDP vec2 v_blurTexCoords[14]; //OUT

		uniform sampler2D sampler;
		
		void main () {
			gl_FragColor = vec4(0.0);
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 0])*0.0044299121055113265;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 1])*0.00895781211794;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 2])*0.0215963866053;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 3])*0.0443683338718;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 4])*0.0776744219933;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 5])*0.115876621105;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 6])*0.147308056121;
			gl_FragColor += texture2D(sampler, uvVarying         )*0.159576912161;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 7])*0.147308056121;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 8])*0.115876621105;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[ 9])*0.0776744219933;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[10])*0.0443683338718;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[11])*0.0215963866053;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[12])*0.00895781211794;
			gl_FragColor += texture2D(sampler, v_blurTexCoords[13])*0.0044299121055113265;
		}
	]]

	local vsh = passId == 1 and vshH or vshV
	local prog = buildShaderProgramFromString( vsh, fsh, {
		uniforms = {
			{
				name = "sampler",
				type = "sampler",
				value = 1
			},
			{
				name = "time",
				type = "float",
				value = 0
			},
			{
				name = "intensity",
				type = "float",
				value = 2
			}
		},
		globals = {
			{
				name = 'viewWidth',
				type = 'GLOBAL_VIEW_WIDTH',
			},
			{
				name = 'viewHeight',
				type = 'GLOBAL_VIEW_HEIGHT',
			}
		}
	} )
	return prog:buildShader():getMoaiShader()
end

--------------------------------------------------------------------
CLASS: CameraImageEffectBlur ( CameraImageEffect )
	:MODEL{}

function CameraImageEffectBlur:getPassCount()
	return 2
end

function CameraImageEffectBlur:onBuild( prop, frameBuffer, layer, passId )
	if passId == 1 then
		prop:setShader( assert( buildBlurShader( passId ) ) )
	elseif passId == 2 then
		prop:setShader( assert( buildBlurShader( passId ) ) )
	end
end


mock.registerComponent( 'CameraImageEffectBlur', CameraImageEffectBlur )