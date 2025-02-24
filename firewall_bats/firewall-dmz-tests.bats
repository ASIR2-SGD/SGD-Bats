#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00. Check tests running on targeted machine" {
    #ATTENTION: IF THIS TESTS FAILS MIGHT BE BECAUSE YOU ARE RUNNING THE CLIENT TEST IN THE WRONG MACHINE,
    #RUN IT IN CLIENT MACHINE INSTEAD
    run hostname
    assert_output 'dmz'
}

#NAT GW Disabled
@test "01. Check eth0 nat gw is disabled" {        
    run bats_pipe route -n \| awk 'NR>2{ print $1" "$2" "$8}'
    refute_line  '0.0.0.0 10.0.2.2 eth0'
}

@test "02. Check 60-routes.yaml exists" {        
    assert_exists '/etc/netplan/60-routes.yaml'        
}

@test "03. Check 60-routes.yaml configured" {        
    run cat '/etc/netplan/60-routes.yaml'        
    assert_line --partial 'via: 10.0.200.1'
}

@test "04. Check default gw is set" {        
    run bats_pipe route -n \| awk 'NR>2{ print $1" "$2" "$8}'
    assert_line  '0.0.0.0 10.0.200.1 eth1'
}


@test "05. check ip forward enabled" {        
    run cat /proc/sys/net/ipv4/ip_forward
    refute_output '1'
}

@test "06. Output traffic to wan should fail" {        
    run ping -c 1 -W 0.2 192.168.82.100
    [ "$status" -ne 0 ]
}

@test "07. Output traffic to fw should fail" {        
    run ping -c 1 -W 0.2 10.0.200.1
    [ "$status" -ne 0 ]
}

@test "08. Output traffic to lan should fail" {        
    run ping -c 1 -W 0.2 10.0.82.200
    [ "$status" -ne 0 ]
}

@test "09. Output traffic to lan should fail" {        
    run ping -c 1 -W 0.2 10.0.82.100
    [ "$status" -ne 0 ]
}

@test "10. Output ldap traffic to lan should fail" {        
    run ping -c 1 -W 0.2 10.0.82.100
    [ "$status" -ne 0 ]
}

@test "11. Output ldap traffic to ldap server should succeed" {        
    run nc -v -z 10.0.82.200 389
    [ "$status" -eq 0 ]
}

@test "12. ldap connection to ldap serverr should succeed" {        
    run ldapwhoami -x -H ldap://10.0.82.200    
    [ "$status" -eq 0 ]
}

@test "13. ldap connection with cn=admin user should should succeed" {        
    run ldapwhoami -x  -D cn=admin,dc=aula82,dc=local -w 1 -H ldap://10.0.82.200
    [ "$status" -eq 0 ]
}

@test "14. ldap search should should succeed" {        
    run ldapsearch -x -LLL  -D cn=admin,dc=aula82,dc=local -w 1 -H ldap://10.0.82.200 -b dc=aula82,dc=local -s base
    [ "$status" -eq 0 ]
}