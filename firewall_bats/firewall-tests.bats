#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup      
}

setup_file() {
    LAN1=lan1
    export LAN1
    LAN2=lan2
    export LAN2
    FW=firewall
    export FW
    FW_LAN_IP=10.10.81.1
    export FW_LAN_IP
    LAN_NET=10.10.81.*/24
    export LAN_NET
    LAN1_IP=$(incus exec $LAN1 -- ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    export LAN1_IP
    LAN2_IP=$(incus exec $LAN2 -- ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    export LAN2_IP
    FW_WAN_IP=$(incus exec $FW -- ip route get 8.8.8.8 | awk -F"src " 'NR==1{split($2,a," ");print a[1]}')
    export FW_WAN_IP
    INCUSBR0_IP4=$(incus network get incusbr0 ipv4.address)
    INCUSBR0_IP4=${INCUSBR0_IP4%/*}
    export INCUSBR0_IP4
}

#DNS and DNSMASQ configuration
@test "00. [FW]Check firewall network devices names" {
    
    incus exec $FW -- ls -xw0 /sys/class/net | grep lan | grep wan     
}

@test "01. [FW]Check firewall lan ip" {
    
    incus exec $FW -- ip a show lan | grep "$FW_LAN_IP"
}

@test "02. [FW]Check packages and other dependencies are installed" {  
    incus exec $FW -- dpkg-query -l dnsmasq | awk '/un|ii/ { print $1 }' | grep 'ii'
    incus exec $FW -- dpkg-query -l nftables | awk '/un|ii/ { print $1 }' | grep 'ii'
    
}

@test "03. [FW]check dnsmasq properly configured" { 
    incus exec $FW -- grep "^server=$INCUSBR0_IP4@wan$" /etc/dnsmasq.d/lan.conf
    incus exec $FW -- grep '^bind-interfaces$' /etc/dnsmasq.d/lan.conf
    incus exec $FW -- grep '^dhcp-option=option:domain-name,asir2.grao' /etc/dnsmasq.d/lan.conf    
    incus exec $FW -- grep '^DNSMASQ_EXCEPT="lo"$' /etc/default/dnsmasq
}

@test "04. [FW]Check systemd-resolved stub disabled figureddnsmasq properly configured" { 
    incus exec $FW -- grep '^DNSStubListener=yes$' /etc/systemd/resolved.conf
}

@test "05. [FW]Check DNSs points to itself" { 
    incus exec $FW -- resolvectl status lan | grep "DNS Servers: $FW_LAN_IP"
    incus exec $FW -- resolvectl status lan | grep "DNS Domain: asir2.grao"
    incus exec $FW -- resolvectl status wan | grep "DNS Servers: $ICNUSBR0_IP4"
    incus exec $FW -- resolvectl status wan | grep "DNS Domain: incus"
}

@test "06. [FW]Check DNS records" { 
    incus exec $FW -- host -W1 fw
    incus exec $FW -- host -W1 lan1
    incus exec $FW -- host -W1 lan2
}

@test "07. [FW]Test lan ping and name resolution" { 
    incus exec $FW -- ping -c 1 -W 0.2 lan1
    incus exec $FW -- ping -c 1 -W 0.2 lan2
    incus exec $FW -- ping -c 1 -W 0.2 fw    
}


#LAN CLIENTS SETUP
@test "08. [LAN]Check IP in subnet" { 
    incus exec $LAN1 -- ip a show dev eth0 | grep $LAN_NET
    incus exec $LAN2 -- ip a show dev eth0 | grep $LAN_NET
}

@test "09. [LAN]Check DNS" { 
    incus exec $LAN1 -- resolvectl status eth0 | grep "DNS Servers: $FW_LAN_IP"
    incus exec $LAN1 -- resolvectl status eth0 | grep "DNS Domain: asir2.grao"
    incus exec $LAN2 -- resolvectl status eth0 | grep "DNS Servers: $FW_LAN_IP"
    incus exec $LAN2 -- resolvectl status eth0 | grep "DNS Domain: asir2.grao"
}


@test "10. [LAN]Check GW " { 
    incus exec $LAN1 -- ip route show default | grep $FW_LAN_IP
    incus exec $LAN2 -- ip route show default | grep $FW_LAN_IP
}

@test "11. [LAN]Test lan ping and name resolution" { 
    incus exec $LAN1 -- ping -c 1 -W 0.2 lan2
    incus exec $LAN1 -- ping -c 1 -W 0.2 fw
    incus exec $LAN2 -- ping -c 1 -W 0.2 lan1
    incus exec $LAN2 -- ping -c 1 -W 0.2 fw    
}


#ROUTING FW
@test "12. [FW]check ip forward enabled" {        
    incus exec $FW -- grep '1' /proc/sys/net/ipv4/ip_forward
}



#NFTABLES
@test "13. [FW]check existence of tables and proper table names" {        
    incus exec $FW -- nft list tables | grep 'table inet filter'
    incus exec $FW -- nft list tables | grep 'table inet nat'     
}

@test "14. [FW]check restrictive policy for chains in filter table" {        
    incus exec $FW -- nft list chain inet filter forward | grep 'policy drop' 
    incus exec $FW -- nft list chain inet filter input | grep 'policy drop'  
    incus exec $FW -- nft list chain inet filter output | grep 'policy drop' 
}

@test "15. [FW]check permisive policy for postrouting chain in nat table" {        
    incus exec $FW -- nft list chain inet nat postrouting | grep 'policy accept'
}

#TEST FROM WAN TO FW

@test "16. [WAN->FW] ping from wan should work on FW" { 
    ping -c 1 -W 0.2 $FW_WAN_IP    
}

@test "17. [WAN->FW] other ports should be closed on FW" { 
      run nc -w 1 -v -z $FW_WAN_IP 22
      [ "$status" -ne 0 ]
      run nc -w 1 -v -z $FW_WAN_IP 53
      [ "$status" -ne 0 ]
      run nc -w 1 -v -z $FW_WAN_IP 67
      [ "$status" -ne 0 ]
}





#TEST TO WAN FROM FW
@test "18. [FW->WAN] ping to WAN from FW should work" { 
    incus exec $FW -- ping -c 1 -W 0.2 yahoo.es    
}

@test "19. [FW->WAN] web ports to WAN from FW should work" { 
    incus exec $FW -- curl google.com
}

@test "20. [FW->WAN] dns ports to WAN from FW should work" { 
    incus exec $FW -- nc -u -w 1 -v -z $INCUSBR0_IP4 53    
}

@test "21. [FW->WAN] other output ports should be ketp closed on FW" { 
    run incus exec $FW -- nc -u -w 1 -v -z $INCUSBR0_IP4 68
    [ "$status" -ne 0 ]

    run incus exec $FW -- nc -w 1 -v -z $INCUSBR0_IP4 22
    [ "$status" -ne 0 ]
}


#SNAT && LAN
@test "22. [LAN]NAT check, clients can surf the net" {        
    incus exec $LAN1 -- ping -c 1 -W 0.2 yahoo.es
    incus exec $LAN2 -- ping -c 1 -W 0.2 yahoo.es 
    incus exec $LAN1 -- curl google.com
    incus exec $LAN2 -- curl google.com
}

#TEST FROM LAN1 !ssh
@test "23. [LAN]SSH to FW from LAN1 should fail" {        
    run incus exec $LAN1 -- nc -w 1 -v -z $FW_LAN_IP 22
    [ "$status" -ne 0 ]
}


#TEST FROM LAN2 ssh

@test "24. [LAN]SSH to FW from LAN2 should succed!" {        
    incus exec $LAN2 -- nc -w 1 -v -z $FW_LAN_IP 22
}


#TODO Check dmz