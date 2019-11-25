FROM alpine:3.8

RUN apk add --no-cache --update openssl bash ruby ruby-json libc6-compat tini

COPY Gemfile Gemfile.lock /

ENV BUNDLE_GEMFILE /Gemfile

RUN apk --no-cache add \
        g++ \
        make \
        ruby-dev \
    && gem install --no-ri --no-rdoc bundler:2.0.2 \
    && bundle install --no-cache --frozen \
    && apk del \
        g++ \
        make \
        ruby-dev

COPY stackdriver_client.rb /
COPY ssl-cert-check /
COPY entrypoint.sh /

# nobody:nobody
USER 65534:65534

ENTRYPOINT ["tini", "--", "/entrypoint.sh"]
