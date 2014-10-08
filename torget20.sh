#!/bin/bash -e
#
# Display the top20 IP from the accesslog.
 
cat /var/log/httpd/access.log* |awk '{print $1}' |sort |uniq -c |sort -n | tail -20
