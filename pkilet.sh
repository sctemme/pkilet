#! /bin/sh -x

usage() {
 echo "usage: $0 -newroot" >&2
}

if [ -z "$OPENSSL" ]; then OPENSSL=openssl; fi
if [ -z "$SSLEAY_CONFIG" ]; then SSLEAY_CONFIG="-config ./pkilet.cnf" ; fi

if [ -z "$DAYS" ] ; then DAYS="-days 365" ; fi	# 1 year
CADAYS="-days 1095"	# 3 years
REQ="$OPENSSL req $SSLEAY_CONFIG"
CA="$OPENSSL ca -verbose $SSLEAY_CONFIG"
VERIFY="$OPENSSL verify"
X509="$OPENSSL x509"
PKCS12="openssl pkcs12"

CAKEY=./cakey.pem
CAREQ=./careq.pem
CACERT=./cacert.pem

# newca() {
# }

RET=0

while [ "$1" != "" ] ; do
case $1 in
-\?|-h|-help)
    usage
    exit 0
    ;;
-newroot)
    caname=rootCA
    # Blow away the old one, no niceties.
    if [ -d "$caname" ] ; then rm -rf $caname ; fi
    # create the directory hierarchy
	mkdir -p ${caname}
	mkdir -p ${caname}/certs
	mkdir -p ${caname}/crl
	mkdir -p ${caname}/newcerts
	mkdir -p ${caname}/private
	touch ${caname}/index.txt

    echo "Making CA certificate ..."
    $REQ -new -keyout ${caname}/private/$CAKEY -nodes\
           -out ${caname}/$CAREQ -subj "/C=US/ST=Colorado/O=Apache Software Foundation/CN=PKI-Let Root CA" -verbose
    $CA -create_serial -out ${caname}/$CACERT $CADAYS -batch \
           -keyfile ${caname}/private/$CAKEY -selfsign \
           -extensions v3_ca -name ${caname} \
           -infiles ${caname}/$CAREQ 
    RET=$?
    ;;
*)
    echo "Unknown arg $i" >&2
    usage
    exit 1
    ;;
esac
shift
done
exit $RET
