// Made with Amplify Shader Editor v1.9.1.5
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "SineVFX/LivingParticles/LivingParticleFloorURP"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_FinalTexture("Final Texture", 2D) = "white" {}
		_FinalColor("Final Color", Color) = (1,0,0,1)
		_FinalColor2("Final Color 2", Color) = (0,0,0,0)
		_FinalPower("Final Power", Range( 0 , 10)) = 6
		_FinalExp("Final Exp", Range( 0.2 , 4)) = 2
		_FinalMaskMultiply("Final Mask Multiply", Range( 0 , 10)) = 2
		[Toggle(_RAMPENABLED_ON)] _RampEnabled("Ramp Enabled", Float) = 0
		_Ramp("Ramp", 2D) = "white" {}
		_Distance("Distance", Float) = 1
		_DistancePower("Distance Power", Range( 0.2 , 4)) = 1
		_OffsetPower("Offset Power", Float) = 0
		[Toggle(_IGNOREYAXIS_ON)] _IgnoreYAxis("Ignore Y Axis", Float) = 0
		_Noise01("Noise 01", 2D) = "white" {}
		_Noise02("Noise 02", 2D) = "white" {}
		_Noise01ScrollSpeed("Noise 01 Scroll Speed", Float) = 0.1
		_Noise02ScrollSpeed("Noise 02 Scroll Speed", Float) = 0.15
		_NoiseDistortion("Noise Distortion", 2D) = "white" {}
		_NoiseDistortionScrollSpeed("Noise Distortion Scroll Speed", Float) = 0.05
		_NoiseDistortionPower("Noise Distortion Power", Range( 0 , 0.2)) = 0.1
		_NoisePower("Noise Power", Range( 0 , 10)) = 4
		_NoiseTiling("Noise Tiling", Float) = 0.25
		[Toggle(_ZYUV_ON)] _ZYUV("ZY UV", Float) = 0
		[Toggle(_XYUV_ON)] _XYUV("XY UV", Float) = 0
		[Toggle(_AUDIOSPECTRUMENABLED1_ON)] _AudioSpectrumEnabled1("Audio Spectrum Enabled", Float) = 0
		[HideInInspector]_AudioSpectrum("Audio Spectrum", 2D) = "white" {}
		_AudioSpectrumPower1("Audio Spectrum Power", Range( 0 , 1)) = 1
		_AudioSpectrumDistanceTiling1("Audio Spectrum Distance Tiling", Float) = 4
		[Toggle(_AUDIOMASKENABLED1_ON)] _AudioMaskEnabled1("Audio Mask Enabled", Float) = 0
		_AudioMaskExp1("Audio Mask Exp", Range( 0.1 , 4)) = 1
		_AudioMaskMultiply1("Audio Mask Multiply", Range( 1 , 4)) = 1
		_AudioMaskAffectsAmplitude1("Audio Mask Affects Amplitude", Range( 0 , 1)) = 0
		[Toggle(_AUDIOAMPLITUDEENABLED1_ON)] _AudioAmplitudeEnabled1("Audio Amplitude Enabled", Float) = 0
		_AudioAmplitudeEmissionPower1("Audio Amplitude Emission Power", Range( 0 , 4)) = 1
		[ASEEnd]_AudioAmplitudeOffsetPower1("Audio Amplitude Offset Power", Range( 0 , 4)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Unlit" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 3.5
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma multi_compile _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			#pragma multi_compile _ LIGHTMAP_ON
			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma shader_feature _ _SAMPLE_GI
			#pragma multi_compile _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON
			#pragma shader_feature _RAMPENABLED_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_color : COLOR;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;
			sampler2D _Ramp;
			sampler2D _FinalTexture;


			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				
				o.ase_texcoord3 = v.ase_texcoord;
				o.ase_texcoord4 = v.ase_texcoord1;
				o.ase_color = v.ase_color;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = positionCS;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				#ifdef ASE_FOG
					o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif

				o.clipPos = positionCS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_color : COLOR;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				o.ase_color = v.ase_color;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float4 appendResult17 = (float4(IN.ase_texcoord3.z , IN.ase_texcoord3.w , IN.ase_texcoord4.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2D( _NoiseDistortion, panner131 );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2D( _Noise02, lerpResult127 ).r * tex2D( _Noise01, lerpResult128 ).r * _NoisePower );
				float4 appendResult168 = (float4(IN.ase_texcoord3.z , IN.ase_texcoord3.w , IN.ase_texcoord4.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2D( _AudioSpectrum, appendResult183 ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float4 lerpResult37 = lerp( _FinalColor2 , _FinalColor , pow( ResultMaskModified90 , _FinalExp ));
				float2 appendResult83 = (float2(ResultMaskModified90 , 0.0));
				#ifdef _RAMPENABLED_ON
				float4 staticSwitch81 = tex2D( _Ramp, appendResult83 );
				#else
				float4 staticSwitch81 = lerpResult37;
				#endif
				float2 uv_FinalTexture = IN.ase_texcoord3.xy * _FinalTexture_ST.xy + _FinalTexture_ST.zw;
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( staticSwitch81 * IN.ase_color * _FinalPower * tex2D( _FinalTexture, uv_FinalTexture ).r * ( 1.0 + ( _AudioAverageAmplitude * _AudioAmplitudeEmissionPower1 * staticSwitch157 * clampResult158 ) ) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(IN.clipPos, Color);
				#endif

				#if defined(_ALPHAPREMULTIPLY_ON)
				Color *= Alpha;
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			float3 _LightDirection;
			float3 _LightPosition;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 clipPos = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				o.clipPos = clipPos;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = IN.worldPos;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "SceneSelectionPass"
            Tags { "LightMode"="SceneSelectionPass" }

			Cull Off

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			float4 _SelectionID;


			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				o.clipPos = TransformWorldToHClip(positionWS);
				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = _SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On


			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "DepthNormalsOnly"
            Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#define ASE_SRP_VERSION 120107


			#pragma exclude_renderers glcore gles gles3 
			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define ATTRIBUTES_NEED_TEXCOORD1
			#define VARYINGS_NEED_NORMAL_WS
			#define VARYINGS_NEED_TANGENT_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#pragma shader_feature _IGNOREYAXIS_ON
			#pragma shader_feature _ZYUV_ON
			#pragma shader_feature _XYUV_ON
			#pragma shader_feature _AUDIOSPECTRUMENABLED1_ON
			#pragma shader_feature _AUDIOMASKENABLED1_ON
			#pragma shader_feature _AUDIOAMPLITUDEENABLED1_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float3 normalWS : TEXCOORD0;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _FinalColor;
			float4 _FinalColor2;
			float4 _FinalTexture_ST;
			float _Distance;
			float _FinalPower;
			float _FinalExp;
			float _AudioMaskAffectsAmplitude1;
			float _AudioAmplitudeOffsetPower1;
			float _OffsetPower;
			float _AudioSpectrumPower1;
			float _AudioMaskMultiply1;
			float _AudioMaskExp1;
			float _NoisePower;
			float _Noise01ScrollSpeed;
			float _NoiseDistortionPower;
			float _NoiseDistortionScrollSpeed;
			float _NoiseTiling;
			float _Noise02ScrollSpeed;
			float _FinalMaskMultiply;
			float _DistancePower;
			float _AudioSpectrumDistanceTiling1;
			float _AudioAmplitudeEmissionPower1;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END
			float4 _Affector;
			sampler2D _Noise02;
			sampler2D _NoiseDistortion;
			sampler2D _Noise01;
			float3 _AudioPosition1;
			sampler2D _AudioSpectrum;
			float _AudioAverageAmplitude;


			
			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			VertexOutput VertexFunction(VertexInput v  )
			{
				VertexOutput o;
				ZERO_INITIALIZE(VertexOutput, o);

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float4 appendResult17 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				#ifdef _IGNOREYAXIS_ON
				float3 staticSwitch93 = float3(1,0,1);
				#else
				float3 staticSwitch93 = float3(1,1,1);
				#endif
				float DistanceMask45 = ( 1.0 - distance( ( appendResult17 * float4( staticSwitch93 , 0.0 ) ) , ( _Affector * float4( staticSwitch93 , 0.0 ) ) ) );
				float clampResult23 = clamp( (0.0 + (( DistanceMask45 + ( _Distance - 1.0 ) ) - 0.0) * (1.0 - 0.0) / (_Distance - 0.0)) , 0.0 , 1.0 );
				float ResultMask53 = pow( clampResult23 , _DistancePower );
				float4 break102 = appendResult17;
				float2 appendResult104 = (float2(break102.x , break102.z));
				float2 appendResult142 = (float2(break102.x , break102.y));
				#ifdef _XYUV_ON
				float2 staticSwitch140 = appendResult142;
				#else
				float2 staticSwitch140 = appendResult104;
				#endif
				float2 appendResult143 = (float2(break102.z , break102.y));
				#ifdef _ZYUV_ON
				float2 staticSwitch141 = appendResult143;
				#else
				float2 staticSwitch141 = staticSwitch140;
				#endif
				float2 ParticlePositionUV106 = staticSwitch141;
				float2 temp_output_119_0 = ( ParticlePositionUV106 * _NoiseTiling );
				float2 panner109 = ( ( ( _TimeParameters.x ) * _Noise02ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 panner131 = ( ( ( _TimeParameters.x ) * _NoiseDistortionScrollSpeed ) * float2( 0.05,0.05 ) + temp_output_119_0);
				float4 tex2DNode132 = tex2Dlod( _NoiseDistortion, float4( panner131, 0, 0.0) );
				float2 temp_cast_2 = (tex2DNode132.r).xx;
				float2 lerpResult127 = lerp( panner109 , temp_cast_2 , _NoiseDistortionPower);
				float2 panner110 = ( ( ( _TimeParameters.x ) * _Noise01ScrollSpeed ) * float2( 1,1 ) + temp_output_119_0);
				float2 temp_cast_3 = (tex2DNode132.r).xx;
				float2 lerpResult128 = lerp( panner110 , temp_cast_3 , _NoiseDistortionPower);
				float ResultNoise111 = ( tex2Dlod( _Noise02, float4( lerpResult127, 0, 0.0) ).r * tex2Dlod( _Noise01, float4( lerpResult128, 0, 0.0) ).r * _NoisePower );
				float4 appendResult168 = (float4(v.ase_texcoord.z , v.ase_texcoord.w , v.ase_texcoord1.x , 0.0));
				float temp_output_170_0 = distance( appendResult168 , float4( _AudioPosition1 , 0.0 ) );
				float clampResult176 = clamp( (0.0 + (( -temp_output_170_0 + _AudioSpectrumDistanceTiling1 ) - 0.0) * (1.0 - 0.0) / (_AudioSpectrumDistanceTiling1 - 0.0)) , 0.0 , 1.0 );
				float clampResult184 = clamp( ( pow( clampResult176 , _AudioMaskExp1 ) * _AudioMaskMultiply1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOMASKENABLED1_ON
				float staticSwitch187 = clampResult184;
				#else
				float staticSwitch187 = 1.0;
				#endif
				float2 appendResult183 = (float2(( temp_output_170_0 * ( 1.0 / _AudioSpectrumDistanceTiling1 ) ) , 0.0));
				float clampResult191 = clamp( ( staticSwitch187 * tex2Dlod( _AudioSpectrum, float4( appendResult183, 0, 0.0) ).r * _AudioSpectrumPower1 ) , 0.0 , 1.0 );
				#ifdef _AUDIOSPECTRUMENABLED1_ON
				float staticSwitch192 = clampResult191;
				#else
				float staticSwitch192 = 0.0;
				#endif
				float clampResult88 = clamp( ( ( ResultMask53 * _FinalMaskMultiply ) + ResultNoise111 + staticSwitch192 ) , 0.0 , 1.0 );
				float ResultMaskModified90 = clampResult88;
				float3 appendResult138 = (float3(v.ase_texcoord1.y , v.ase_texcoord1.z , v.ase_texcoord1.w));
				float3 normalizeResult139 = normalize( appendResult138 );
				#ifdef _AUDIOAMPLITUDEENABLED1_ON
				float staticSwitch157 = 1.0;
				#else
				float staticSwitch157 = 0.0;
				#endif
				float clampResult158 = clamp( ( ( 1.0 - _AudioMaskAffectsAmplitude1 ) + staticSwitch187 ) , 0.0 , 1.0 );
				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = ( ( 1.0 - ResultMaskModified90 ) * _OffsetPower * normalizeResult139 * ( ( _AudioAverageAmplitude * _AudioAmplitudeOffsetPower1 * staticSwitch157 * clampResult158 ) + 1.0 ) );

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldNormal(v.ase_normal);

				o.clipPos = TransformWorldToHClip(positionWS);
				o.normalWS.xyz =  normalWS;

				return o;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				

				surfaceDescription.Alpha = 1;
				surfaceDescription.AlphaClipThreshold = 0.5;

				#if _ALPHATEST_ON
					clip(surfaceDescription.Alpha - surfaceDescription.AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				float3 normalWS = IN.normalWS;

				return half4(NormalizeNormalPerPixel(normalWS), 0.0);
			}

			ENDHLSL
		}
		
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19105
Node;AmplifyShaderEditor.TexCoordVertexDataNode;148;-3324.907,-1265.587;Inherit;False;0;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;149;-3322.907,-1054.587;Inherit;False;1;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;17;-2987.389,-1125.477;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;193;-5449.919,527.4488;Inherit;False;0;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;97;-3274.945,-713.9004;Float;False;Constant;_Vector2;Vector 2;11;0;Create;True;0;0;0;False;0;False;1,1,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexCoordVertexDataNode;167;-5426.953,762.7659;Inherit;False;1;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.BreakToComponentsNode;102;-2749.313,-1303.455;Inherit;False;FLOAT4;1;0;FLOAT4;0,0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.Vector3Node;96;-3280.945,-863.9004;Float;False;Constant;_Vector1;Vector 1;11;0;Create;True;0;0;0;False;0;False;1,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;168;-5090.953,698.7659;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.Vector3Node;169;-5138.953,922.7659;Inherit;False;Global;_AudioPosition1;_AudioPosition;33;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;104;-2470.998,-1297.124;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;142;-2469.166,-1404.684;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.Vector4Node;20;-3031.338,-970.8239;Float;False;Global;_Affector;_Affector;3;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;93;-3043.945,-791.9004;Float;False;Property;_IgnoreYAxis;Ignore Y Axis;11;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT3;0,0,0;False;0;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;-2744.945,-1111.9;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DistanceOpNode;170;-4818.953,810.7659;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;140;-2226.134,-1435.527;Float;False;Property;_XYUV;XY UV;22;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-2739.945,-969.9004;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;143;-2459.352,-1524.997;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;141;-1977.886,-1514.628;Float;False;Property;_ZYUV;ZY UV;21;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT2;0,0;False;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT2;0,0;False;6;FLOAT2;0,0;False;7;FLOAT2;0,0;False;8;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DistanceOpNode;19;-2446.929,-1046.137;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode;171;-4338.953,1354.766;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;172;-4434.953,1034.766;Float;False;Property;_AudioSpectrumDistanceTiling1;Audio Spectrum Distance Tiling;26;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;22;-2283.804,-1040.446;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;106;-1796.388,-1303.287;Float;False;ParticlePositionUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;173;-4178.953,1418.766;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-3323.018,-279.5234;Float;False;Property;_Distance;Distance;8;0;Create;True;0;0;0;False;0;False;1;1.75;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;27;-3322.463,-176.7314;Float;False;Constant;_Float0;Float 0;4;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;107;-3865.778,-2001.611;Inherit;False;106;ParticlePositionUV;1;0;OBJECT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-3786.271,-1925.718;Float;False;Property;_NoiseTiling;Noise Tiling;20;0;Create;True;0;0;0;False;0;False;0.25;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TimeNode;124;-3988.08,-2455.51;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;45;-2107.307,-1043.219;Float;False;DistanceMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;174;-4034.953,1418.766;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;134;-4061.681,-2638.726;Float;False;Property;_NoiseDistortionScrollSpeed;Noise Distortion Scroll Speed;17;0;Create;True;0;0;0;False;0;False;0.05;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;176;-3858.953,1418.766;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;177;-4002.953,1610.766;Float;False;Property;_AudioMaskExp1;Audio Mask Exp;28;0;Create;True;0;0;0;False;0;False;1;1;0.1;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;175;-4306.953,954.7659;Float;False;Constant;_Float6;Float 4;28;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;47;-3385.508,-374.6587;Inherit;False;45;DistanceMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;122;-4014.08,-2538.51;Float;False;Property;_Noise02ScrollSpeed;Noise 02 Scroll Speed;15;0;Create;True;0;0;0;False;0;False;0.15;0.12;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;119;-3581.271,-1988.717;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;26;-3132.352,-237.1247;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-4012.08,-2307.51;Float;False;Property;_Noise01ScrollSpeed;Noise 01 Scroll Speed;14;0;Create;True;0;0;0;False;0;False;0.1;0.08;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;133;-3582.353,-2614.693;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;131;-3242.619,-2882.083;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;0.05,0.05;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-2884.253,-305.0402;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;178;-3650.953,1450.766;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;126;-3587.08,-2380.51;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;31;-2904.552,-355.7464;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;125;-3586.08,-2505.51;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;179;-3778.953,1706.766;Float;False;Property;_AudioMaskMultiply1;Audio Mask Multiply;29;0;Create;True;0;0;0;False;0;False;1;1;1;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;180;-4130.953,986.7659;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;182;-3954.953,794.7659;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;181;-3394.953,1578.766;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode;28;-2625.198,-390.5479;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;109;-2909.619,-2349.673;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;132;-3037.619,-2899.083;Inherit;True;Property;_NoiseDistortion;Noise Distortion;16;0;Create;True;0;0;0;False;0;False;-1;None;19bfab0886d4ce348ba29f17a191277b;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;129;-3014.997,-2687.215;Float;False;Property;_NoiseDistortionPower;Noise Distortion Power;18;0;Create;True;0;0;0;False;0;False;0.1;0.2;0;0.2;0;1;FLOAT;0
Node;AmplifyShaderEditor.PannerNode;110;-2906.136,-2089.58;Inherit;False;3;0;FLOAT2;0,0;False;2;FLOAT2;1,1;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;128;-2440.74,-2356.307;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;34;-2642.906,-219.4901;Float;False;Property;_DistancePower;Distance Power;9;0;Create;True;0;0;0;False;0;False;1;1;0.2;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;183;-3778.953,794.7659;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;184;-3250.953,1562.766;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;127;-2444.489,-2599.995;Inherit;False;3;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ClampOpNode;23;-2441.016,-389.9604;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;185;-3650.953,1306.766;Float;False;Constant;_Float9;Float 8;29;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;188;-3634.953,762.7659;Inherit;True;Property;_AudioSpectrum;Audio Spectrum;24;1;[HideInInspector];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;187;-3426.953,1322.766;Float;False;Property;_AudioMaskEnabled1;Audio Mask Enabled;27;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;186;-3618.953,970.7659;Inherit;False;Property;_AudioSpectrumPower1;Audio Spectrum Power;25;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;33;-2205.906,-309.4904;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;114;-1901.047,-2176.647;Float;False;Property;_NoisePower;Noise Power;19;0;Create;True;0;0;0;False;0;False;4;6;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;98;-1922.118,-2380.805;Inherit;True;Property;_Noise01;Noise 01;12;0;Create;True;0;0;0;False;0;False;-1;None;e16f8e2dd5ea82044bade391afc45676;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;99;-1920.546,-2647.616;Inherit;True;Property;_Noise02;Noise 02;13;0;Create;True;0;0;0;False;0;False;-1;None;fe9b27216f3b18f499e61ce73ae8dad2;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;105;-1462.533,-2492.596;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;53;-2016.534,-316.0599;Float;False;ResultMask;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;-3282.953,714.7659;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;191;-3010.953,794.7659;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;190;-2786.953,778.7659;Float;False;Constant;_Float3;Float 2;26;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;86;-2971.988,171.2753;Float;False;Property;_FinalMaskMultiply;Final Mask Multiply;5;0;Create;True;0;0;0;False;0;False;2;3;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;111;-1273.442,-2496.126;Float;False;ResultNoise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;54;-2899.038,89.09859;Inherit;False;53;ResultMask;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;192;-2610.953,794.7659;Float;False;Property;_AudioSpectrumEnabled1;Audio Spectrum Enabled;23;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;118;-2740.755,446.5673;Inherit;False;111;ResultNoise;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;85;-2664.985,121.2754;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;151;-1304.897,-43.02383;Inherit;False;Property;_AudioMaskAffectsAmplitude1;Audio Mask Affects Amplitude;30;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;117;-2425.914,316.1152;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;152;-942.1083,14.65697;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;154;-1305.628,-372.4787;Inherit;False;Constant;_Float8;Float 7;32;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;-743.3395,96.76801;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;153;-1304.628,-445.4788;Inherit;False;Constant;_Float7;Float 6;32;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;88;-2190.81,111.4448;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;160;-768.2177,-505.2585;Float;False;Global;_AudioAverageAmplitude;_AudioAverageAmplitude;26;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexCoordVertexDataNode;137;-165.6544,512.7655;Inherit;False;1;4;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode;90;-2024.181,110.9656;Float;False;ResultMaskModified;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;159;-782.5157,-310.6408;Float;False;Property;_AudioAmplitudeOffsetPower1;Audio Amplitude Offset Power;33;0;Create;True;0;0;0;False;0;False;1;1;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;157;-1124.692,-430.2963;Inherit;False;Property;_AudioAmplitudeEnabled1;Audio Amplitude Enabled;31;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;158;-609.1088,101.6569;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;164;-449.4224,-183.4261;Float;False;Constant;_Float4;Float 3;28;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-446.4124,-327.2186;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;92;-79.78304,290.7678;Inherit;False;90;ResultMaskModified;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;138;61.84087,557.433;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;89;178.3751,294.9239;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;43;165.2519,386.878;Float;False;Property;_OffsetPower;Offset Power;10;0;Create;True;0;0;0;False;0;False;0;-1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;139;204.7481,557.2629;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;165;-251.545,-280.1282;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;135;-1159.57,-1377.248;Float;False;Property;_FinalExp;Final Exp;4;0;Create;True;0;0;0;False;0;False;2;2;0.2;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;36;-880.678,-1782.035;Float;False;Property;_FinalColor2;Final Color 2;2;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DynamicAppendNode;83;-816.4039,-1255.788;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ColorNode;14;-874.975,-1595.518;Float;False;Property;_FinalColor;Final Color;1;0;Create;True;0;0;0;False;0;False;1,0,0,1;1,0,0,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.StaticSwitch;81;25.73351,-1424.518;Float;False;Property;_RampEnabled;Ramp Enabled;6;0;Create;True;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;All;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;82;-441.7664,-1373.116;Inherit;True;Property;_Ramp;Ramp;7;0;Create;True;0;0;0;False;0;False;-1;None;1260249478b816b468c2888f0a40a2e0;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;156;-788.1887,-411.2021;Float;False;Property;_AudioAmplitudeEmissionPower1;Audio Amplitude Emission Power;32;0;Create;True;0;0;0;False;0;False;1;1;0;4;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;3;437.6673,-1320.86;Inherit;False;5;5;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.PowerNode;136;-821.571,-1425.248;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;166;-246.3046,-562.468;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;84;-1026.458,-1209.971;Float;False;Constant;_Float5;Float 5;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;161;-473.3056,-604.468;Float;False;Constant;_Float2;Float 1;27;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-448.187,-467.2021;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;37;-548.8058,-1697.366;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;4;-47.0505,-1132.769;Float;False;Property;_FinalPower;Final Power;3;0;Create;True;0;0;0;False;0;False;6;3;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;42;483.6871,309.0532;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;91;-1136.402,-1292.252;Inherit;False;90;ResultMaskModified;1;0;OBJECT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;147;-63.16714,-1041.559;Inherit;True;Property;_FinalTexture;Final Texture;0;0;Create;True;0;0;0;False;0;False;-1;None;a0c8393bc92291e438c0a270fbfa611f;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;52;65.49101,-1305.91;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;196;993.235,-582.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;194;993.235,-582.7628;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;SineVFX/LivingParticles/LivingParticleFloorURP;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;23;Surface;0;0;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Cast Shadows;1;0;  Use Shadow Threshold;0;0;Receive Shadows;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;DOTS Instancing;0;0;Meta Pass;0;0;Extra Pre Pass;0;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Vertex Position,InvertActionOnDeselection;1;0;0;10;False;True;True;True;False;False;True;True;True;True;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;195;993.235,-582.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;197;993.235,-582.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;198;993.235,-582.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;199;993.235,-542.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;200;993.235,-542.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;201;993.235,-542.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;202;993.235,-542.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;203;993.235,-542.7628;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;3;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
WireConnection;17;0;148;3
WireConnection;17;1;148;4
WireConnection;17;2;149;1
WireConnection;102;0;17;0
WireConnection;168;0;193;3
WireConnection;168;1;193;4
WireConnection;168;2;167;1
WireConnection;104;0;102;0
WireConnection;104;1;102;2
WireConnection;142;0;102;0
WireConnection;142;1;102;1
WireConnection;93;1;97;0
WireConnection;93;0;96;0
WireConnection;94;0;17;0
WireConnection;94;1;93;0
WireConnection;170;0;168;0
WireConnection;170;1;169;0
WireConnection;140;1;104;0
WireConnection;140;0;142;0
WireConnection;95;0;20;0
WireConnection;95;1;93;0
WireConnection;143;0;102;2
WireConnection;143;1;102;1
WireConnection;141;1;140;0
WireConnection;141;0;143;0
WireConnection;19;0;94;0
WireConnection;19;1;95;0
WireConnection;171;0;170;0
WireConnection;22;0;19;0
WireConnection;106;0;141;0
WireConnection;173;0;171;0
WireConnection;173;1;172;0
WireConnection;45;0;22;0
WireConnection;174;0;173;0
WireConnection;174;2;172;0
WireConnection;176;0;174;0
WireConnection;119;0;107;0
WireConnection;119;1;120;0
WireConnection;26;0;25;0
WireConnection;26;1;27;0
WireConnection;133;0;124;2
WireConnection;133;1;134;0
WireConnection;131;0;119;0
WireConnection;131;1;133;0
WireConnection;24;0;47;0
WireConnection;24;1;26;0
WireConnection;178;0;176;0
WireConnection;178;1;177;0
WireConnection;126;0;124;2
WireConnection;126;1;121;0
WireConnection;31;0;25;0
WireConnection;125;0;124;2
WireConnection;125;1;122;0
WireConnection;180;0;175;0
WireConnection;180;1;172;0
WireConnection;182;0;170;0
WireConnection;182;1;180;0
WireConnection;181;0;178;0
WireConnection;181;1;179;0
WireConnection;28;0;24;0
WireConnection;28;2;31;0
WireConnection;109;0;119;0
WireConnection;109;1;125;0
WireConnection;132;1;131;0
WireConnection;110;0;119;0
WireConnection;110;1;126;0
WireConnection;128;0;110;0
WireConnection;128;1;132;1
WireConnection;128;2;129;0
WireConnection;183;0;182;0
WireConnection;184;0;181;0
WireConnection;127;0;109;0
WireConnection;127;1;132;1
WireConnection;127;2;129;0
WireConnection;23;0;28;0
WireConnection;188;1;183;0
WireConnection;187;1;185;0
WireConnection;187;0;184;0
WireConnection;33;0;23;0
WireConnection;33;1;34;0
WireConnection;98;1;128;0
WireConnection;99;1;127;0
WireConnection;105;0;99;1
WireConnection;105;1;98;1
WireConnection;105;2;114;0
WireConnection;53;0;33;0
WireConnection;189;0;187;0
WireConnection;189;1;188;1
WireConnection;189;2;186;0
WireConnection;191;0;189;0
WireConnection;111;0;105;0
WireConnection;192;1;190;0
WireConnection;192;0;191;0
WireConnection;85;0;54;0
WireConnection;85;1;86;0
WireConnection;117;0;85;0
WireConnection;117;1;118;0
WireConnection;117;2;192;0
WireConnection;152;0;151;0
WireConnection;155;0;152;0
WireConnection;155;1;187;0
WireConnection;88;0;117;0
WireConnection;90;0;88;0
WireConnection;157;1;153;0
WireConnection;157;0;154;0
WireConnection;158;0;155;0
WireConnection;163;0;160;0
WireConnection;163;1;159;0
WireConnection;163;2;157;0
WireConnection;163;3;158;0
WireConnection;138;0;137;2
WireConnection;138;1;137;3
WireConnection;138;2;137;4
WireConnection;89;0;92;0
WireConnection;139;0;138;0
WireConnection;165;0;163;0
WireConnection;165;1;164;0
WireConnection;83;0;91;0
WireConnection;83;1;84;0
WireConnection;81;1;37;0
WireConnection;81;0;82;0
WireConnection;82;1;83;0
WireConnection;3;0;81;0
WireConnection;3;1;52;0
WireConnection;3;2;4;0
WireConnection;3;3;147;1
WireConnection;3;4;166;0
WireConnection;136;0;91;0
WireConnection;136;1;135;0
WireConnection;166;0;161;0
WireConnection;166;1;162;0
WireConnection;162;0;160;0
WireConnection;162;1;156;0
WireConnection;162;2;157;0
WireConnection;162;3;158;0
WireConnection;37;0;36;0
WireConnection;37;1;14;0
WireConnection;37;2;136;0
WireConnection;42;0;89;0
WireConnection;42;1;43;0
WireConnection;42;2;139;0
WireConnection;42;3;165;0
WireConnection;194;2;3;0
WireConnection;194;5;42;0
ASEEND*/
//CHKSM=744C726543F6752C0766B6C561F794864CEC1F34