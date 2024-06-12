// compile as move-mv-llvm-compiler -c CollectionExample.move --stdlib -S
module 0x10::debug {
    native public fun print<T>(x: &T);
}

module 0x4::InnerStruct {
    use 0x10::debug;

    struct Inner<K, V> has copy, drop, store {
        key: K,
        val: V,
    }
    // get the key from Inner
    public fun get_inner_key<K, V>(inner: &Inner<K, V>): &K {
        &inner.key
    }
    public fun print_key<K, V>(inner: &Inner<K, V>) {
        debug::print(&inner.key);
    }
    // get the value from Inner
    public fun get_inner_val<K, V>(inner: &Inner<K, V>): &V {
        &inner.val
    }
    // get the value from Inner
    public fun print_val<K, V>(inner: &Inner<K, V>) {
        debug::print(&inner.val);
    }
    // return the Inner struct
    public fun create_inner<K, V>(key: K, val: V): Inner<K, V> {
        Inner { key, val }
    }

    public fun print<K, V>(inner: &Inner<K, V>) {
        debug::print(&inner.key);
        debug::print(&inner.val);
    }
}

module 0x3::GenericStruct {
    // Generic struct that includes a generic object of parametrized type S
    struct GenericStruct<S: drop> has copy, drop, store {
        id: u64,
        s: S,
    }
    // Function to create a GenericStruct
    public fun create_generic_struct<S: drop>(id: u64, s: S): GenericStruct<S> {
        GenericStruct {
            id,
            s,
        }
    }
    public fun inner<S: drop>(gen: &GenericStruct<S>): &S {
        &gen.s
    }
}

module 0x1::GenericStructExample {
    use std::vector;
    use 0x10::debug;
    use 0x4::InnerStruct;
    use 0x3::GenericStruct;

    public entry fun test() {
        // Creating a struct inner with key = 0x1 and val = 0x64
        let inner = InnerStruct::create_inner<u8, u64>(0x1, 0x64);
        debug::print(InnerStruct::get_inner_key(&inner));
        debug::print(InnerStruct::get_inner_val(&inner));
        InnerStruct::print(&inner);

        // Create generic struct with internal object inner
        let generic_struct = GenericStruct::create_generic_struct<InnerStruct::Inner<u8, u64>>(42, inner);

        let inner_in_generic = GenericStruct::inner(&generic_struct);
        InnerStruct::print(inner_in_generic);
    }
}
