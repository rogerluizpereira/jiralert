
# Method 1: GO Install from package 
#FROM golang:1.22-alpine3.19 AS builder
#WORKDIR /go/
#RUN go install github.com/prometheus-community/jiralert/cmd/jiralert@v1.3.0

# Method 2: GO Install from cloned branch ( Master )
FROM golang:1.22-alpine3.19 AS builder
RUN apk add git
WORKDIR /go/src/
RUN git clone --branch master https://github.com/prometheus-community/jiralert.git
WORKDIR /go/src/jiralert
RUN go install /go/src/jiralert/cmd/jiralert
COPY ./config/ /go/bin/config/

FROM alpine:3.19.4 AS runtime
WORKDIR /jiralert/
COPY --from=builder /go/bin/ /jiralert/

ENTRYPOINT [ "/jiralert/jiralert" ]
#For debug purpose
#ENTRYPOINT ["tail", "-f", "/dev/null"]