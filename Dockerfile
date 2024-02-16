FROM ruby:3

RUN mkdir /srv/app
ADD . /srv/app/

WORKDIR /srv/app/

RUN bundle install

CMD ["ruby", "/srv/app/scrape.rb"]