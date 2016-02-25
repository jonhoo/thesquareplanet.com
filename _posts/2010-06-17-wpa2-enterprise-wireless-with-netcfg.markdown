---
layout: post
title: WPA2-Enterprise wireless with netcfg
date: '2010-06-17 05:00:25'
---

At Bond University the IT department has now finally taken the step from an open wireless network with a login proxy to a proper WPA2 Enterprise setup.

Apart from giving much higher security since data is not transmitted unencrypted through the air, this also makes it a lot easier to automatically connect to the internet. With the previous setup, a post_up netcfg hook was needed that used some specially crafted cURL code to post the login form on the proxy. Ugly as hell, and not very reliable or secure either.

The only issue is that WPA2-Enterprise has a lot of different configuration options, so it took a while to figure out the exact setup to use.

First of all I had a look at the configuration options for Windows XP here: http://www.bond.edu.au/student-resources/student-support/computing-support/for-students/wireless-access/index.htm. The advantage of looking at the XP setup guide is that it doesn't have as much fancy auto-detection as 7 or Mac OSX, so they give some more low-level details that we can base our setup on.

In this setup I decided to use netcfg simply because it provides a flexible utility for managing multiple wireless configurations and switching between them in a simple fashion. Furthermore, it abstracts away some of the uglier command line options of wpa_supplicant into configuration options.

All netcfg configuration files live in /etc/network.d. Each file represents one network, and contains at the very least for a wireless connection an interface specification, the SSID of the network and an IP configuration line. Have a look in the /etc/network.d/examples directory for, well, examples..

For WPA2-Enterprise however, we need quite a few more parameters:

```
CONNECTION='wireless'
INTERFACE=wlan0
SECURITY='wpa-configsection'
ESSID='BondStudents'
IP='dhcp'
CONFIGSECTION='
  ssid="BondStudents"
  key_mgmt=WPA-EAP
  eap=PEAP
  group=CCMP
  pairwise=CCMP
  identity="<student ID goes here>"
  password="<password goes here>"
  priority=1
  ca_path="/etc/ssl/certs"
  phase2="auth=MSCHAPV2"
'
```

Quite a mouthful.. In essence, this means we are using WPA enterprise with CCMP (an AES-based encryption algorithm) and MSCHAPV2 authentication with PEAP (TLS) encapsulation. As if that helped..

The most interesting line here is: ca_path="/etc/ssl/certs".. Why would we need to import certfiicates? Well, turns out Bond uses a SSL certificate that is not exactly mainstream called "UTN-USERFirst-Hardware". This certificate is usually included in the certificate directory of most distros, but is not very secure as it is not a trusted signing authority. If you want to know more about this, then Google it.

Well, that should be it. You should be able to run `sudo netcfg BondStudents` if you've called the configuration file "BondStudents" and you'll be online!