#!/bin/bash
set -e
CERTDIR="$(dirname "$0")/certs"
mkdir -p "$CERTDIR"

# CA
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout "$CERTDIR/snakeoil-ca.key" \
  -out "$CERTDIR/snakeoil-ca.crt" \
  -subj "/C=DE/ST=Snake/O=SnakeOil CA/CN=SnakeOil CA"

# Server
openssl req -nodes -newkey rsa:2048 \
  -keyout "$CERTDIR/snakeoil-server.key" \
  -out "$CERTDIR/snakeoil-server.csr" \
  -subj "/C=DE/ST=Snake/O=SnakeOil/CN=localhost" \
  -addext "subjectAltName=DNS:localhost"
openssl x509 -req -days 3650 \
  -in "$CERTDIR/snakeoil-server.csr" \
  -CA "$CERTDIR/snakeoil-ca.crt" \
  -CAkey "$CERTDIR/snakeoil-ca.key" \
  -CAcreateserial \
  -out "$CERTDIR/snakeoil-server.crt" \
  -extfile <(printf "subjectAltName=DNS:localhost")

# Clean up
rm "$CERTDIR/snakeoil-server.csr"
