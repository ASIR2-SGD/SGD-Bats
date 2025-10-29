#username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "01.files and folders created" {    
    assert_exists '/shared'    
    assert_exists '/shared/aula82'    
    assert_exists '/shared/aula14'    
    assert_exists '/shared/aula13'    
    assert_exists '/shared/common'
    assert_exists '/shared/misc'            
}

@test "02.users created" {
    grep asir2_1 /etc/passwd
    grep asir2_2 /etc/passwd
    grep asir1_1 /etc/passwd
    grep asir1_2 /etc/passwd
    grep smr1a_1 /etc/passwd
    grep smr1a_2 /etc/passwd   
    grep teacher1 /etc/passwd 
    grep teacher2 /etc/passwd
}

@test "03.existance of groups" {    
    grep students /etc/groups
    grep teachers /etc/groups
    grep asir2 /etc/groups
    grep asir1 /etc/groups
    grep smr1A /etc/groups
}

@test "04. users belons to class groups" { 
    id -nG asir2_1 | grep "\basir2\b"
    id -nG asir2_2 | grep "\basir2\b"
    id -nG asir1_1 | grep "\basir1\b"
    id -nG asir1_2 | grep "\basir1\b"
    id -nG smr1a_1 | grep "\bsmr1a\b"
    id -nG smr1a_2 | grep "\bsmr1a\b"
    
}
@test "05. users belons to student and teacher groups" { 
    id -nG asir2_1 | grep "\bstudent\b"
    id -nG asir2_2 | grep "\bstudent\b"
    id -nG asir1_1 | grep "\bstudent\b"
    id -nG asir1_2 | grep "\bstudent\b"
    id -nG smr1a_1 | grep "\bstudent\b"
    id -nG smr1a_2 | grep "\bstudent\b"
    id -nG teacher1 | grep "\bteacher\b"
    id -nG teacher2 | grep "\bteacher\b"    
}

@test "05.CA_Root mounted" {    
    skip
    egrep '^.+:/net/pki.+/net/CA_Root' /etc/fstab
    #run cat /etc/fstab
    #assert_line --regexp '^/net/CA_Root.+192\.168\.0\.200:/net/pki$'
}

@test "06.TODO" {
    skip
    ls -l /net/CA_Root/
}

@test "07.TODO" {
    skip
    assert_exists /net/CA_Root/asir2_root_ca.crt 
}

@test "08CTODO" {
    skip
    assert_exists '/usr/local/share/ca-certificates/asir2_root_ca.crt'    
}

@test "09.TODO" {
    skip
    assert_exists '/etc/ssl/certs/asir2_root_ca.pem'    
}


@test "10.TODO" {
    skip
    run stat -c '%F' '/etc/ssl/certs/asir2_root_ca.pem'
    refute_output 'regular file'    
}

@test "11.TODO" {
    skip
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -subject
    assert_output "subject=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -ext keyUsage 
    assert_line --partial  "Certificate Sign"
    run openssl x509 -in /etc/ssl/certs/asir2_root_ca.pem -noout -ext subjectKeyIdentifier
    assert_line --partial 56:BF:B7:8A:3E:8F:DE:38:AA:3B:2D:F4:99:CB:50:88:2C:9D:3D:5E
}


#CSR and SERVER CERT
@test "12.TODO" {
    skip
    run stat  -L -c '%a %U %G' '/home/vagrant/certs'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/req'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/private'
    assert_output --partial '750 vagrant vagrant' 
}

@test "13.TODO" {
    skip
    openssl rsa -in ~/certs/private/$username.aula82.local.key.pem -check  
}


@test "14.TODO" {
    skip
    private_key_hash=$(openssl x509 -modulus -noout -in ~/certs/www.$username.aula82.local.pem | openssl md5)
    cert_private_key_hash=$(openssl rsa -noout -modulus -in ~/certs/private/$username.aula82.local.key.pem | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "15.TODO" {
    skip
    run cat ~/certs/www.$username.aula82.local.info
    assert_line --partial "cn = www.$username.aula82.local"
    assert_line --partial 'tls_www_server'
}

@test "16.TODO" {
    skip
    run openssl req -text -noout -verify -in ~/certs/req/www.$username.aula82.local.csr -subject
    assert_output --partial "CN = www.$username.aula82.local"
    run bats_pipe openssl req -in ~/certs/req/www.$username.aula82.local.csr -noout -text -verify \| grep -A 1 "Extended Key Usage" 
    assert_line --partial "TLS Web Server Authentication"
}

@test "17.TODO" {
    skip
    run openssl x509 -in ~/certs/www.$username.aula82.local.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in ~/certs/www.$username.aula82.local.pem -noout -subject
    assert_output --partial "CN = www.$username.aula82.local"    
    run openssl x509 -in ~/certs/www.$username.aula82.local.pem -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in ~/certs/www.$username.aula82.local.pem -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
}

#APACHE CONF
@test "18.TODO" {
    skip
    assert_exists '/etc/apache2/ssl'   
    run stat  -L -c '%a %U %G' '/etc/apache2/ssl'
    assert_output --partial '755 root vagrant' 
}

@test "19.TODO" {
    skip
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -subject
    assert_output --partial "CN = www.$username.aula82.local"    
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
}

@test "20.TODO" {
    skip
    run stat  -L -c '%a %U %G' "/etc/apache2/ssl/private/$username.aula82.local.key.pem"
    assert_output --partial '644 root www-data'
}

@test "21.TODO" {
    skip
    openssl rsa -in /etc/apache2/ssl/private/$username.aula82.local.key.pem -check  
}


@test "22.TODO" {
    skip
    private_key_hash=$(openssl x509 -modulus -noout -in /etc/apache2/ssl/www.$username.aula82.local.pem | openssl md5)
    cert_private_key_hash=$(openssl rsa -noout -modulus -in /etc/apache2/ssl/private/$username.aula82.local.key.pem | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "23.TODO" {
    skip
    assert_exists "/etc/apache2/sites-available/www.$username.aula82.local.conf"  
    run egrep "ServerName" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "www.$username.aula82.local"    
    run egrep "SSLCertificateFile" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "/etc/apache2/ssl/www.$username.aula82.local.pem"
    run egrep "SSLCertificateKeyFile" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "/etc/apache2/ssl/private/$username.aula82.local.key.pem"    
}

@test "24.Apache www server site enabled via a2ensite" {
    skip
    assert_exists "/etc/apache2/sites-enabled/www.$username.aula82.local.conf"  
    run stat -c '%F' /etc/apache2/sites-enabled/www.$username.aula82.local.conf
    refute_output 'regular file'   
}


@test "25.Apache server www site running" {
    skip
    apache2ctl -S | egrep "443.+www.$username.aula82.local"

}


@test "26.Resolving aula82 own servername" {
    skip
    echo www.$username.aula82.local | nslookup
}

@test "27.Check certificates from own server" {
    skip
    server_name=www.${username}.aula82.local
    run bats_pipe echo echo \| openssl s_client -showcerts -servername ${server_name} -connect ${server_name}:443 2>/dev/null \| openssl x509 -noout -subject -issuer
    assert_line "issuer=CN = ASIR2 Root CA"    
    assert_line --partial "CN = www.$username.aula82.local"    
}

@test "28.Check Web page is served" {
    skip
    run curl "https://www.$username.aula82.local"
    assert_line --partial "$username"
}





