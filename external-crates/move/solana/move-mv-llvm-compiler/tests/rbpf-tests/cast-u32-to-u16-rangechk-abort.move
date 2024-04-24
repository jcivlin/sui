// abort 4017

module 0x101::Test1 {
  public fun test_castu16(a: u32): u16 {
    (a as u16)
  }
}

module 0x10::Test {
  public fun test_main() {
    assert!(0x101::Test1::test_castu16(65535u32) == 65535, 10);  // Ok: source fits in dest.

    0x101::Test1::test_castu16(65536u32);  // Abort: source too big.
  }
}