#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00. Check tests running on targeted machine" {
    #ATTENTION: IF THIS TESTS FAILS MIGHT BE BECAUSE YOU ARE RUNNING THE CLIENT TEST IN THE WRONG MACHINE,
    #RUN IT IN CLIENT MACHINE INSTEAD
    run hostname
    assert_output 'lan'
}

#NAT GW Disabled
@test "01. Check eth0 nat gw is disabled" {        
    run bats_pipe route -n \| awk 'NR>2{ print $1" "$2" "$8}'
    refute_line  '0.0.0.0 10.0.2.2 eth0'
}

@test "01. Check 60-routes.yaml exists" {        
    assert_exists '/etc/neplan/60-routes.yaml'        
}

@test "01. Check 60-routes.yaml configured" {        
    run cat '/etc/neplan/60-routes.yaml'        
    asset_line --partial 'via: 10.0.82.1'
}

@test "01. Check default gw is set" {        
    run bats_pipe route -n \| awk 'NR>2{ print $1" "$2" "$8}'
    assert_line  '0.0.0.0 10.0.82.1 eth1'
}


@test "02. Conectivity test" {        
    ping 10.0.82.1
    ping 10.0.200.1
    ping 10.0.82.100
    ping 10.0.200.100
    #ping 192.168.82.100
}

@test "01. check ip forward disabled" {        
    run cat /proc/sys/net/ipv4/ip_forward
    refute_output '1'
}