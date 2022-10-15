FROM ruby:2.6.1

RUN gem install jekyll:3.4.3 bundler:1.14.6 \
    && gem install jekyll-paginate:1.1.0 \
    && mkdir /kosbr

WORKDIR /kosbr

EXPOSE 4000
