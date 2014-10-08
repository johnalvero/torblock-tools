#!/bin/bash
 
if [[ -z "$1" ]]; then
  echo Usage: $0 "<ip to block>"
  exit 1
fi
 
line=$(grep $1 torblock_cust.txt)
 
if [ $? -eq 0 ]
then
  echo "Already exists in torblock_cust.txt"
  exit 1
fi
 
line=$(iptables -L TOR -n | grep $1 | wc -l)
if [ $line -gt 0 ]
then
  echo "Already exists in iptables TOR chain"
  exit 1
fi
 
 
 
echo "adding new ip"
echo "$1" >> torblock_cust.txt
iptables -A TOR-CUST -s $1 -j DROP
