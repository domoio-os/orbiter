# Orbiter

**TODO: Add description**

## Installation

Generate the keys for the orbiter
         cd /etc/domoio/certs/orbiter
         openssl genrsa -out orbiter.pem 2048
         openssl rsa -in orbiter.pem -outform PEM -pubout -out orbiter.pub.pem
