FROM crystallang/crystal:1.5.0

RUN apt update -y && apt install -y \
    m4 \
    automake \
    dpkg

WORKDIR /etc/barista
COPY . /etc/barista
RUN shards install
RUN crystal spec
RUN crystal build examples/coffee_shop.cr
RUN mv coffee_shop /coffee-shop
WORKDIR /
