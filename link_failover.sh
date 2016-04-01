#!/bin/sh

# IPs TO PINGTEST
IP_TEST_1="4.2.2.2"
IP_TEST_2="8.8.8.8"

# PRIMARY LINK
PRIMARY_GATEWAY="192.168.102.2"
EXT_IP_DEFAULT="192.168.102.254"

# SECONDARY LINK
SECONDARY_GATEWAY="192.168.101.2"
EXT_IP_SECOND="192.168.101.254"

f_linkChangeActions() {
        service network restart
        service iptables restart
        service squid restart
        # OTHER ACTIONS HERE
}


f_pingReturnCheck() {
        if [ $RETORNO -eq 0 ]
        then
                echo "0"
        else
                echo "1"
        fi
}

f_doPing() {
        INTERFACE=$1
        IPADDRESS=$2
        /bin/ping -n -c 3 -I $INTERFACE $IPADDRESS >/dev/null 2>&1 ; RC=$?
        RETORNO="$RC"
        f_pingReturnCheck
}


f_doLinkTest() {
        if [ $(f_doPing "$EXT_IP_DEFAULT" "$IP_TEST_1" ) -eq "0" ] || [ $(f_doPing "$EXT_IP_DEFAULT" "$IP_TEST_2" ) -eq "0" ]
        then
                echo "PING WITH PRIMARY GATEWAY IS OK"
                if [ $(grep "GATEWAY" /etc/sysconfig/network | cut -d= -f2) == $PRIMARY_GATEWAY ]
                then
                        echo "PRIMARY GATEWAY ALREADY IS THE DEFAULT GATEWAY"
                else
                        echo "PRIMARY GATEWAY IS NOT THE DEFAULT, SETTING IT UP"
                        sed -i s/"$SECONDARY_GATEWAY"/"$PRIMARY_GATEWAY"/g /etc/sysconfig/network
                        f_linkChangeActions
                fi
        else
                echo "CANT PING ANYTHING USING PRIMARY GATEWAY"
                if [ $(grep "GATEWAY" /etc/sysconfig/network | cut -d= -f2) == $SECONDARY_GATEWAY ]
                then
                        echo "SECONDARY GATEWAY ALREADY IS THE DEFAULT GATEWAY"
                else
                        echo "SECONDARY IS NOT THE DEFAULT, SETTING IT UP"
                        sed -i s/"$PRIMARY_GATEWAY"/"$SECONDARY_GATEWAY"/g /etc/sysconfig/network
                        f_linkChangeActions
                fi
        fi
}

f_doLinkTest

