//
module 0x101::Test1 {
  public fun test_neq_u8(a: u8, b: u8): bool {
    a != b
  }
}

module 0x10::Test {
  public fun test_main() {
    assert!(0x101::Test1::test_neq_u8(255u8, 254u8), 10);
    assert!(!0x101::Test1::test_neq_u8(255u8, 255u8), 10);
  }
}