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

mkdirs() {
    topdir=$1
    # Blow away the old one, no niceties.
    if [ -d "$topdir" ] ; then rm -rf $topdir ; fi
    # create the directory hierarchy
	mkdir -p ${topdir}
	mkdir -p ${topdir}/certs
	mkdir -p ${topdir}/crl
	mkdir -p ${topdir}/newcerts
	mkdir -p ${topdir}/private
	touch ${topdir}/index.txt
}

RET=0

while [ "$1" != "" ] ; do
case $1 in
-\?|-h|-help)
    usage
    exit 0
    ;;
-newroot)
    caname=rootCA
    mkdirs ${caname}
    echo "Making Root CA certificate ..."
    $REQ -new -newkey rsa:4096 -keyout ${caname}/private/$CAKEY -nodes -out ${caname}/$CAREQ \
           -subj "/C=US/ST=Colorado/O=Apache Software Foundation/CN=PKI-Let Root CA"
    $CA -create_serial -out ${caname}/$CACERT $CADAYS -batch \
           -keyfile ${caname}/private/$CAKEY -selfsign \
           -extensions v3_ca -name ${caname} \
           -infiles ${caname}/$CAREQ 
    RET=$?
    ;;
-newissuing)
    caname=issuingCA
    mkdirs ${caname}
    echo "Making Issuing CA certificate ..."
    $REQ -new -newkey rsa:2048 -keyout ${caname}/private/$CAKEY -nodes -out ${caname}/$CAREQ \
         -subj "/C=US/ST=Colorado/O=ASF/OU=Apache HTTP Server/CN=PKI-Let Issuing CA"
    # Now sign it with the root CA
    $CA -name rootCA -policy policy_anything -out ${caname}/$CACERT -batch \
        -extensions v3_ca -infiles ${caname}/$CAREQ
    # Somehow from CA.sh it seems that the serial # for the new CA comes from its certificate
    # The -next_serial option used here seems undocumented
    $X509 -in ${caname}/$CACERT -noout -next_serial \
          -out ${caname}/serial
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
