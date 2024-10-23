FROM alpine:latest AS archive-images

ARG IMAGES_DIR=./pictograms/images
COPY ${IMAGES_DIR} /pictograms

RUN tar -cf /pictograms.tar /pictograms


FROM docker.io/minio/minio:latest AS upload-pictograms

COPY --from=archive-images /pictograms.tar /pictograms.tar

COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc

ARG ADMIN=minioadmin
ARG ADMIN_PWD=minioadmin

WORKDIR /data

RUN minio server /data --address ":9000" --console-address ":9001" & \
    server_pid=$!; \
    until mc alias set local http://localhost:9000 ${ADMIN} ${ADMIN_PWD}; do sleep 1; done; \
    sleep 15; \
    mc mb local/pictograms; \
    mc cp /pictograms.tar local/pictograms/ --disable-multipart --attr "X-Amz-Meta-Snowball-Auto-Extract=true"; \
    mc anonymous set download local/pictograms; \
    kill $server_pid


FROM docker.io/minio/minio:latest

COPY --from=upload-pictograms /data /data

CMD ["minio", "server", "/data", "--address", ":9000", "--console-address", ":9001"]