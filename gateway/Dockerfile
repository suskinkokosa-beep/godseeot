FROM golang:1.20-alpine AS build
WORKDIR /src
COPY . .
RUN go mod download && CGO_ENABLED=0 GOOS=linux go build -o /out/gateway main.go

FROM alpine:3.18
COPY --from=build /out/gateway /usr/local/bin/gateway
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/gateway"]
