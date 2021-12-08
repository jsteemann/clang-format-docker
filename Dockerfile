FROM alpine:3.15
WORKDIR /usr/src/
ENV version=12.0.1-r0
LABEL description="ClangFormat ${version}"
RUN apk add --no-cache clang-extra-tools=${version}
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
