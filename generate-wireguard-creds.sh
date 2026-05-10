#!/bin/bash

wg genkey |
    xargs -I{} sh -c '
        echo {} && echo {} | wg pubkey && wg genpsk
    ' | tr '\n' , |
    awk -F"," '{
        print "            private_key: \""$1"\"";
        print "            public_key: \""$2"\"";
        print "            psk_seed: \""$3"\"";
    }'
