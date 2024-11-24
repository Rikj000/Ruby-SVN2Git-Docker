# Base the container off the latest Alphine Linux base image
FROM alpine:latest

# Setup the application working directory
WORKDIR /var/svn2git

# Update the OS
RUN apk update; apk upgrade; apk add --no-cache \
    # Install latest Svn2Git dependencies
    ruby \
    subversion \
    perl \
    perl-subversion \
    # Install temporary build tools
    autoconf \
    g++ \
    make \
    zlib-dev \
    python3 \
    py-setuptools;

# Build + install old Git v1.8.3.1 from source
# See: https://github.com/nirvdrum/svn2git/blob/v2.4.0/lib/svn2git/migration.rb#L353
ENV GIT_VERSION=1.8.3.1
RUN wget https://github.com/git/git/archive/refs/tags/v$GIT_VERSION.tar.gz; \
    tar -zxf ./v$GIT_VERSION.tar.gz; \
    rm ./v$GIT_VERSION.tar.gz; \
    cd ./git-$GIT_VERSION; \
    make NO_TCLTK=1 configure; \
    ./configure --prefix=/usr; \
    make NO_TCLTK=1 all; \
    make NO_TCLTK=1 install; \
    cd ..; \
    rm -r ./git-$GIT_VERSION/;

# Remove temporary build tools
RUN apk del --no-cache \
    autoconf \
    g++ \
    make \
    zlib-dev \
    python3 \
    py-setuptools;

# Install Svn2Git v2.4.0 from RubyGems
RUN gem install svn2git --version 2.4.0;

# Patch Svn2Git v2.4.0 to support Ruby v3.2+
# See: https://github.com/nirvdrum/svn2git/pull/333
ENV SEARCH_STRING="      if File.exists?(File.expand_path(DEFAULT_AUTHORS_FILE))"
ENV REPLACE_STRING="      if File.exist?(File.expand_path(DEFAULT_AUTHORS_FILE))"
RUN sed -i "/^$SEARCH_STRING/s#$SEARCH_STRING#$REPLACE_STRING#" \
    "$(gem which svn2git | rev | cut -c 4- | rev)/migration.rb";

# Patch Svn2Git v2.4.0 to not error on '$stdin.gets.chomp'
# See: https://github.com/nirvdrum/svn2git/pull/308
ENV SEARCH_STRING="        loop { @stdin_queue << \$stdin.gets.chomp }"
ENV REPLACE_STRING="        loop { @stdin_queue << \$stdin.gets }"
RUN sed -i "/^$SEARCH_STRING/s#$SEARCH_STRING#$REPLACE_STRING#" \
    "$(gem which svn2git | rev | cut -c 4- | rev)/migration.rb";

# Setup the application entry point
ENTRYPOINT ["svn2git"]
