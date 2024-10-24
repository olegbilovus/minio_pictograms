FROM alpine:latest AS archive-images

ARG IMAGES_DIR=./pictograms/images
COPY ${IMAGES_DIR} /pictograms

RUN tar -cf /pictograms.tar /pictograms


FROM docker.io/minio/minio:latest AS upload-pictograms

COPY --from=archive-images /pictograms.tar /pictograms.tar

COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc

ENV MINIO_COMPRESSION_ENABLE=on

WORKDIR /data

RUN minio server /data --address "127.0.0.1:9000" --console-address "127.0.0.1:9001" & \
    server_pid=$!; \
    sleep 15; \
    until mc alias set local http://127.0.0.1:9000 minioadmin minioadmin; do sleep 1; done; \
    mc mb local/pictograms && \
    mc cp /pictograms.tar local/pictograms/ --disable-multipart --attr "X-Amz-Meta-Snowball-Auto-Extract=true" && \
    mc anonymous set download local/pictograms && \
    kill $server_pid


FROM docker.io/minio/minio:latest

COPY --from=upload-pictograms /data /data

# Changed the default credentials beacause they are well-known. 
# Do not use these, set the envs when running the container.
ENV MINIO_ROOT_USER=9dd119c705a593791f9416e8cfbd053987892125f45920636387991c74bc3909
ENV MINIO_ROOT_PASSWORD=10e0c31880bd1ac873b3daf1c090223fa17cd4ce9490e0dd9c50cf80b8a4414d 
ENV MINIO_API_ROOT_ACCESS=off

CMD ["minio", "server", "/data", "--address", ":9000", "--console-address", ":9001"]