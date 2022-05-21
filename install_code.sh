#!/usr/bin/ic-repl -r ic

import can_manager = "rrkah-fqaaa-aaaaa-aaaaq-cai";
let hello_can = "r7inp-6aaaa-aaaaa-aaabq-cai";
call can_manager.install_code(file "./hello.wasm", hello_can, variant {install});
