#!/bin/bash -e
#
# John Homer H Alvero
# Sept 28, 2013
#
# Remember to create /root/torblock_cust.txt for custom IP addresses
# 
 
if [ "$USER" != "root" ]; then
    echo "Must be run as root (you are $USER)."
    exit 1
fi
 
if [ "$1" == "" ]; then
    echo "$0 port [port [port [...]]]"
    exit 1
fi 
 
CHAIN_NAME="TOR"
CHAIN_NAME_CUST="TOR-CUST"
CHAIN_NAME_STR="TOR-STR"
TMP_TOR_LIST="/tmp/temp_tor_list"
TMP_TOR_MYLIST="/root/torblock_cust.txt"
IP_ADDRESS=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
 
 
BLOCK_STR[0]='Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.0)'
 
 
 
 
# Create tor chain if it doesn't exist. This is basically a grouping of
# filters within iptables.
if ! iptables -L "$CHAIN_NAME" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME" >/dev/null 2>&1
fi
 
if ! iptables -L "$CHAIN_NAME_CUST" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME_CUST" >/dev/null 2>&1
fi
 
if ! iptables -L "$CHAIN_NAME_STR" -n >/dev/null 2>&1 ; then
    iptables -N "$CHAIN_NAME_STR" >/dev/null 2>&1
fi
 
 
# Download the exist list from the tor project, build the temp file. Also
# filter out any commented (#) lines.
rm -f $TMP_TOR_LIST
touch $TMP_TOR_LIST
 
for PORT in "$@"
do
    wget -q -O - "https://check.torproject.org/cgi-bin/TorBulkExitList.py?ip=$IP_ADDRESS&port=$PORT" -U NoSuchBrowser/1.0 >> $TMP_TOR_LIST
    echo >> $TMP_TOR_LIST
done
 
sed -i 's|^#.*$||g' $TMP_TOR_LIST
 
# Block the contents of the list in iptables
if [ -s $TMP_TOR_LIST ]
then
    iptables -F $CHAIN_NAME
    for IP in $(cat $TMP_TOR_LIST | uniq | sort)
    do
        iptables -A $CHAIN_NAME -s $IP -j DROP
    done
fi
 
if [ -s $TMP_TOR_MYLIST ]
then
        iptables -F $CHAIN_NAME_CUST
        for IP in $(cat $TMP_TOR_MYLIST | uniq | sort)
        do
            iptables -A $CHAIN_NAME_CUST -s $IP -j DROP
        done
fi
 
if [ "${#BLOCK_STR[@]}" -gt "0" ]
then
        iptables -F $CHAIN_NAME_STR
        for mySTR in "${BLOCK_STR[@]}"
        do
            iptables -A $CHAIN_NAME_STR -p tcp --dport 80 -m string --string "$mySTR" --algo kmp -j DROP
        done
fi
 
iptables -F INPUT
iptables -A INPUT -p tcp -m tcp --dport 80 -j $CHAIN_NAME
iptables -A INPUT -p tcp -m tcp --dport 80 -j $CHAIN_NAME_CUST
iptables -A INPUT -p tcp -m tcp --dport 80 -j $CHAIN_NAME_STR
 
 
iptables-save >> /var/log/block-tor-iptables.log
