// compile as move-mv-llvm-compiler -c CollectionExample.move --stdlib  -S
module 0x10::debug {
    native public fun print<T>(x: &T);
}

module 0x2::Book {
    // Define a structure for a Book
    struct Book has copy, drop, store {
        isbn: u64,
        title: vector<u8>,
        author: vector<u8>,
    }

    public fun create_book(isbn: u64, title: vector<u8>, author: vector<u8>): Book {
        Book { isbn, title, author }
    }

    public fun isbn(book: &Book): &u64 {
        &book.isbn
    }
    public fun title(book: &Book): &vector<u8> {
        &book.title
    }
    public fun author(book: &Book): &vector<u8> {
        &book.author
    }
}

module 0x1::CollectionExample {
    use std::vector;
    use 0x10::debug;
    use 0x2::Book as Book;

    // Define a generic struct that holds a vector of T
    struct Collection<T> has copy, drop, store {
        items: vector<T>,
    }

    // Function to create a new Collection
    public fun new_collection<T>(): Collection<T> {
        Collection { items: vector::empty() }
    }

    // Function to add an item to the Collection
    public fun add_item<T>(collection: &mut Collection<T>, item: T) {
        vector::push_back(&mut collection.items, item);
    }

    // Function to print the Collection's items
    public fun print_collection<T>(collection: &Collection<T>) {
        let length = vector::length(&collection.items);
        debug::print(&length);

        let i = 0;
        while (i < length) {
            let item = vector::borrow(&collection.items, i);
            debug::print(item); // Assuming T is printable
            i = i + 1;
        }
    }

    // Entry function to demonstrate usage
    public entry fun demonstrate() {
        let int_collection = new_collection<u64>();
        add_item(&mut int_collection, 1);
        add_item(&mut int_collection, 2);
        add_item(&mut int_collection, 3);

        print_collection(&int_collection);

        let string_collection = new_collection<vector<u8>>();
        let hello_bytes: vector<u8> = vector[72, 101, 108, 108, 111];
        let world_bytes: vector<u8> = vector[87, 111, 114, 108, 100];
        add_item(&mut string_collection, hello_bytes);
        add_item(&mut string_collection, world_bytes);

        print_collection(&string_collection);

        let library = new_collection<Book::Book>();
        let title1: vector<u8> = vector[ // "Move Programming"
            77, 111, 118, 101, 32, 80, 114, 111, 103, 114, 97, 109, 109, 105, 110, 103
        ];
        let author1: vector<u8> = vector[ // "Alice"
            65, 108, 105, 99, 101
        ];
        let book1 = Book::create_book(9781234567890, title1, author1);
        add_item(&mut library, book1);

        let title2: vector<u8> = vector[ // "Blockchain Basics"
            66, 108, 111, 99, 107, 99, 104, 97, 105, 110, 32, 66, 97, 115, 105, 99, 115
        ];
        let author2: vector<u8> = vector[ // "Bob"
            66, 111, 98
        ];
        let book2 = Book::create_book(9780987654321, title2, author2);
        add_item(&mut library, book2);

        print_collection(&library);
    }
}
