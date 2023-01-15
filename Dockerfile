FROM crystallang/crystal:1.6.2

WORKDIR /barista

ADD shard.yml .

RUN shards install

ADD .git ./.git/
ADD src ./src/
ADD spec ./spec/
ADD fixtures ./fixtures/

CMD ["crystal", "spec"]