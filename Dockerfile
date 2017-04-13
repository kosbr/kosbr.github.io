FROM ruby:2.4.1

RUN gem install jekyll bundler \
    && gem install jekyll-paginate \
    && mkdir /root/src

EXPOSE 4000
