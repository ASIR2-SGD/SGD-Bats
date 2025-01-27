setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00. Check runing bats machine" {
    #ATTENTION: IF THIS TESTS FAILS MIGHT BE BECAUSE YOU ARE RUNNING THE CLIENT TEST IN THE WRONG MACHINE,
    #RUN IT IN CLIENT MACHINE INSTEAD
    run hostname
    assert_output 'client1'
}


@test "01. Check packages and other dependencies are installed" {        
    run bats_pipe dpkg-query -l sssd \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l sssd-ldap \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l ldap-utils \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l sshpass \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
}

@test "02. Check CA Root Certificate ready to be installed " {    
    assert_exists '/usr/local/share/ca-certificates/asir2_root_ca.crt'    
}

@test "03.Check CA_Root certificatee " {    
    run openssl x509 -in /usr/local/share/ca-certificates/asir2_root_ca.crt -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /usr/local/share/ca-certificates/asir2_root_ca.crt -noout -subject
    assert_output "subject=CN = ASIR2 Root CA"
    run openssl x509 -in /usr/local/share/ca-certificates/asir2_root_ca.crt -noout -ext keyUsage 
    assert_line --partial  "Certificate Sign"
    run openssl x509 -in /usr/local/share/ca-certificates/asir2_root_ca.crt -noout -ext subjectKeyIdentifier
    assert_line --partial 56:BF:B7:8A:3E:8F:DE:38:AA:3B:2D:F4:99:CB:50:88:2C:9D:3D:5E
}

@test "04. Check CA Root Certificated installed" {
    assert_exists '/etc/ssl/certs/asir2_root_ca.pem'    
}


@test "05. Check CA Root Certificated installed properly via update-ca-certificates (creates a link)" {
    run stat -c '%F' '/etc/ssl/certs/asir2_root_ca.pem'
    refute_output 'regular file'    
}

@test "06.Check CA_Root certificatee " {    
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -subject
    assert_output "subject=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -ext keyUsage 
    assert_line --partial  "Certificate Sign"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -ext subjectKeyIdentifier
    assert_line --partial 56:BF:B7:8A:3E:8F:DE:38:AA:3B:2D:F4:99:CB:50:88:2C:9D:3D:5E
}

@test "07. Check LDAP Top object" {        
    run ldapsearch -x -LLL -ZZ -D cn=admin,dc=aula82,dc=local -w $ldap_password -H ldap://ldap01.$username.aula82.local -b dc=aula82,dc=local -s base
    assert_line 'dn: dc=aula82,dc=local' 
    assert_line 'objectClass: top'    
}


@test "08. Check sssd.conf file" { 
    run sudo cat /etc/sssd/sssd.conf
    assert_line 'domains = aula82.local'
    assert_line '[domain/aula82.local]'
    assert_line 'id_provider = ldap'
    assert_line 'auth_provider = ldap'
    assert_line "ldap_uri = ldap://ldap01.$username.aula82.local"
}


@test "09. Check sssd.conf permissions" {      
    run stat -c '%a %U %G' "/etc/sssd/sssd.conf"
    assert_output  '600 root root' 
}

@test "10. Automatic home directory creation (via pam-auth-update --enable module)" { 
    egrep pam_mkhomedir.so /etc/pam.d/common-session
}

@test "11. Check sssd.service is active" {                
    systemctl is-active sssd.service    
}


@test "12. Check system users retrieved from ldap" {                
    run getent passwd profesor
    assert_output 'profesor:*:10002:10101:Profesor genérico:/home/profesor:/bin/bash'
    run getent passwd alumno
    assert_output 'alumno:*:10003:10102:Alumno genérico:/home/alumno:/bin/bash'
    run getent passwd vinatasal
    assert_output 'vinatasal:*:10007:10102:vinatasal:/home/vinatasal:/bin/bash'    
    run getent passwd arnbalmas
    assert_output 'arnbalmas:*:10008:10102:arnbalmas:/home/arnbalmas:/bin/bash'
    run getent passwd alumno_asir2
    assert_output 'alumno_asir2:*:10004:10102:Alumno_asir2 genérico:/home/alumno_asir2:/bin/bash'
    run getent passwd vicsevflo
    assert_output 'vicsevflo:*:10019:10102:vicsevflo:/home/vicsevflo:/bin/bash'
    run getent passwd hugtouram
    assert_output 'hugtouram:*:10021:10102:hugtouram:/home/hugtouram:/bin/bash'
}


@test "13. Check ldap user ssh connection " {                
    sshpass -p $ldap_password | ssh $username@localhost 'exit'    
}