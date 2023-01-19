FROM crystallang/crystal:1.6.2

WORKDIR /barista

ADD shard.yml .

RUN shards install

ADD .git ./.git/
ADD src ./src/
ADD spec ./spec/
ADD fixtures ./fixtures/

RUN useradd barista_spec
ENV BARISTA_TEST_USER=barista_spec

CMD ["crystal", "spec"]