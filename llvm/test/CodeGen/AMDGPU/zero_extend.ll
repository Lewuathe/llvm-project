; RUN: llc -mtriple=amdgcn -mcpu=tahiti < %s | FileCheck -enable-var-scope --check-prefixes=GCN,SI %s
; RUN: llc -mtriple=amdgcn -mcpu=tonga -mattr=-flat-for-global < %s | FileCheck -enable-var-scope --check-prefixes=GCN,VI %s
; RUN: llc -mtriple=r600 -mcpu=redwood < %s | FileCheck -check-prefix=R600 %s

; R600: {{^}}s_mad_zext_i32_to_i64:
; R600: MEM_RAT_CACHELESS STORE_RAW
; R600: MEM_RAT_CACHELESS STORE_RAW

; GCN: {{^}}s_mad_zext_i32_to_i64:
; GCN: v_mov_b32_e32 v[[V_ZERO:[0-9]]], 0{{$}}
; GCN: buffer_store_dwordx2 v[0:[[V_ZERO]]]
define amdgpu_kernel void @s_mad_zext_i32_to_i64(ptr addrspace(1) %out, i32 %a, i32 %b, i32 %c) #0 {
entry:
  %tmp0 = mul i32 %a, %b
  %tmp1 = add i32 %tmp0, %c
  %tmp2 = zext i32 %tmp1 to i64
  store i64 %tmp2, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}s_cmp_zext_i1_to_i32
; GCN: v_cndmask_b32
define amdgpu_kernel void @s_cmp_zext_i1_to_i32(ptr addrspace(1) %out, i32 %a, i32 %b) #0 {
entry:
  %tmp0 = icmp eq i32 %a, %b
  %tmp1 = zext i1 %tmp0 to i32
  store i32 %tmp1, ptr addrspace(1) %out
  ret void
}

; GCN-LABEL: {{^}}s_arg_zext_i1_to_i64:
define amdgpu_kernel void @s_arg_zext_i1_to_i64(ptr addrspace(1) %out, i1 zeroext %arg) #0 {
  %ext = zext i1 %arg to i64
  store i64 %ext, ptr addrspace(1) %out, align 8
  ret void
}

; GCN-LABEL: {{^}}s_cmp_zext_i1_to_i64:
; GCN-DAG: s_mov_b32 s{{[0-9]+}}, 0
; GCN-DAG: s_cmp_eq_u32
; GCN:     v_cndmask_b32
define amdgpu_kernel void @s_cmp_zext_i1_to_i64(ptr addrspace(1) %out, i32 %a, i32 %b) #0 {
  %cmp = icmp eq i32 %a, %b
  %ext = zext i1 %cmp to i64
  store i64 %ext, ptr addrspace(1) %out, align 8
  ret void
}

; FIXME: Why different commute?
; GCN-LABEL: {{^}}s_cmp_zext_i1_to_i16
; GCN: s_load_dword [[A:s[0-9]+]]
; GCN: s_load_dword [[B:s[0-9]+]]

; GCN-DAG: s_and_b32 [[MASK_A:s[0-9]+]], [[A]], 0xffff{{$}}
; GCN-DAG: s_and_b32 [[MASK_B:s[0-9]+]], [[B]], 0xffff{{$}}
; VI: s_cmp_eq_u32 [[MASK_B]], [[MASK_A]]
; SI: s_cmp_eq_u32 [[MASK_A]], [[MASK_B]]
; GCN: s_cselect_b64 [[CC:s\[[0-9:]+\]]], -1, 0
; GCN: v_cndmask_b32_e64 [[RESULT:v[0-9]+]], 0, 1, [[CC]]
; GCN: buffer_store_short [[RESULT]]
define amdgpu_kernel void @s_cmp_zext_i1_to_i16(ptr addrspace(1) %out, [8 x i32], i16 zeroext %a, [8 x i32], i16 zeroext %b) #0 {
  %tmp0 = icmp eq i16 %a, %b
  %tmp1 = zext i1 %tmp0 to i16
  store i16 %tmp1, ptr addrspace(1) %out
  ret void
}

attributes #0 = { nounwind }
