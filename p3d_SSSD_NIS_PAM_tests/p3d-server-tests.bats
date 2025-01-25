setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "01. Check packages and other dependencies are installed" {    
    run bats_pipe dpkg-query -l slapd \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l ldap-utils \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l gnutls-bin \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
}

@test "02. Check slapd.service is running" {        
    systemctl is-active slapd.service
}

@test "03. Check LDAP TLS anonymous connection" {
    run ldapwhoami -x -ZZ -H ldap://ldap01.$username.aula82.local
    assert_line "anonymous"
}

@test "04. Check LDAP Top object" {    
    run ldapsearch -x -LLL -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -b dc=aula82,dc=local -s base 
    assert_line 'dn: dc=aula82,dc=local' 
    assert_line 'objectClass: top'    
}

#ldapadd -x -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -f ~/ldif/system-users.ldif
@test "05. Check users are properly inserted" {    
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

@test "06. Check own user login and password" {    
    run ldapwhoami -x -ZZ -D uid=$username,ou=people,dc=aula82,dc=local -w 1 -H ldap://ldap01.$username.aula82.local
    assert_output --partial "uid=$username,ou=people,dc=aula82,dc=local"   
} 
