#!/bin/sh
# UFW setup script for SubQuery indexer
# Provided by Jim | counterpoint

# To run this script: sudo bash ufw-setup.sh

ufw disable
ufw --force reset

ufw default deny incoming

ufw default allow outgoing

# This allows Docker containers to talk to each other while not exposing their ports through the Docker IP table manipulation
# From https://hub.docker.com/r/chaifeng/ufw-docker-agent/

echo "" >> /etc/ufw/after.rules # Blank line
echo "# BEGIN UFW AND DOCKER" >> /etc/ufw/after.rules
echo "*filter" >> /etc/ufw/after.rules
echo ":ufw-user-forward - [0:0]" >> /etc/ufw/after.rules
echo ":ufw-docker-logging-deny - [0:0]" >> /etc/ufw/after.rules
echo ":DOCKER-USER - [0:0]" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-user-forward" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "-A DOCKER-USER -j RETURN -s 10.0.0.0/8" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j RETURN -s 172.16.0.0/12" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j RETURN -s 192.168.0.0/16" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "-A DOCKER-USER -p udp -m udp --sport 53 --dport 1024:65535 -j RETURN" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 192.168.0.0/16" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 10.0.0.0/8" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p tcp -m tcp --tcp-flags FIN,SYN,RST,ACK SYN -d 172.16.0.0/12" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 192.168.0.0/16" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 10.0.0.0/8" >> /etc/ufw/after.rules
echo "-A DOCKER-USER -j ufw-docker-logging-deny -p udp -m udp --dport 0:32767 -d 172.16.0.0/12" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "-A DOCKER-USER -j RETURN" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "-A ufw-docker-logging-deny -m limit --limit 3/min --limit-burst 10 -j LOG --log-prefix \"[UFW DOCKER BLOCK] \"" >> /etc/ufw/after.rules
echo "-A ufw-docker-logging-deny -j DROP" >> /etc/ufw/after.rules
echo "" >> /etc/ufw/after.rules # Blank line
echo "COMMIT" >> /etc/ufw/after.rules
echo "# END UFW AND DOCKER" >> /etc/ufw/after.rules

# Allow SSH
ufw allow 22

# Allow SubQuery proxy endpoint
ufw route allow proto tcp from any to any port 80

# Allow SubQuery admin endpoint
ufw route allow proto tcp from any to any port 8000

# Allow SubQuery admin endpoint to only my IP address
#ufw route allow proto tcp from <your IP address> to any port 8000

ufw enable