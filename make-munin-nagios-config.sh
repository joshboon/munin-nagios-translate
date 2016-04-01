#!/bin/bash -
#===============================================================================
#
#          FILE: make_munin_nagios_config.sh
# 
#         USAGE: ./make_munin_nagios_config.sh 
# 
#   DESCRIPTION: This script digests a full munin monitoring node and generates icinga or nagios config to match.
#                This allows you to set alerts in munin and have them flow down to icinga or nagios.
#                Note that you will also need to set munin up to pass alerts to nagios or icinga
#       OPTIONS: ---
#  REQUIREMENTS: xmlstarlet, curl, diff, tidy, munin-nagios-templates from repo in object dir
#          BUGS: ---
#         NOTES: Only tested on Ubuntu using Munin 2
#        AUTHOR: Josh Boon (jcb), alwayscurious@joshboon.com
#===============================================================================
set -o nounset                              # Treat unset variables as an error
. script.include
IFS=$'\n'
echo > $OBJECTSDIR/munin-services-generated.cfg
echo > $OBJECTSDIR/munin-servicegroups-generated.cfg
echo > $OBJECTSDIR/munin-hostgroups-generated.cfg
echo > $OBJECTSDIR/munin-hosts-generated.cfg
echo > /tmp/servicegroupsfound
echo > /tmp/hostgroupsfound
hosts=$(curl $MUNINHOST/index.html 2>/dev/null | tidy -n -asxml 2>/dev/null | xmlstarlet pyx | egrep 'Ahref[a-z].*/.*/index.html$' | uniq | sed 's~Ahref~~' )
if [[ $CHECKHOSTS = 1 ]]
then
echo "$hosts" > hosts.pre_run
diff hosts.pre_run hosts.post_run
if [[ $? != 0 ]]
then
 read -p 'I found changes as above. Are you ok with this? [y/n]' win
 if [[ "$win" = "[nN]" ]]
 then
  echo "dying"
  exit 1
 fi
fi
fi
cp hosts.pre_run hosts.post_run
for i in $hosts; do
	hostname=$(echo $i | cut -d"/" -f2)
	hostgroup=$(echo $i | cut -d"/" -f1)
        echo $hostgroup >> /tmp/hostgroupsfound
	echo "define host{
use	$HOSTTEMPLATE ; Name of host template to use
host_name $hostname
alias	$hostname
hostgroups munin-$hostgroup
address	$(grep -A1 $hostname $MUNININCLUDEDIR/*.conf | grep address | sed 's~^.*address ~~' | sed -n '1p')
}" >>  $OBJECTSDIR/munin-hosts-generated.cfg
	services=$(curl $MUNINHOST/$i 2>/dev/null | tidy -n -asxml 2>/dev/null | xmlstarlet pyx | egrep '(Aalt|Aid)' | uniq)
	for j in $services; do
		
		if [[ $(echo $j | grep -o PLL) = PLL ]]
		then 
			continue
		fi
		if [[ $(echo $j | grep -o Aid) = Aid ]]
		then 
			echo $j | sed -e 's~Aid~~' -e 's~:~~g' > /tmp/servicetype
			echo $j | sed -e 's~Aid~~' -e 's~:~~g' >> /tmp/servicegroupsfound
			continue
		fi
		service=$(echo $j | sed -e 's~Aalt~~' -e 's~:~~g' -e 's~(~~' -e 's~)~~' -e 's~%~~'  )
		servicegroup=$(cat /tmp/servicetype )
		echo "define service {
use munin-service
host_name	$hostname
service_description $service 
servicegroups munin-$servicegroup,munin-services
}" >>  $OBJECTSDIR/munin-services-generated.cfg
	done
done
servicegroups=$(cat /tmp/servicegroupsfound | sort | uniq | egrep -v '(header|footer|nav)' )
for k in $servicegroups; do
		echo "define servicegroup{
servicegroup_name munin-$k
alias munin-$k
notes_url $MUNINHOST/$k-day.html
}" >> $OBJECTSDIR/munin-servicegroups-generated.cfg
done

hostgroups=$(cat /tmp/hostgroupsfound | sort | uniq )
for l in $hostgroups; do
		echo "define hostgroup{
hostgroup_name munin-$l
alias munin-$l
notes_url $MUNINHOST/$l/index.html
}" >>  $OBJECTSDIR/munin-hostgroups-generated.cfg
done

