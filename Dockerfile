
#name image: #hsmstt2

FROM alpine:3.14
ARG LIBP11_VERSION=0.4.11
ARG SOFTHSM2_VERSION=2.6.1
ARG OPENSC_VERSION=0.21.0

ENV SOFTHSM2_VERSION=${SOFTHSM2_VERSION} \
    SOFTHSM2_SOURCES=/softhsm2

# install build dependencies
RUN apk add --no-cache \
        ccid \
        # openssl \
        pcsc-lite \
        pcsc-lite-dev \
    && apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        build-base \
        curl \
        gettext \
        openssl-dev \
        libtool \
        m4 \
        git \
        readline-dev \
        zlib-dev \
        linux-headers 



RUN curl -fsL 
https://github.com/OpenSC/OpenSC/releases/download/${OPENSC_VERSION}/opensc-${OPENSC_VERSION}.tar.gz  
-o opensc-${OPENSC_VERSION}.tar.gz \
    && tar -zxf opensc-${OPENSC_VERSION}.tar.gz \
    && rm opensc-${OPENSC_VERSION}.tar.gz \
    && cd opensc-${OPENSC_VERSION} \
    && ./bootstrap \
    && ./configure \
        --host=x86_64-alpine-linux-musl \
        --prefix=/usr \
        --sysconfdir=/etc \
        --disable-man \
        --enable-zlib \
        --enable-readline \
        --enable-openssl \
        --enable-pcsc \
        --enable-sm \
        CC='gcc' \
    && make \
    && make install \
    && curl -fsL 
https://github.com/OpenSC/libp11/releases/download/libp11-${LIBP11_VERSION}/libp11-${LIBP11_VERSION}.tar.gz 
-o libp11-${LIBP11_VERSION}.tar.gz \
    && tar -zxf libp11-${LIBP11_VERSION}.tar.gz \
    # && rm libp11-${LIBP11_VERSION}.tar.gz \
    && cd libp11-${LIBP11_VERSION} \
    && ./configure \
    && make \
    && make install \
    && apk del .build-deps \
    # && rm -r /usr/src/build \
    && addgroup -g 1000 opensc \
    && adduser -u 1000 -G opensc -s /bin/sh -D opensc \
    && mkdir -p /run/pcscd \
    && chown -R nobody:nobody /run/pcscd
# build and install SoftHSM2

RUN apk add --no-cache git autoconf automake libtool  pkgconfig linux-headers 
pcre2-dev  build-base openssl-dev

RUN cp /opensc-0.21.0/src/common/.libs/libpkcs11.a /usr/local/lib/

RUN git clone https://github.com/openssl/openssl &&\
    cd openssl &&   \
    git checkout openssl-3.0 && \
    LDFLAGS="-static -L/usr/local/lib -lpkcs11" ./config no-shared --static 
--prefix=/usr/local/openssl --openssldir=/usr/local/openssl&& \
    #OpenSSL_1_1_1-stable && \  
    # LDFLAGS="-static"  ./config --static && \ 
    make && make install  \
    &&export PATH=/usr/local/openssl/bin:$PATH
   
RUN git clone https://github.com/opendnssec/SoftHSMv2.git ${SOFTHSM2_SOURCES}
WORKDIR ${SOFTHSM2_SOURCES}

RUN git checkout ${SOFTHSM2_VERSION} -b ${SOFTHSM2_VERSION} 
# \
#     && sh autogen.sh \
#     && ./configure \
# LDFLAGS="-static -L/usr/local/openssl/lib" CFLAGS="-I/usr/local/openssl/include" 
./configure --disable-shared --with-openssl=/usr/local/openssl
# LDFLAGS="-static -L/usr/local/openssl/lib64" CFLAGS="-I/usr/local/openssl/include" 
./configure --disable-shared --with-openssl=/usr/local/openssl/include && \
#     && make \
#     && make install

WORKDIR /root
# RUN rm -fr ${SOFTHSM2_SOURCES}

# install pkcs11-tool
RUN apk --update add opensc
COPY ./alpine/hsmpkiAlpine.sh hsmpki.sh
COPY ./alpine/opensslAlpine11.cnf /usr/local/ssl/openssl.cnf
COPY ./alpine/opensslAlpine11.cnf /etc/ssl/openssl.cnf
COPY autocacert.cnf autocacert.cnf
COPY autoisscert.cnf autoisscert.cnf
COPY req.cnf req.cnf
RUN apk add --no-cache opensc
# COPY /engines-3/  /usr/lib/engines-3/
