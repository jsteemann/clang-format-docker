FROM alpine:3.12
WORKDIR /usr/src/
ENV clang_version=10.0.0-r2
RUN apk add --no-cache clang=${clang_version}
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]