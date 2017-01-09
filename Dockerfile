#######################
# Web2py installation #
#######################

# Set the base image for this installation
FROM centos:7

# File Author/ Mainteainer
MAINTAINER preactive <preactive@gmail.com>

ENV container docker

#Update the repository sources list
RUN umask 022
RUN yum -y install epel-release
RUN yum update -y


########### BEGIN Firewall #############
EXPOSE 443
EXPOSE 80

########### BEGIN SYSTEM CHANGES #############
RUN useradd -m uwsgi

########### BEGIN INSTALLATION #############

## Install Git first
RUN yum install git-core -y

## Install Stuff to support Web2py
RUN yum -y group install "Development Tools"
RUN yum install -y python-devel python-pip gcc nginx wget unzip python-psycopg2 MySQL-python libxml2-devel
RUN yum clean all
RUN pip install --upgrade pip

########### BEGIN UWSGI #############
RUN pip install uwsgi

RUN mkdir -p /etc/uwsgi/sites
RUN mkdir -p /var/log/uwsgi

ADD uwsgi.ini /etc/

########### BEGIN NGINX #############
# Remove the default Nginx configuration file
RUN rm -v /etc/nginx/nginx.conf

# Copy a configuration file from the current directory
ADD nginx.conf /etc/nginx/

# Append "daemon off;" to the beginning of the configuration
RUN echo "daemon off;" >> /etc/nginx/nginx.conf

WORKDIR /etc/nginx/ssl/
RUN openssl req -x509 -new -newkey rsa:4096 -days 3652 -nodes  -subj "/C=US/ST=Test/L=Test/O=Test/CN=localhost" -keyout server.key -out server.crt

RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

########### BEGIN WEB2PY #############
RUN mkdir -p /opt/www-data/ 
WORKDIR /opt/www-data/
RUN git clone --recursive https://github.com/web2py/web2py.git

COPY parameters_80.py /opt/www-data/web2py/parameters_443.py
RUN chown uwsgi:uwsgi -R /opt/www-data/

RUN mv /opt/www-data/web2py/handlers/wsgihandler.py /opt/www-data/web2py/wsgihandler.py

########### BEGIN ENABLE SEVICES #############
RUN mkdir -p /run/uwsgi
RUN chown nginx:nginx /run/uwsgi

RUN yum install -y supervisor
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord","-c","/etc/supervisor/conf.d/supervisord.conf"]



########### Finalized #############
