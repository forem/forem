# syntax=docker/dockerfile:1.7

ARG GO_VERSION=1.26

FROM golang:${GO_VERSION}-alpine AS build

WORKDIR /src

RUN apk add --no-cache ca-certificates git

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod \
    go mod download

COPY services/api ./services/api

ARG VCS_REF=unknown
ARG VERSION=dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build \
      -trimpath \
      -ldflags="-s -w -X main.version=${VERSION} -X main.commit=${VCS_REF}" \
      -o /out/noema-api ./services/api/cmd/api

FROM alpine:3.22 AS runtime

RUN apk add --no-cache ca-certificates wget && \
    addgroup -S noema && \
    adduser -S -G noema -h /app noema

WORKDIR /app
COPY --from=build /out/noema-api /app/noema-api

ENV NOEMA_ENV=production \
    PORT=8080 \
    SEARCH_PROVIDER=postgres

EXPOSE 8080
USER noema:noema
ENTRYPOINT ["/app/noema-api"]
