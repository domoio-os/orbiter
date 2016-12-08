# Orbiter

**TODO: Add description**

## Installation

Generate the keys for the orbiter
         cd /etc/domoio/certs/orbiter
         openssl genrsa -out orbiter.pem 2048
         openssl rsa -in orbiter.pem -outform PEM -pubout -out orbiter.pub.pem


### Hardware dependent extra steps
#### BeagleBone
In order to let the group gpio get access to the gpio ports, create the file /etc/udev/rules.d/99-gpio.rule with this content:

    SUBSYSTEM=="gpio*", PROGRAM="/bin/sh -c 'chown -R root:gpio /sys/class/gpio && chmod -R 770 /sys/class/gpio; chown -R root:gpio /sys/devices/virtual/gpio && chmod -R 770 /sys/devices/virtual/gpio; chown -R root:gpio /sys/devices/platform/ocp/*.gpio && chmod -R 770 /sys/devices/platform/ocp/*.gpio'"
