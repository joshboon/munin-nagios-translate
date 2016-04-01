# Make Icinga/nagios Easier
This script will digest a munin montioring front end and spit out a full icinga configure for any alerts passed to it.
## Why?
* Create hosts automatically which you can then use in other icinga/nagios cfg files
* Reduce the number of checks required and centralize tools and agents

## Scipt Setup
* Clone the repo to your desired location
* Copy the *.cfg files to your object dir
* Copy the munin-contact.cfg.template to munin-contact.cfg in your object dir and configure for the contact groups you want notifed for munin alerts
* Copy the script.include.template to script.include and set variables correctly
* Install xmlstarlet, curl, diff, tidy

## Nagios/Icinga setup
* setup nsca I recommend https://www.nsca-ng.org/

## Munin Setup
* setup config files
Munin has to be configured to have one file per host in the munin include dir with the template below. I will also use the specified address for pings. I generate mine on the fly from my config data and plan to release that script soon.
Sample config
[$HOSTNAME]
    address $ADDRESS
* install nsca client 
* setup munin notification channel
add the following to your munin.conf
contact.nagios.command /usr/sbin/send_nsca  -H $ICINGAIP  -c /etc/send_nsca.cfg -e'\n'
## Run
Run make_munin_nagios_config.sh 
check sanity of output with a config check then reload icinga or nagios

## TODO
* more testing
* monitoring via munin tcp check direct if available
* different sevice templates
* digest monolithic cfg files in munin

