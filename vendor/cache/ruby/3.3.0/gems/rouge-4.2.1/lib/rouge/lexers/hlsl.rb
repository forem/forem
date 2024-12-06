# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'c.rb'

    class HLSL < C
      title "HLSL"
      desc "HLSL, the High Level Shading Language for DirectX (docs.microsoft.com/en-us/windows/win32/direct3dhlsl/dx-graphics-hlsl)"
      tag 'hlsl'
      filenames '*.hlsl', '*.hlsli'
      mimetypes 'text/x-hlsl'

      def self.keywords
        @keywords ||= Set.new %w(
          asm asm_fragment break case cbuffer centroid class column_major
          compile compile_fragment const continue default discard do else export
          extern for fxgroup globallycoherent groupshared if in inline inout
          interface line lineadj linear namespace nointerpolation noperspective
          NULL out packoffset pass pixelfragment point precise return register
          row_major sample sampler shared stateblock stateblock_state static
          struct switch tbuffer technique technique10 technique11 texture
          typedef triangle uniform vertexfragment volatile while
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          dword matrix snorm string unorm unsigned void vector BlendState Buffer
          ByteAddressBuffer ComputeShader DepthStencilState DepthStencilView
          DomainShader GeometryShader HullShader InputPatch LineStream
          OutputPatch PixelShader PointStream RasterizerState RenderTargetView
          RasterizerOrderedBuffer RasterizerOrderedByteAddressBuffer
          RasterizerOrderedStructuredBuffer RasterizerOrderedTexture1D
          RasterizerOrderedTexture1DArray RasterizerOrderedTexture2D
          RasterizerOrderedTexture2DArray RasterizerOrderedTexture3D RWBuffer
          RWByteAddressBuffer RWStructuredBuffer RWTexture1D RWTexture1DArray
          RWTexture2D RWTexture2DArray RWTexture3D SamplerState
          SamplerComparisonState StructuredBuffer Texture1D Texture1DArray
          Texture2D Texture2DArray Texture2DMS Texture2DMSArray Texture3D
          TextureCube TextureCubeArray TriangleStream VertexShader

          bool1 bool2 bool3 bool4 BOOL1 BOOL2 BOOL3 BOOL4
          int1 int2 int3 int4
          half1 half2 half3 half4
          float1 float2 float3 float4
          double1 double2 double3 double4

          bool1x1 bool1x2 bool1x3 bool1x4 bool2x1 bool2x2 bool2x3 bool2x4
          bool3x1 bool3x2 bool3x3 bool3x4 bool4x1 bool4x2 bool4x3 bool4x4
          BOOL1x1 BOOL1x2 BOOL1x3 BOOL1x4 BOOL2x1 BOOL2x2 BOOL2x3 BOOL2x4
          BOOL3x1 BOOL3x2 BOOL3x3 BOOL3x4 BOOL4x1 BOOL4x2 BOOL4x3 BOOL4x4
          half1x1 half1x2 half1x3 half1x4 half2x1 half2x2 half2x3 half2x4
          half3x1 half3x2 half3x3 half3x4 half4x1 half4x2 half4x3 half4x4
          int1x1 int1x2 int1x3 int1x4 int2x1 int2x2 int2x3 int2x4
          int3x1 int3x2 int3x3 int3x4 int4x1 int4x2 int4x3 int4x4
          float1x1 float1x2 float1x3 float1x4 float2x1 float2x2 float2x3 float2x4
          float3x1 float3x2 float3x3 float3x4 float4x1 float4x2 float4x3 float4x4
          double1x1 double1x2 double1x3 double1x4 double2x1 double2x2 double2x3 double2x4
          double3x1 double3x2 double3x3 double3x4 double4x1 double4x2 double4x3 double4x4
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          auto catch char const_cast delete dynamic_cast enum explicit friend
          goto long mutable new operator private protected public
          reinterpret_cast short signed sizeof static_cast template this throw
          try typename union unsigned using virtual
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          abort abs acos all AllMemoryBarrier AllMemoryBarrierWithGroupSync any
          AppendStructuredBuffer asdouble asfloat asin asint asuint asuint atan
          atan2 ceil CheckAccessFullyMapped clamp clip CompileShader
          ConsumeStructuredBuffer cos cosh countbits cross D3DCOLORtoUBYTE4 ddx
          ddx_coarse ddx_fine ddy ddy_coarse ddy_fine degrees determinant
          DeviceMemoryBarrier DeviceMemoryBarrierWithGroupSync distance dot dst
          errorf EvaluateAttributeAtCentroid EvaluateAttributeAtSample
          EvaluateAttributeSnapped exp exp2 f16tof32 f32tof16 faceforward
          firstbithigh firstbitlow floor fma fmod frac frexp fwidth
          GetRenderTargetSampleCount GetRenderTargetSamplePosition
          GlobalOrderedCountIncrement GroupMemoryBarrier
          GroupMemoryBarrierWithGroupSync InterlockedAdd InterlockedAnd
          InterlockedCompareExchange InterlockedCompareStore InterlockedExchange
          InterlockedMax InterlockedMin InterlockedOr InterlockedXor isfinite
          isinf isnan ldexp length lerp lit log log10 log2 mad max min modf
          msad4 mul noise normalize pow printf Process2DQuadTessFactorsAvg
          Process2DQuadTessFactorsMax Process2DQuadTessFactorsMin
          ProcessIsolineTessFactors ProcessQuadTessFactorsAvg
          ProcessQuadTessFactorsMax ProcessQuadTessFactorsMin
          ProcessTriTessFactorsAvg ProcessTriTessFactorsMax
          ProcessTriTessFactorsMin QuadReadLaneAt QuadSwapX QuadSwapY radians
          rcp reflect refract reversebits round rsqrt saturate sign sin sincos
          sinh smoothstep sqrt step tan tanh tex1D tex1D tex1Dbias tex1Dgrad
          tex1Dlod tex1Dproj tex2D tex2D tex2Dbias tex2Dgrad tex2Dlod tex2Dproj
          tex3D tex3D tex3Dbias tex3Dgrad tex3Dlod tex3Dproj texCUBE texCUBE
          texCUBEbias texCUBEgrad texCUBElod texCUBEproj transpose trunc
          WaveAllBitAnd WaveAllMax WaveAllMin WaveAllBitOr WaveAllBitXor
          WaveAllEqual WaveAllProduct WaveAllSum WaveAllTrue WaveAnyTrue
          WaveBallot WaveGetLaneCount WaveGetLaneIndex WaveGetOrderedIndex
          WaveIsHelperLane WaveOnce WavePrefixProduct WavePrefixSum
          WaveReadFirstLane WaveReadLaneAt

          SV_CLIPDISTANCE SV_CLIPDISTANCE0 SV_CLIPDISTANCE1 SV_CULLDISTANCE
          SV_CULLDISTANCE0 SV_CULLDISTANCE1 SV_COVERAGE SV_DEPTH
          SV_DEPTHGREATEREQUAL SV_DEPTHLESSEQUAL SV_DISPATCHTHREADID
          SV_DOMAINLOCATION SV_GROUPID SV_GROUPINDEX SV_GROUPTHREADID
          SV_GSINSTANCEID SV_INNERCOVERAGE SV_INSIDETESSFACTOR SV_INSTANCEID
          SV_ISFRONTFACE SV_OUTPUTCONTROLPOINTID SV_POSITION SV_PRIMITIVEID
          SV_RENDERTARGETARRAYINDEX SV_SAMPLEINDEX SV_STENCILREF SV_TESSFACTOR
          SV_VERTEXID SV_VIEWPORTARRAYINDEX

          allow_uav_condition branch call domain earlydepthstencil fastopt
          flatten forcecase instance loop maxtessfactor numthreads
          outputcontrolpoints outputtopology partitioning patchconstantfunc
          unroll

          BINORMAL BINORMAL0 BINORMAL1 BINORMAL2 BINORMAL3 BINORMAL4
          BLENDINDICES0 BLENDINDICES1 BLENDINDICES2 BLENDINDICES3 BLENDINDICES4
          BLENDWEIGHT0 BLENDWEIGHT1 BLENDWEIGHT2 BLENDWEIGHT3 BLENDWEIGHT4 COLOR
          COLOR0 COLOR1 COLOR2 COLOR3 COLOR4 NORMAL NORMAL0 NORMAL1 NORMAL2
          NORMAL3 NORMAL4 POSITION POSITION0 POSITION1 POSITION2 POSITION3
          POSITION4 POSITIONT PSIZE0 PSIZE1 PSIZE2 PSIZE3 PSIZE4 TANGENT
          TANGENT0 TANGENT1 TANGENT2 TANGENT3 TANGENT4 TESSFACTOR0 TESSFACTOR1
          TESSFACTOR2 TESSFACTOR3 TESSFACTOR4 TEXCOORD0 TEXCOORD1 TEXCOORD2
          TEXCOORD3 TEXCOORD4

          FOG PSIZE

          VFACE VPOS

          DEPTH0 DEPTH1 DEPTH2 DEPTH3 DEPTH4
        )
      end

      ws = %r((?:\s|//.*?\n|/[*].*?[*]/)+)
      id = /[a-zA-Z_][a-zA-Z0-9_]*/

      state :root do
        mixin :expr_whitespace
        rule %r(
          ([\w*\s]+?[\s*])                  # return arguments
          (#{id})                           # function name
          (\s*\([^;]*?\)(?:\s*:\s+#{id})?)  # signature
          (#{ws}?)({|;)                     # open brace or semicolon
        )mx do |m|
          # This is copied from the C lexer
          recurse m[1]
          token Name::Function, m[2]
          recurse m[3]
          recurse m[4]
          token Punctuation, m[5]
          if m[5] == ?{
            push :function
          end
        end
        rule %r/\{/, Punctuation, :function
        mixin :statements
      end
    end
  end
end
