
FROM golang:1.22-alpine3.19 AS builder
RUN apk add --no-cache \
    git
WORKDIR /go/src/
RUN git clone --branch master https://github.com/prometheus-community/jiralert.git
RUN git clone --branch master https://github.com/rogerluizpereira/envconfig.git

WORKDIR /go/src/jiralert/cmd/jiralert 
RUN version=$(git describe --tags --match "v[0-9]*" --always) \
&& go install -ldflags="-X main.Version=$version"
WORKDIR /go/src/envconfig
RUN version=$(git describe --tags --match "v[0-9]*" --always) \
&& go install -ldflags="-X main.Version=$version"

COPY ./config/ /go/bin/config/
COPY ./entrypoint.sh /go/bin/

FROM alpine:3.19.4 AS runtime
RUN apk add --no-cache \
     gettext
WORKDIR /jiralert/
COPY --from=builder /go/bin/ /jiralert/

ENTRYPOINT [ "/jiralert/entrypoint.sh" ]
#Apenas para debug, mantém o container rodando
#CMD ["tail", "-f", "/dev/null"]