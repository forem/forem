# -*- coding: utf-8 -*- #
# frozen_string_literal: true

module Rouge
  module Lexers
    load_lexer 'c.rb'

    # This file defines the GLSL language lexer to the Rouge
    # syntax highlighter.
    #
    # Author: Sri Harsha Chilakapati
    class Glsl < C
      tag 'glsl'
      filenames '*.glsl', '*.frag', '*.vert', '*.geom', '*.vs', '*.gs', '*.shader'
      mimetypes 'x-shader/x-vertex', 'x-shader/x-fragment', 'x-shader/x-geometry'

      title "GLSL"
      desc "The GLSL shader language"

      def self.keywords
        @keywords ||= Set.new %w(
          attribute const uniform varying
          layout
          centroid flat smooth noperspective
          patch sample
          break continue do for while switch case default
          if else
          subroutine
          in out inout
          invariant
          discard return struct precision
        )
      end

      def self.keywords_type
        @keywords_type ||= Set.new %w(
          float double int void bool true false
          lowp mediump highp
          mat2 mat3 mat4 dmat2 dmat3 dmat4
          mat2x2 mat2x3 mat2x4 dmat2x2 dmat2x3 dmat2x4
          mat3x2 mat3x3 mat3x4 dmat3x2 dmat3x3 dmat3x4
          mat4x2 mat4x3 mat4x4 dmat4x2 dmat4x3 dmat4x4
          vec2 vec3 vec4 ivec2 ivec3 ivec4 bvec2 bvec3 bvec4 dvec2 dvec3 dvec4
          uint uvec2 uvec3 uvec4
          sampler1D sampler2D sampler3D samplerCube
          sampler1DShadow sampler2DShadow samplerCubeShadow
          sampler1DArray sampler2DArray
          sampler1DArrayShadow sampler2DArrayShadow
          isampler1D isampler2D isampler3D isamplerCube
          isampler1DArray isampler2DArray
          usampler1D usampler2D usampler3D usamplerCube
          usampler1DArray usampler2DArray
          sampler2DRect sampler2DRectShadow isampler2DRect usampler2DRect
          samplerBuffer isamplerBuffer usamplerBuffer
          sampler2DMS isampler2DMS usampler2DMS
          sampler2DMSArray isampler2DMSArray usampler2DMSArray
          samplerCubeArray samplerCubeArrayShadow isamplerCubeArray usamplerCubeArray
        )
      end

      def self.reserved
        @reserved ||= Set.new %w(
          common partition active
          asm
          class union enum typedef template this packed
          goto
          inline noinline volatile public static extern external interface
          long short half fixed unsigned superp
          input output
          hvec2 hvec3 hvec4 fvec2 fvec3 fvec4
          sampler3DRect
          filter
          image1D image2D image3D imageCube
          iimage1D iimage2D iimage3D iimageCube
          uimage1D uimage2D uimage3D uimageCube
          image1DArray image2DArray
          iimage1DArray iimage2DArray uimage1DArray uimage2DArray
          image1DShadow image2DShadow
          image1DArrayShadow image2DArrayShadow
          imageBuffer iimageBuffer uimageBuffer
          sizeof cast
          namespace using
          row_major
        )
      end

      def self.builtins
        @builtins ||= Set.new %w(
          gl_VertexID gl_InstanceID gl_PerVertex gl_Position gl_PointSize gl_ClipDistance
          gl_PrimitiveIDIn gl_InvocationID gl_PrimitiveID gl_Layer gl_ViewportIndex
          gl_MaxPatchVertices gl_PatchVerticesIn gl_TessLevelOuter gl_TessLevelInner
          gl_TessCoord gl_FragCoord gl_FrontFacing gl_PointCoord gl_SampleID gl_SamplePosition
          gl_FragColor gl_FragData gl_MaxDrawBuffers gl_FragDepth gl_SampleMask
          gl_ClipVertex gl_FrontColor gl_BackColor gl_FrontSecondaryColor gl_BackSecondaryColor
          gl_TexCoord gl_FogFragCoord gl_Color gl_SecondaryColor gl_Normal gl_VertexID
          gl_MultiTexCord0 gl_MultiTexCord1 gl_MultiTexCord2 gl_MultiTexCord3
          gl_MultiTexCord4 gl_MultiTexCord5 gl_MultiTexCord6 gl_MultiTexCord7
          gl_FogCoord gl_MaxVertexAttribs gl_MaxVertexUniformComponents
          gl_MaxVaryingFloats gl_MaxVaryingComponents gl_MaxVertexOutputComponents
          gl_MaxGeometryInputComponents gl_MaxGeometryOutputComponents
          gl_MaxFragmentInputComponents gl_MaxVertexTextureImageUnits
          gl_MaxCombinedTextureImageUnits gl_MaxTextureImageUnits
          gl_MaxFragmentUniformComponents gl_MaxClipDistances
          gl_MaxGeometryTextureImageUnits gl_MaxGeometryUniformComponents
          gl_MaxGeometryVaryingComponents gl_MaxTessControlInputComponents
          gl_MaxTessControlOutputComponents gl_MaxTessControlTextureImageUnits
          gl_MaxTessControlUniformComponents gl_MaxTessControlTotalOutputComponents
          gl_MaxTessEvaluationInputComponents gl_MaxTessEvaluationOutputComponents
          gl_MaxTessEvaluationTextureImageUnits gl_MaxTessEvaluationUniformComponents
          gl_MaxTessPatchComponents gl_MaxTessGenLevel gl_MaxViewports
          gl_MaxVertexUniformVectors gl_MaxFragmentUniformVectors gl_MaxVaryingVectors
          gl_MaxTextureUnits gl_MaxTextureCoords gl_MaxClipPlanes gl_DepthRange
          gl_DepthRangeParameters gl_ModelViewMatrix gl_ProjectionMatrix
          gl_ModelViewProjectionMatrix gl_TextureMatrix gl_NormalMatrix
          gl_ModelViewMatrixInverse gl_ProjectionMatrixInverse gl_ModelViewProjectionMatrixInverse
          gl_TextureMatrixInverse gl_ModelViewMatrixTranspose
          gl_ModelViewProjectionMatrixTranspose gl_TextureMatrixTranspose
          gl_ModelViewMatrixInverseTranspose gl_ProjectionMatrixInverseTranspose
          gl_ModelViewProjectionMatrixInverseTranspose
          gl_TextureMatrixInverseTranspose gl_NormalScale gl_ClipPlane gl_PointParameters
          gl_Point gl_MaterialParameters gl_FrontMaterial gl_BackMaterial
          gl_LightSourceParameters gl_LightSource gl_MaxLights gl_LightModelParameters
          gl_LightModel gl_LightModelProducts gl_FrontLightModelProduct
          gl_BackLightModelProduct gl_LightProducts gl_FrontLightProduct
          gl_BackLightProduct gl_TextureEnvColor gl_EyePlaneS gl_EyePlaneT gl_EyePlaneR
          gl_EyePlaneQ gl_ObjectPlaneS gl_ObjectPlaneT gl_ObjectPlaneR gl_ObjectPlaneQ
          gl_FogParameters gl_Fog
        )
      end
    end
  end
end
