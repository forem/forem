# -*- coding: utf-8 -*- #

module Rouge
  module Lexers
    load_lexer 'cpp.rb'

    class CUDA < Cpp
      title "CUDA"
      desc "Compute Unified Device Architecture, used for programming with NVIDIA GPU"

      tag 'cuda'
      filenames '*.cu', '*.cuh'

      def self.keywords
        @keywords ||= super + Set.new(%w(
          __global__ __device__ __host__ __noinline__ __forceinline__
          __constant__ __shared__ __managed__ __restrict__
        ))
      end

      def self.keywords_type
        @keywords_type ||= super + Set.new(%w(
          char1 char2 char3 char4 uchar1 uchar2 uchar3 uchar4
          short1 short2 short3 short4 ushort1 ushort2 ushort3 ushort4
          int1 int2 int3 int4 uint1 uint2 uint3 uint4
          long1 long2 long3 long4 ulong1 ulong2 ulong3 ulong4
          longlong1 longlong2 longlong3 longlong4 
          ulonglong1 ulonglong2 ulonglong3 ulonglong4 
          float1 float2 float3 float4 double1 double2 double3 double4
          dim3
        ))
      end
    end
  end
end
