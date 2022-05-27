#!/usr/bin/ic-repl -r ic
identity default "./id1.pem";

import matrix = "rrkah-fqaaa-aaaaa-aaaaq-cai";
let member1 = "ndb4h-h6tuq-2iudh-j3opo-trbbe-vljdk-7bxgi-t5eyp-744ga-6eqv6-2ae";
let member2 = "rrkah-fqaaa-aaaaa-aaaaq-cai";
let member3 = "2vxsx-fae";

call matrix.create_manager(vec {member1; member2; member3}, 3);