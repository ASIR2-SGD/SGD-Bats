setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "1. Check packages and other dependencies are installed" {            
    run bats_pipe dpkg-query -l slapd \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l ldap-utils \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
    run bats_pipe dpkg-query -l gnutls-bin \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
}

@test "2. Check certs folder proper permissions" {    
    run stat  -L -c '%a %U %G' '/home/vagrant/certs'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/req'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/private'
    assert_output --partial '755 vagrant vagrant' 
}

@test "3. check private key" {            
    openssl rsa -in ~/certs/private/$username.aula82.local.key.pem -check  
}

@test "4. Check certificate signing request info file" {            
    run cat ~/certs/ldap01.$username.aula82.local.info
    assert_line --partial "cn = ldap01.$username.aula82.local"
    assert_line --partial 'tls_www_server'
}

@test "5. Check certificate signing request(CSR)" {            
    run openssl req -text -noout -verify -in ~/certs/req/ldap01.$username.aula82.local.csr
    assert_line --partial "CN = ldap01.$username.aula82.local"
}

@test "6. Check certificates proper permissions" {    
    run stat -L -c '%a %U %G' ~/certs/ldap01.$username.aula82.local.pem
    assert_output --partial '644 vagrant vagrant' 
}


@test "7. Check ldap certificate in certs folder" {    
    run openssl x509 -in ~/certs/ldap01.$username.aula82.local.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in ~/certs/ldap01.$username.aula82.local.pem -noout -subject
    assert_output --partial "CN = ldap01.$username.aula82.local"    
    run openssl x509 -in ~/certs/ldap01.$username.aula82.local.pem -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in ~/certs/ldap01.$username.aula82.local.pem -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
}

@test "8. Check certificates proper permissions" {    
    run stat -L -c '%a %U %G' "/etc/ldap/ssl/ldap01.$username.aula82.local.pem"
    assert_output --partial '644 root openldap' 
}


@test "9. Check ldap certificate in ldap folder" {    
    run openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -noout -subject
    assert_output --partial "CN = ldap01.$username.aula82.local"    
    run openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
}


@test "10. Check CA Root Certificate ready to be installed " {    
    assert_exists '/usr/local/share/ca-certificates/asir2_root_ca.crt'    
}

@test "11. Check CA Root Certificated installed" {
    assert_exists '/etc/ssl/certs/asir2_root_ca.pem'    
}


@test "12. Check CA Root Certificated installed properly via update-ca-certificates (creates a link)" {
    run stat -c '%F' '/etc/ssl/certs/asir2_root_ca.pem'
    refute_output 'regular file'    
}

@test "13. Check CA Root Certificate is the right one" {    
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -text -noout
    assert_line --partial 'Issuer: CN = ASIR2 Root CA'
    assert_line --partial 'Subject: CN = ASIR2 Root CA'            
}


@test "14. Check folder structure under /etc/ldap" {  
    run stat -c '%a %U %G' "/etc/ldap/ssl/"
    assert_output --partial '755 root openldap' 

    run stat -c '%a %U %G' "/etc/ldap/ssl/private/"
    assert_output --partial '755 root openldap' 
}

@test "15. Check certificates placed under proper tree structure" {        
    assert_exists "/etc/ssl/certs/asir2_root_ca.pem"
    assert_exists "/etc/ldap/ssl/ldap01.$username.aula82.local.pem"
    assert_exists "/etc/ldap/ssl/private/ldap01.$username.aula82.local.key.pem"    
}

@test "16. Check Certificate is issued by the CA Root installed in the system" {    
    ca_root_id=$(openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -noout -ext authorityKeyIdentifier | tail -1 )
    cert_issuer_id=$(openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -ext subjectKeyIdentifier | tail -1 )
    [[ "${ca_root_id}"  == "${cert_issuer_id}" ]]
 
}

@test "17. Check certificates to be configured in LDAP are the right ones" {    
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -text -noout
    assert_line --partial 'Issuer: CN = ASIR2 Root CA'
    assert_line --partial 'Subject: CN = ASIR2 Root CA'            

    run openssl x509 -in /etc/ldap/ssl/ldap01.$username.aula82.local.pem -text -noout
    assert_line --partial 'Issuer: CN = ASIR2 Root CA'
    assert_line --partial "CN = ldap01.$username.aula82.local"             
}



@test "18. Check certificates proper permissions" {    
    run stat -L -c '%a %U %G' '/etc/ssl/certs/asir2_root_ca.pem'
    assert_output --partial '644 root root' 

    run stat -L -c '%a %U %G' "/etc/ldap/ssl/ldap01.$username.aula82.local.pem"
    assert_output --partial '644 root openldap' 

    run stat -L -c '%a %U %G' "/etc/ldap/ssl/private/ldap01.$username.aula82.local.key.pem"
    assert_output --partial '644 root openldap' 
}


@test "19. Check hostname ldap01.username.aula82.local" {        
    echo ldap01.$username.aula82.local | nslookup
}


@test "20. Check LDAP anonymous connection" {    
    ldapwhoami -x -H ldap://ldap01.$username.aula82.local
}

@test "21. Check LDAP cn=admin,cn=config  connection" {    
    run ldapwhoami -x -D cn=admin,cn=config -w SAD -H ldap://ldap01.$username.aula82.local
    assert_output 'dn:cn=admin,cn=config'
}

@test "22. Check LDAP olcTLSCertificates* installed" {
    run ldapsearch -LLL -D cn=admin,cn=config -w SAD  -H ldap://ldap01.$username.aula82.local -b cn=config -s base
    assert_line "olcTLSCACertificateFile: /etc/ssl/certs/asir2_root_ca.pem"
    assert_line "olcTLSCertificateFile: /etc/ldap/ssl/ldap01.$username.aula82.local.pem"
    assert_line --partial "olcTLSCertificateKeyFile: /etc/ldap/ssl/private/ldap01.$username.aula82.local"   
}

@test "23. Check LDAP TLS anonymous connection" {
    run ldapwhoami -x -ZZ -H ldap://ldap01.$username.aula82.local
    assert_line "anonymous"
}

@test "24. Check LDAP TLS cn=admin,cn=config connection" {    
    run ldapwhoami -x -ZZ  -D cn=admin,cn=config -w SAD -H ldap://ldap01.$username.aula82.local
    assert_output 'dn:cn=admin,cn=config'
}