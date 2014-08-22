
FROM ubuntu:14.10
MAINTAINER Will Lopez <dt.will.lopez@gmail.com>

ENV DEBIAN_FRONTEND noninteractive

# disable startup of services during image creation
RUN echo exit 101 > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d


##################################################
###################################################
##################################################

RUN apt-get update -y
RUN apt-get upgrade -y
RUN apt-get install -y apt-utils
RUN apt-get install -y python-bzrlib
RUN apt-get install -y bzr
RUN apt-get install -y mercurial

RUN apt-get install -y software-properties-common python-software-properties
RUN apt-get install -y python
RUN apt-get install -y libcurl3 libcurl4-gnutls-dev curl
RUN apt-get install -y wget
RUN apt-get install -y strace
RUN apt-get install -y diffstat

#RUN which python

RUN apt-get update -y
RUN apt-get install -y --fix-missing python-pip
RUN apt-get install -y -m pkg-config
RUN apt-get install -y -m cmake
RUN apt-get install -y -m build-essential
RUN apt-get install -y tcpdump
RUN apt-get install -y screen

RUN apt-get install -y openssh-server

# supervisor
RUN apt-get install -y supervisor

RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 22
EXPOSE 9001
CMD ["/usr/bin/supervisord"]


#
# In order to manage the maximum amount of connections upon launch, 
# open up and edit the following configuration file using nano:
#nano /etc/default/rabbitmq-server
# Uncomment the limit line (i.e. remove #) before saving and exit by 
# pressing CTRL+X followed with Y.

##################################################
################################################## java 7
##################################################

RUN apt-get update -y

#
RUN apt-get install openjdk-7-jre -y
#RUN apt-get install icedtea-7-plugin openjdk-7-jre -y
#RUN apt-get install openjdk-7-jre --fix-missing -y 
RUN apt-get install openjdk-7-jdk -y    
RUN java -version


##################################################
################################################## erlang
################################################## 
RUN apt-get --fix-missing -y install binutils build-essential
RUN apt-get update -y
RUN apt-get --fix-missing -y install m4 libncurses5-dev libssh-dev unixodbc-dev 
RUN apt-get --fix-missing -y install libgmp3-dev libwxgtk2.8-dev libglu1-mesa-dev 
RUN apt-get --fix-missing -y install fop xsltproc
RUN apt-get update -y
RUN apt-get install erlang -y

##################################################
################################################## rabbitmq
##################################################
RUN apt-get install rabbitmq-server -y
# rabbitmq config steps here
#

# plugins
RUN /usr/sbin/rabbitmq-plugins enable rabbitmq_management
RUN /usr/sbin/rabbitmq-plugins enable rabbitmq_shovel
RUN /usr/sbin/rabbitmq-plugins enable rabbitmq_shovel_management
RUN echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config

EXPOSE 5672 15672 4369


##################################################
################################################## atom
##################################################

#RUN apt-get update -y && sudo apt-get install python-software-properties -y
#RUN apt-add-repository ppa:webupd8team/atom -y
#RUN apt-get install atom -y

##################################################
################################################## elasticsearch
##################################################
#
RUN pip install elasticsearch

#
RUN \
  cd /tmp && \
  wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.tar.gz && \
  tar xvzf elasticsearch-1.3.2.tar.gz && \
  rm -f elasticsearch-1.3.2.tar.gz && \
  mv /tmp/elasticsearch-1.3.2 /elasticsearch

RUN mkdir /elasticsearch/config/templates
RUN mkdir /elasticsearch/config/mapping
RUN cd /elasticsearch/config/mapping && \
	mkdir /elasticsearch/config/mapping/inventoryindex

RUN /elasticsearch/bin/plugin --install mobz/elasticsearch-head
RUN /elasticsearch/bin/plugin --install lukas-vlcek/bigdesk

#config (can be json or yml
#ADD elasticsearch.json /elasticsearch/config/elasticsearch.json
#ADD index_inventory.json /elasticsearch/config/index_inventory.json
ADD elasticsearch.yml /elasticsearch/config/elasticsearch.yml
ADD mappings/inventoryindex/inventory.json /elasticsearch/config/mapping/inventoryindex/inventory.json
ADD mappings/inventoryindex/vehicle.json /elasticsearch/config/mapping/inventoryindex/vehicle.json
ADD templates/inventory.json /elasticsearch/config/templates/inventory.json
ADD templates/vehicle.json /elasticsearch/config/templates/vehicle.json

RUN cd /elasticsearch/config/templates/ && \
	 pwd && \
     ls -1 -a
     
RUN cd /elasticsearch/config/mapping/inventoryindex/ && \
	 pwd && \
     ls -1 -a


# Define working directory.
WORKDIR /elasticsearch/data

# Define mountable directories.
VOLUME ["/elasticsearch/data"]

# Define default command.
#CMD ["/elasticsearch/bin/elasticsearch"]

# Expose ports.
#   - 9200: HTTP
#   - 9300: transport
EXPOSE 9200
EXPOSE 9300

##################################################
################################################## go
##################################################

# Install go
RUN apt-get install golang -y

RUN go version

ENV GOROOT /usr/lib/go
ENV GOBIN /usr/bin/go
ENV PATH /usr/lib/go/bin:$PATH

# Setup home environment
RUN addgroup docker
RUN useradd dev -m --groups docker -p password
#RUN echo "%docker ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/docker.config
RUN echo "%docker ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/docker.config
RUN chown -R dev /home/dev
RUN mkdir -p /home/dev/go /home/dev/bin /home/dev/lib /home/dev/include
RUN mkdir -p /home/dev/setup/
ADD elastic_init.py /home/dev/setup/elastic_init.py
RUN chmod 755 /home/dev/setup/elastic_init.py

ENV PATH /home/dev/bin:$PATH
ENV PKG_CONFIG_PATH /home/dev/lib/pkgconfig
ENV LD_LIBRARY_PATH /home/dev/lib
ENV GOPATH /home/dev/go:$GOPATH

# Add your github token with pulls auth --add <token>
#RUN go get github.com/dotcloud/gordon/pulls

# May not need: godep to save / restore dependancies
#RUN go get github.com/kr/godep
# missing link somewhere, pointer proj missing
# May not need: Cover is used in almost all projects too
#RUN go get code.google.com/p/go.tools/cmd/cover

############################################
############################################ shared volume
############################################

# Create a shared data volume
# We need to create an empty file, otherwise the volume will
# belong to root.
# This is probably a Docker bug.
RUN mkdir /var/shared/
RUN touch /var/shared/placeholder
RUN chown -R dev:dev /var/shared
VOLUME /var/shared

