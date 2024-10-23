FROM docker.io/minio/minio:latest AS upload-pictograms

COPY --from=docker.io/minio/mc:latest /usr/bin/mc /usr/bin/mc

ARG ADMIN=minioadmin
ARG ADMIN_PWD=minioadmin
ARG IMAGES_DIR=./pictograms/images

WORKDIR /data

COPY ${IMAGES_DIR} /pictograms

RUN minio server /data & \
    server_pid=$!; \
    until mc alias set local http://127.0.0.1:9000 ${ADMIN} ${ADMIN_PWD}; do sleep 1; done; \
    mc mb local/pictograms; \
    mc cp --recursive /pictograms/ local/pictograms/; \
    mc anonymous set download local/pictograms; \
    kill $server_pid;


FROM docker.io/minio/minio:latest

COPY --from=upload-pictograms /data /data

CMD ["minio", "server", "/data", "--address", ":9000", "--console-address", ":9001"]