#!/bin/bash

wg genkey |
    xargs -I{} sh -c '
        echo {} && echo {} | wg pubkey && wg genpsk
    ' | tr '\n' , |
    awk -F"," '{
        print "          wireguard_private_key: \""$1"\"";
        print "          wireguard_public_key: \""$2"\"";
        print "          wireguard_psk_seed: \""$3"\"";
    }'
