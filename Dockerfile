FROM ruby:3.0.4-alpine AS builder

RUN apk add \
    build-base \
    git \
    cmake \
    libffi-dev

COPY Gemfile* /tmp/
COPY cutting_edge.gemspec* /tmp/
WORKDIR /tmp
RUN bundle install

WORKDIR /app
COPY . /app
RUN bundle exec rake install

FROM ruby:3.0.4-alpine

COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

RUN apk add \
    bash \
    tzdata

VOLUME /cutting_edge
WORKDIR /cutting_edge
COPY docker-run.sh /docker-run.sh
ENTRYPOINT ["/docker-run.sh"]