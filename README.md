> NOTICE! This repository is under development. 

![CI](https://github.com/JYVSECTEC/containerized-grr/workflows/CI/badge.svg?branch=master)

# Containerized GRR Rapid Response

## GRR Rapid Response

[GRR Rapid Response](https://github.com/google/grr), later GRR, is an open source incident response framework written in Python 2.7 (Python 3.6 version was published in December 2019). The development work of GRR was started in 2011 by Google, with an aim to create a state of the art tool that meets the requirements set for a cross-platform and scalable incident response framework. Since 2011 GRR has been continuously maintained by Google's software engineers and other contributors, currently being at the version 3.3.0.8 (released on 9 October 2019).

## Motivation behind containerized GRR

GRR project offers an [official Docker image](https://hub.docker.com/r/grrdocker/grr/) which can be used to run all the GRR server components, HTTP frontend, worker and web-based user interface within a single Docker container. Additionally, image includes bundled MySQL for a data storing.
However, the GRR developer team notices on their [documentation](https://grr-doc.readthedocs.io/en/v3.3.0/) that using official image is ideal only when the tool is tested or used for evaluation purposes.

Initially, the idea was to distribute the official image in a way that every component of the tool can be executed in their own Docker container. Assumption was that the distribution of components should offer a better scalability than the official image allowing usage of the contained GRR also in a large organizational networks and ability to perform incident response more intensively. It is advisable to notice that GRR can already be used, distributed and scaled by compiling it directly from a source code or installing it from a software packages. However, in my experience the Docker images are a more approachable way to take use of a tool since Docker tackles all the operating system compatibility and dependency problems that might occur when the traditional installing methods are used. In addition, the scaling process can easily find out to be more complex than utilizing container orchestration tools such Kubernetes.

## The starting point

To get the best result for the project, publicly available sources where examined to find out how other developers have deployed GRR in to their environments. During the search process I found [Spotify FOSS team's blog post](https://labs.spotify.com/2019/04/04/whacking-a-million-moles-automated-incident-response-infrastructure-in-gcp/) about how they have built a [Terraform](https://www.terraform.io/) module for a GRR and implemented it in a Google GCE environment. [Spotify's Git repository](https://github.com/spotify/terraform-google-grr) revealed also that they have built successfully a local testing environment that contains Dockerfiles for each component of GRR server.

Although the repository seemed promising for a direct deployment there were features that did not meet the requirements that were set for the distribution project. In addition, the Spotify's version used quite old version of GRR image as base image so there was need for update.

## Quick deployment

### Forewords

This repository contains all the necessary configuration files that are needed to deploy containerized GRR successfully. Please, leave an issue if you encounter any problems during or after deployment.

### Prerequisites

Containerized GRR server is successfully tested on following operating systems:

Ubuntu 18.04 Bionic (1 dual-core CPU, 8 GB RAM) with following packages and their
respectively versions:  
  * Docker Engine and Client v19.03.1  
  * Docker Compose v1.24.1

CentOS 7 (1 dual-core CPU, 8 GB RAM) with following packages and their respectively
versions:
  * Docker Engine and Client v18.09.6  
  * Docker Compose v1.24.0  

Docker images used during deployment process (hosted on Docker Hub):
  * grrdocker/grr:v3.3.0.8  
  * mysql:5.7  
  * nginx:latest  
  * prom/prometheus:latest  

GRR agents are successfully tested on following operating systems and versions:
  * Windows Workstation 7, 10  
  * Windows Server 2008, 2012  
  * CentOS 7  
  * Ubuntu 18.04  

### GRR server

Deployment of containerized GRR server is designed to be a straightforward process.
After you have executed the requirements shown in prerequisites section you should
be able to deploy GRR server using following commands:  

```bash
git clone https://github.com/JYVSECTEC/containerized-grr  
cd ./containerized-grr  
bash setup.sh  
docker network create --driver=bridge --subnet=<SUBNETWORK> static  
docker-compose up --build --detach  
```

If no errors occur command `docker-compose ps` should inform that there are now
six containers up and running:  
  * grr-admin  
  * grr-front  
  * grr-proxy  
  * grr-mysql  
  * grr-worker  
  * grr-prometheus  

Now you can access the administrator GUI by browsing by Nginx IP address or URL
and use the credentials provided during deployment process (default: admin/grr).
However, you must install GRR agents on those clients that you want to examine before you can really execute any forensic tasks on endpoints. Consult the [GRR agent
installation on clients](#GRR-agent-installation-on-clients) section for additional information.

### GRR agent installation on clients

After GRR server is successfully deployed, client installers can be examined. GRR
Server populates `./containerized-grr/installers` directory with installer packages for
both 32-bit and 64-bit operating systems:  
  * dbg_GRR_x.x.x.x_amd64.exe  
  * dbg_GRR_x.x.x.x_i386.exe  
  * grr_x.x.x.x_amd64.changes  
  * grr_x.x.x.x_amd64.deb  
  * GRR_x.x.x.x_amd64.exe  
  * grr_x.x.x.x_amd64.pkg  
  * grr_x.x.x.x_amd64.rpm  
  * grr_x.x.x.x_i386.changes  
  * grr_x.x.x.x_i386.deb  
  * GRR_x.x.x.x_i386.exe  
  * grr_x.x.x.x_i386.rpm  

Depending on the client operating system, you can push the correct installer package
to the client and execute it, or install agent using respective package manager:  

```bash
# On Red Hat based Linux distros  
yum install grr_x.x.x.x_amd64.rpm  

# On Debian based Linux distros  
dpkg --install grr_x.x.x.x_amd64.deb  

# On Windows operating systems  
.\GRR_x.x.x.x_amd64.exe  

# On MacOS  
sudo installer -pkg grr_x.x.x.x_amd64.pkg -target /  
```

### Configuration explained

#### Authentication

In future containerized GRR will support various authentication methods, but currently there are two tested methods available (defaults to Remote Authentication):  
  * Basic Authentication – Username and password are generated during setup process of GRR server and stored on the database  
  * Remote Authentication – GRR server trusts authentication that the Nginx reverse proxy handles.  

#### Database

MySQL database files are mounted to host side of system to prevent any data loss if
the container execution terminates.  

#### Monitoring  

Containerized GRR includes Prometheus monitoring system which enables investigator to observe the status of each GRR sever component and query monitoring data for occurred changes. However, it should be noticed that the monitoring system is
only implemented to bring additional feature for the server execution. Any extensively testing of Prometheus is not made.  

#### Proxy

Containerized GRR utilizes Nginx proxy which handles the traffic between GRR agents and GRR HTTP front-end. In addition, administrative user interface is accessed via proxy, and by default it handles the user authentication.

Creating a new self-signed certificate for the proxy:
```bash
cd ./containerized-grr
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ./nginx/cert.key -out ./nginx/cert.crt
```

Creating a new username and password for Remote Authentication:
```bash
cd ./containerized-grr
sh -c "echo -n '<USERNAME>:' >> ./nginx/.htpasswd" && sh -c "openssl passwd -apr1 >> ./nginx/.htpasswd"
```
#### Osquery

Containerized GRR supports also centralized management of osquery agents. GRR is
configured to search osquery binary on clients from its default installation path, so it
is advisable to keep binaries on their default installation location. Osquery is successfully tested in containerized GRR using the osquery version 4.0.2.

# Author

Author: JYVSECTEC/Joni Ahonen  
Twitter: @JYVSECTEC, @ahoneen  
More information: jyvsectec.fi  

# License

This source code is licenced under the Apache Version 2.0 license. 

# References

https://grr-doc.readthedocs.io/en/v3.3.0/  
https://github.com/google/grr/tree/v3.3.0.8  
https://labs.spotify.com/2019/04/04/whacking-a-million-moles-automated-incident-response-infrastructure-in-gcp/  
https://github.com/spotify/terraform-google-grr