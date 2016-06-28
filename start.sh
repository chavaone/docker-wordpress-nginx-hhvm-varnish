#!/bin/bash

pwd
wp bootstrap install
wp bootstrap setup

/usr/bin/hhvm --config /etc/hhvm/server.ini --user wordpress --mode daemon &
service nginx start
/usr/sbin/varnishd -f /etc/varnish/default.vcl -s malloc,100M -a 0.0.0.0:80
varnishlog -w /home/wordpress/log/varnish.log -i Timestamp,Begin,ReqMethod,ReqUrl,ReqHeader -d
