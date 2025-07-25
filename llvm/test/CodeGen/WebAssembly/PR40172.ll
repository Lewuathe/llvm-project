; RUN: llc < %s -O0 -wasm-disable-explicit-locals -wasm-keep-registers | FileCheck %s

; Regression test for bug 40172. The problem was that FastISel assumed
; that CmpInst results did not need to be zero extended because
; WebAssembly's compare instructions always return 0 or 1. But in this
; test case FastISel falls back to DAG ISel, which combines away the
; comparison, invalidating FastISel's assumption.

target triple = "wasm32-unknown-unknown"

; CHECK:  i32.sub $[[BASE:[0-9]+]]=,
; CHECK:  local.copy $[[ARG:[0-9]+]]=, $0{{$}}
; CHECK:  i32.const $push[[A0:[0-9]+]]=, 1{{$}}
; CHECK:  i32.and $push[[A1:[0-9]+]]=, $[[ARG]], $pop[[A0]]{{$}}
; CHECK:  i32.store8 8($[[BASE]]), $pop[[A1]]{{$}}

define void @test(i8 %byte) {
  %t = alloca { i8, i8 }, align 8
  %x4 = and i8 %byte, 1
  %x5 = icmp eq i8 %x4, 1
  %x6 = and i8 %byte, 2
  %x7 = icmp eq i8 %x6, 2
  %x9 = zext i1 %x5 to i8
  store i8 %x9, ptr %t, align 1
  %x10 = getelementptr inbounds { i8, i8 }, ptr %t, i32 0, i32 1
  %x11 = zext i1 %x7 to i8
  store i8 %x11, ptr %x10, align 1
  ret void
}
