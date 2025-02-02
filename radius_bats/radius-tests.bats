#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00. Check packages and other dependencies are installed" {  
    run bats_pipe dpkg-query -l slapd \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l ldap-utils \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l freeradius \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l ldap-account-manager \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l freeradius-ldap \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'    
}

#LDAP UP AND SET UP
@test "01. Check slapd.service is running" {        
    systemctl is-active slapd.service
}

@test "02. Refute existence of a second DIT" {        
    run ldapsearch -LLL -D cn=admin,cn=config -w SAD -H ldap:// -b cn=config olcDatabase 
    refute_line 'dn: olcDatabase={2}mdb,cn=config'
}


@test "03. Check LDAP TLS anonymous connection" {
    run ldapwhoami -x -ZZ -H ldap://ldap01.$username.aula82.local
    assert_line "anonymous"
}

@test "04. Check LDAP Top object" {    
    ldap_password=1
    run ldapsearch -x -LLL -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -b dc=aula82,dc=local -s base 
    assert_line 'dn: dc=aula82,dc=local' 
    assert_line 'objectClass: top'    
}

#ldapadd -x -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -f ~/ldif/system-users.ldif
@test "05. Check users are properly inserted" {    
    ldap_password=1
    run ldapsearch -x -LLL -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -b dc=aula82,dc=local
    assert_line 'dn: ou=group,dc=aula82,dc=local'
    assert_line 'dn: ou=people,dc=aula82,dc=local'
    assert_line 'dn: cn=admin,ou=group,dc=aula82,dc=local'
    assert_line 'dn: cn=asir2,ou=group,dc=aula82,dc=local'
    assert_line 'dn: cn=student,ou=group,dc=aula82,dc=local'
    assert_line 'dn: cn=teacher,ou=group,dc=aula82,dc=local'
    assert_line 'dn: uid=alumno,ou=people,dc=aula82,dc=local'
    assert_line "dn: uid=$username,ou=people,dc=aula82,dc=local"    
}

@test "06. LAM installed and running on localhost" {    
    run curl -L http://localhost/lam 
    assert_line '<title>LDAP Account Manager</title>'
}

@test "07. Check user vagrant belongs to freerad group for permissions" {            
    run id -Gn
    assert_output --partial 'freerad'    
}

@test "08. Check ldap module file exists in mods-enabled and is a link to mods-available" {
    run stat -c '%F' '/etc/freeradius/3.0/mods-enabled/ldap'
    refute_output 'regular file'  
}
    
    
@test "09. Check ldap module file permisons (640 freerad:freerad)" {  
    run stat -c '%a %U %G' "/etc/freeradius/3.0/mods-available/ldap"
    assert_output --partial '640 freerad freerad'               
}


@test "10. Check ldap module file proper configuration options" {            

    run bats_pipe cat /etc/freeradius/3.0/mods-enabled/ldap \| sed '/^\s*#.*$/d' \| sed '/^\s*$/d' \| head -10
    assert_line --partial "server = 'localhost'"
    assert_line --partial "identity = 'cn=freerad,dc=aula82,dc=local'"
    assert_line --partial 'password = 1'
    assert_line --partial "base_dn = 'dc=aula82,dc=local'"    
}


@test "11. Check default is active" {            
    run stat -c '%F' '/etc/freeradius/3.0/sites-enabled/default'
    refute_output 'regular file'    
}

@test "12. Check client configuration file file accepts connections from internat network" {       
    run bats_pipe cat /etc/freeradius/3.0/clients.conf \| grep -A 10 vagrant-int-network
    assert_line --regexp "ipaddr\s*=\s*172.0.82.0/24"
    assert_line --regexp "ipaddr\s*=\s*192.168.82.0/24"
    assert_line --regexp "secret\s*=\s*testing123"    
}

@test "13. Check freeradius.service is running" {        
    systemctl is-active freeradius.service
}

@test "14. Check client connection from localhost" {            
    radtest -x alumno 1 localhost 1812 testing123    
}

@test "15. Check client connection from internal network" {            
    radtest -x alumno 1 172.0.82.1 1812 testing123    
}

@test "16. Check client connection from AP" {            
    skip
}