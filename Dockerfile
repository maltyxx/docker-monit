FROM docker:stable

LABEL maintainer="Yoann VANITOU <yvanitou@gmail.com>"

ARG MONIT_VERSION=5.26.0

RUN set -x \
    && apk add --no-cache --virtual mybuild \
        build-base \
    && apk add --no-cache \
        openssl-dev \
        lm-sensors \
        libltdl \
        zlib-dev \
        ca-certificates \
        tzdata \
        findmnt \
    && cd /tmp \
    && wget "https://mmonit.com/monit/dist/monit-$MONIT_VERSION.tar.gz" \
    && tar -zxvf "monit-$MONIT_VERSION.tar.gz" \
    && cd "monit-$MONIT_VERSION" \
    && ./configure --sysconfdir /etc/monit \
        --without-pam \
    && make -j$(nproc) \
    && make install \
    && cd \
    && rm -rf /tmp/* \
    && apk del mybuild \
    && mkdir -p /etc/monit /docker-entrypoint.d

COPY --chown=0:0 root/monit /etc/monit
COPY --chown=0:0 root/docker-entrypoint.sh /docker-entrypoint.sh

EXPOSE 2812

HEALTHCHECK --start-period=300s --interval=30s --timeout=30s --retries=3 CMD monit status || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]

CMD ["/usr/local/bin/monit", "-I"]
