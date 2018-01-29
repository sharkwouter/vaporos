#Dockerfile for building the ubuntu installer for Debian

FROM sharkwouter/steamos
MAINTAINER Wouter Wijsman

#Make sure we're running the latest update
RUN apt-get update
RUN apt-get dist-upgrade -y

#Add repo sources
ADD debian.list /etc/apt/sources.list.d/debian.list
RUN apt-get update

#Clean archive
RUN apt-get clean

#Create user
RUN useradd -m -s /bin/bash builder
#RUN echo "builder ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builder-nopasswd

#Create share directory
RUN mkdir -p /home/builder/share
RUN chown builder:builder /home/builder/share

#Set default user
USER builder:builder

#This directory should be shared with the host
WORKDIR /home/builder/share
