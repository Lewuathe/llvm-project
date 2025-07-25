; RUN: llc -mtriple=amdgcn -mcpu=verde < %s | FileCheck %s
; RUN: llc -mtriple=amdgcn -mcpu=tonga < %s | FileCheck %s

; This is used to crash in LiveIntervalAnalysis via SILoadStoreOptimizer
; while fixing up the merge of two ds_write instructions.

@tess_lds = external addrspace(3) global [8192 x i32]

; CHECK-LABEL: {{^}}main:
; CHECK-DAG: ds_write_b32
; CHECK-DAG: ds_write_b32
; CHECK-DAG: v_mov_b32_e32 v1, v0
; CHECK: tbuffer_store_format_xyzw v[0:3],
define amdgpu_vs void @main(i32 inreg %arg) {
main_body:
  %tmp = load float, ptr addrspace(3) poison, align 4
  %tmp1 = load float, ptr addrspace(3) poison, align 4
  store float %tmp, ptr addrspace(3) null, align 4
  %tmp2 = bitcast float %tmp to i32
  %tmp3 = add nuw nsw i32 0, 1
  %tmp4 = zext i32 %tmp3 to i64
  %tmp5 = getelementptr [8192 x i32], ptr addrspace(3) @tess_lds, i64 0, i64 %tmp4
  store float %tmp1, ptr addrspace(3) %tmp5, align 4
  %tmp7 = bitcast float %tmp1 to i32
  %tmp8 = insertelement <4 x i32> poison, i32 %tmp2, i32 0
  %tmp9 = insertelement <4 x i32> %tmp8, i32 %tmp7, i32 1
  %tmp10 = insertelement <4 x i32> %tmp9, i32 poison, i32 2
  %tmp11 = insertelement <4 x i32> %tmp10, i32 poison, i32 3
  call void @llvm.amdgcn.struct.ptr.tbuffer.store.v4i32(<4 x i32> %tmp11, ptr addrspace(8) poison, i32 0, i32 0, i32 %arg, i32 78, i32 3) #2
  ret void
}

declare void @llvm.amdgcn.struct.ptr.tbuffer.store.v4i32(<4 x i32>, ptr addrspace(8), i32, i32, i32, i32 immarg, i32 immarg) #0

attributes #0 = { nounwind willreturn writeonly }
