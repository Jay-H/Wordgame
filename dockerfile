FROM alpine:latest AS builder

# Environment Variables
ARG GODOT_VERSION="4.4.1"
ARG GODOT_EXPORT_PRESET="Linux/X11"
ARG GODOT_GAME_NAME="wordwar"
ARG HTTPS_GIT_REPO="https://github.com/Jay-H/Wordgame/"
ENV GODOT_VERSION=${GODOT_VERSION}
ENV GODOT_GAME_NAME=${GODOT_GAME_NAME}


RUN apk update && \
    apk add --no-cache bash wget git && \
    # Install glibc required for Godot headless
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
    apk add --allow-untrusted glibc-2.31-r0.apk && \
    rm glibc-2.31-r0.apk


RUN wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_linux_headless.64.zip -O /tmp/godot.zip && \
    wget https://downloads.tuxfamily.org/godotengine/${GODOT_VERSION}/Godot_v${GODOT_VERSION}-stable_export_templates.tpz -O /tmp/templates.tpz && \
    # Extract Godot executable and move it to /usr/local/bin
    unzip /tmp/godot.zip && \
    mv Godot_v${GODOT_VERSION}-stable_linux_headless.64 /usr/local/bin/godot && \
    # Create necessary Godot configuration paths
    mkdir -p ~/.config/godot ~/.local/share/godot/templates/${GODOT_VERSION}.stable && \
    # Extract templates into the expected Godot path
    unzip /tmp/templates.tpz && \
    mv templates/* ~/.local/share/godot/templates/${GODOT_VERSION}.stable && \
    # Clean up temporary downloads
    rm -rf /tmp/godot.zip /tmp/templates.tpz templates

WORKDIR /build
RUN git clone ${HTTPS_GIT_REPO} .

RUN /usr/local/bin/godot --path /build --export-pack "${GODOT_EXPORT_PRESET}" "${GODOT_GAME_NAME}.pck"

FROM alpine:latest AS runtime

ARG GODOT_VERSION="4.4.1"
ARG GODOT_GAME_NAME="wordwar"

ENV PORT 8080
EXPOSE 8080

RUN apk update && \
    apk add --no-cache bash && \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.31-r0/glibc-2.31-r0.apk && \
    apk add --allow-untrusted glibc-2.31-r0.apk && \
    rm glibc-2.31-r0.apk && \
    # Cleanup to ensure a small final image
    rm -rf /var/cache/apk/*

COPY --from=builder /usr/local/bin/godot /usr/local/bin/godot

WORKDIR /app
COPY --from=builder /build/${GODOT_GAME_NAME}.pck /app/

CMD ["/usr/local/bin/godot", "--main-pack", "wordwar.pck"]