module 0x1::dynamic_structure {
    struct Inner<K, V> has copy, drop, store {
        key: K,
        val: V,
    }

    struct DynamicStruct<S: drop> has copy, drop, store {
        id: u64,
        s: S,
    }

    public fun dynamic_struct<K: drop, V: drop>(id: u64, key: K, val: V) {
        DynamicStruct {
            id,
            s: Inner { key, val },
        };
    }
    public fun test_fail() {
        // If code is open then `dynamic_struct` is instantiated explicitly and
        // `dynamic_struct` call below will not fail.
        // DynamicStruct {
        //     id: 44,
        //     s: Inner { key: 1, val: 2 },
        // };

        // this was failing before commit `061824-fixing-dynamic-fields`
        dynamic_struct(44, 1, 2);
    }
}
