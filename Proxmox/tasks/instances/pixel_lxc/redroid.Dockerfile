ARG BASE
FROM ${BASE} AS base

FROM busybox:1.37.0@sha256:bdf57e528e45e4433820e045b29b4597825a1c9e38353532d90a01445013f82e AS patch
COPY --from=base /vendor/lib64/hw/gralloc.gbm.so /gralloc.gbm.so
# bpp table stops at 0x2a, so RGBA_1010102 (Photos HDR) divides by zero and restarts Android; send it to the 4-byte branch
RUN echo "f06f7b2e6d84d3a8f81a91b32d1227c0f3cf6d2cd997ddfbdf399e796b731621  /gralloc.gbm.so" | sha256sum -c - \
 && printf '\353\244' | dd of=/gralloc.gbm.so bs=1 seek=22482 conv=notrunc \
 && echo "9bfd4e5dc3b8cdcfd88fe6d2c057ca90863430f23f3ae530e0936cbe52c16857  /gralloc.gbm.so" | sha256sum -c -

FROM ${BASE}
COPY --from=patch /gralloc.gbm.so /vendor/lib64/hw/gralloc.gbm.so
