#!/bin/bash
#creat per Jordi Blasco 18-08-2010
#set -xv
source /etc/ipmicontrol/ipmicontrol.conf
##############################################################
#                       Daemon core                          #
##############################################################

if [ -d $WORKDIR ]; then mkdir -p $WORKDIR; fi

while true
do
  hosts=$(cat /etc/hosts | grep ilo | gawk '{print $2}')
  for host in $hosts
    do 
    echo "IMPIControl on $host"
    ipmitool -I lanplus -H $host -U admin -P admin sel elist > $WORKDIR/$host.new
    RULES=$(cat /etc/ipmicontrol/rules)
    for i in $RULES
       do 
	  echo "Verify rule : $i "
	  gawk -v RULE="$i" -v HOST=$host '{if(match ($0,RULE)!=0){
                                                    print HOST" "$0
                                                    }
                             }' $WORKDIR/$host.new  >> $WORKDIR/$host.warn
       done
    LASTUDATE=$(cat $WORKDIR/$host.warn | gawk '{print system("date +%s -d \"$3 $5\"")}' | sort -n | uniq | tail -1)
    LASTUDATE=$((LASTUDATE+0))
    TDIFF=$(($(date +%s)-$LASTUDATE))
    if (( $TDIFF < $PURGE*3600 )); then
      cat $WORKDIR/$host.warn >>  $WORKDIR/collapse.warn
    fi 
    done
#      WARN=`diff $WORKDIR/collapse.warn $WORKDIR/collapse.warn.0`
#      if [ -n "$WARN" ]; then 
      if [ -e $WORKDIR/collapse.warn ]; then 
         echo "Nova entrada!"
         cat $WORKDIR/collapse.warn
	 cp -p $WORKDIR/collapse.warn $WORKDIR/collapse.warn.0
         mail -s "[IPMIControl] noves entrades" $MAIL < $WORKDIR/collapse.warn
      fi
      rm -f $WORKDIR/*.warn
      rm -f $WORKDIR/*.new
      sleep $TIMEOUT
done

