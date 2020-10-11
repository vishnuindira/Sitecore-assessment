#!/bin/bash
#Path of outfiles
outpath=$1

CPU_USAGE=$(top -b -n2 -p 1 | fgrep "Cpu(s)" | tail -1 | awk -F'id,' -v prefix="$prefix" '{ split($1, vs, ","); v=vs[length(vs)]; sub("%", "", v); printf "%s%.1f%%\n", prefix, 100 - v }')
DATE=$(date "+%Y-%m-%d %H:%M:")
CPU_USAGE="$(date) CPU: $CPU_USAGE"
echo $CPU_USAGE >> $outpath/cpu_usage.out

df -H | grep -vE '^Filesystem|tmpfs|cdrom' | awk '{ print $5 " " $1 }' | while read output;
do
  usep=$(echo $output | awk '{ print $1}' | cut -d'%' -f1  )
  partition=$(echo $output | awk '{ print $2 }' )
  DISK_USAGE="$partition DISK: ($usep%) $(date)"
  echo $DISK_USAGE >> $outpath/disk_usage.out
done


