; ModuleID = '0x102__Test3'
source_filename = "<unknown>"
target datalayout = "e-m:e-p:64:64-i64:64-n32:64-S128"
target triple = "sbf-solana-solana"

declare i32 @memcmp(ptr, ptr, i64)

define private void @"0000000000000102_Test3_main_DRHWKoxhcGBAC1"() {
entry:
  %local_0 = alloca i8, align 1
  %local_1 = alloca i8, align 1
  %local_2 = alloca i8, align 1
  store i8 1, ptr %local_0, align 1
  store i8 2, ptr %local_1, align 1
  %call_arg_0 = load i8, ptr %local_0, align 1
  %call_arg_1 = load i8, ptr %local_1, align 1
  %retval = call i8 @"0000000000000100_Test1_test1_FSLrpZ9dBeTRcs"(i8 %call_arg_0, i8 %call_arg_1)
  store i8 %retval, ptr %local_2, align 1
  ret void
}

declare i8 @"0000000000000100_Test1_test1_FSLrpZ9dBeTRcs"(i8, i8)
