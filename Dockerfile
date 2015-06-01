FROM ubuntu:14.04

MAINTAINER Guy Irvine <guy@guyirvine.com>

RUN echo "Install packages" \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y update \
  && apt-get install -y \
      ruby \
      ruby-dev \
      nodejs \
      npm \
      git-core \
      libpq-dev

RUN echo "Setup locales" \
  && localedef -c -i en_NZ -f UTF-8 en_NZ.UTF-8 \
  && update-locale LANG=en_NZ.UTF-8

#RUN echo "Create user" \
#  && mkdir -p /opt/project/ \
#  && groupadd --gid 1000 puser \
#  && useradd -m --home /home/puser --uid 1000 --gid puser --shell /bin/sh puser

RUN echo "Install required" \
  && gem install bundler \
  && npm install -g bower

RUN echo "Cleaning up" \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*

COPY . /opt/project/

#USER fpuser

WORKDIR /opt/project/

# Leaving in the node / bower commands as they will no doubt prove useful ...

#RUN /bin/ln -s /usr/bin/nodejs /usr/bin/node

RUN bundle install --without test development

EXPOSE 5002

# ENTRYPOINT ["bundle", "exec", "ruby", "app.rb", "-o", "0.0.0.0", "-p", "5000"]
ENTRYPOINT ["ruby", "app.rb", "-o", "0.0.0.0", "-p", "5002"]
