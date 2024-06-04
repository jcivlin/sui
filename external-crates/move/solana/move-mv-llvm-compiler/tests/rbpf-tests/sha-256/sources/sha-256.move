// input ../input.json
// use-stdlib
// log 0000000000000000000000000000000000000000000000000000000000000001::string::String { bytes: [72, 101, 108, 108, 111, 32, 100, 114, 97, 110, 100], }
// log [72, 101, 108, 108, 111]
// log [24, 95, 141, 179, 34, 113, 254, 37, 245, 97, 166, 252, 147, 139, 46, 38, 67, 6, 236, 48, 78, 218, 81, 128, 7, 209, 118, 72, 38, 56, 25, 105]
// log 37


module 0x10::debug {
  native public fun print<T>(x: &T);
}

module sha_256::hello {
    use 0x10::debug;
    use 0x1::string;
    use std::vector;
    use std::hash::sha2_256;

    /// Error codes
    const EInvalidRndLength: u64 = 0;


    public fun create_u8_vector(): vector<u8> {
        let v = vector::empty<u8>();
        vector::push_back(&mut v, 72); // H
        vector::push_back(&mut v, 101); // e
        vector::push_back(&mut v, 108); // l
        vector::push_back(&mut v, 108); // l
        vector::push_back(&mut v, 111); // o
        v
    }

    public fun print_vector_u8(vec: &vector<u8>) {
        let vec_u8 = vector::empty<u8>();
        let len = vector::length<u8>(vec);

        let i = 0;
        while (i < len) {
            let byte = vector::borrow<u8>(vec, i);
            vector::push_back<u8>(&mut vec_u8, *byte);
            i = i + 1;
        };

        debug::print(&vec_u8);
    }

    // Converts the first 8 bytes of rnd to a u64 number and outputs its modulo with input n.
    // Since n is u64, the output is at most 2^{-64} biased assuming rnd is uniformly random.
    public fun safe_selection(n: u64, rnd: &vector<u8>): u64 {
        assert!(vector::length(rnd) >= 8, EInvalidRndLength);
        let m: u64 = 0;
        let i = 0;
        while (i < 8) {
            m = m << 8;
            let curr_byte = *vector::borrow(rnd, i);
            m = m + (curr_byte as u64);
            i = i + 1;
        };
        let n_64 = (n as u64);
        let module_64  = m % n_64;
        let res = (module_64 as u64);
        res
    }


    public entry fun main() : u64 {
        let s = string::utf8(b"Hello drand");
        debug::print(&s);

        let v = create_u8_vector();
        print_vector_u8(&v);

        let rand = std::hash::sha2_256(v);
        print_vector_u8(&rand);

        let rand_u64 = safe_selection(64, &rand);
        debug::print(&rand_u64);

        rand_u64
    }
}
