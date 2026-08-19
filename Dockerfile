ARG AIOSTREAMS_BASE_IMAGE=ghcr.io/viren070/aiostreams:latest
FROM ${AIOSTREAMS_BASE_IMAGE}

COPY docker/patch-request-limit.cjs /tmp/patch-request-limit.cjs
RUN /nodejs/bin/node /tmp/patch-request-limit.cjs
