#username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_D00IRNAME}/../common/common_setup"
    _common_setup  
}

@test "01.nfs pki exported" {    
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
}

@test "02.nfs pki exported insecure" {
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+insecure'
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+all_squash'
}

@test "03.nfs exported directories exits" {    
    assert_exists '/net/pki/issued'    
    assert_exists '/net/pki/reqs'    
}

@test "04.nfs exported directories reqs is writable " { 
    run stat  -L -c '%a %U %G' '/net/pki/reqs'
    assert_output --partial '777 vagrant vagrant' 
     run stat  -L -c '%a %U %G' '/net/pki/issued'
    assert_output --partial '755 vagrant vagrant'  
}

@test "05.CA_Root mounted" {    
    egrep '^.+:/net/pki.+/net/CA_Root' /etc/fstab
    #run cat /etc/fstab
    #assert_line --regexp '^/net/CA_Root.+192\.168\.0\.200:/net/pki$'
}

@test "06.nfs CA_Root mounted on /net/CA_Root " {        
    ls -l /net/CA_Root/
}

@test "07.nfs CA_Root_aula82.pem readable" {    
    assert_exists /net/CA_Root/asir2_root_ca.crt 
}

@test "08Check CA Root Certificate ready to be installed " {    
    assert_exists '/usr/local/share/ca-certificates/asir2_root_ca.crt'    
}

@test "09.Check CA Root Certificated installed" {
    assert_exists '/etc/ssl/certs/asir2_root_ca.pem'    
}


@test "10.Check CA Root Certificated installed properly via update-ca-certificates (creates a link)" {
    run stat -c '%F' '/etc/ssl/certs/asir2_root_ca.pem'
    refute_output 'regular file'    
}

@test "11.Check CA_Root certificatee " {    
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
@test "12.Check certs folder proper permissions" {    
    run stat  -L -c '%a %U %G' '/home/vagrant/certs'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/req'
    assert_output --partial '755 vagrant vagrant' 

    run stat  -L -c '%a %U %G' '/home/vagrant/certs/private'
    assert_output --partial '750 vagrant vagrant' 
}

@test "13.check private key" {            
    openssl rsa -in ~/certs/private/$username.aula82.local.key.pem -check  
}


@test "14. Verify the Integrity of an SSL/TLS certificate and Private Key Pair" {
    private_key_hash=$(openssl x509 -modulus -noout -in ~/certs/www.$username.aula82.local.pem | openssl md5)
    cert_private_key_hash=$(openssl rsa -noout -modulus -in ~/certs/private/$username.aula82.local.key.pem | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "15.Check certificate signing request info file" {            
    run cat ~/certs/www.$username.aula82.local.info
    assert_line --partial "cn = www.$username.aula82.local"
    assert_line --partial 'tls_www_server'
}

@test "16.Check certificate signing request(CSR)" {            
    run openssl req -text -noout -verify -in ~/certs/req/www.$username.aula82.local.csr -subject
    assert_output --partial "CN = www.$username.aula82.local"
    run bats_pipe openssl req -in ~/certs/req/www.$username.aula82.local.csr -noout -text -verify \| grep -A 1 "Extended Key Usage" 
    assert_line --partial "TLS Web Server Authentication"
}

@test "17.Check www certificate in certs folder" {    
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
@test "18.Apache ssl directory exists and is readable" {    
    assert_exists '/etc/apache2/ssl'   
    run stat  -L -c '%a %U %G' '/etc/apache2/ssl'
    assert_output --partial '755 root vagrant' 
}

@test "19.Check www certificate in apache folder" { 
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -issuer
    assert_output "issuer=CN = ASIR2 Root CA"
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -subject
    assert_output --partial "CN = www.$username.aula82.local"    
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in /etc/apache2/ssl/www.$username.aula82.local.pem -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
}

@test "20.Check perms on private key" { 
    run stat  -L -c '%a %U %G' "/etc/apache2/ssl/private/$username.aula82.local.key.pem"
    assert_output --partial '640 root www-data'
}

@test "21.check private key" {            
    openssl rsa -in /etc/apache2/ssl/private/$username.aula82.local.key.pem -check  
}


@test "22. Verify the Integrity of an SSL/TLS certificate and Private Key Pair" {
    private_key_hash=$(openssl x509 -modulus -noout -in /etc/apache2/ssl/www.$username.aula82.local.pem | openssl md5)
    cert_private_key_hash=$(openssl rsa -noout -modulus -in /etc/apache2/ssl/private/$username.aula82.local.key.pem | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "23.Apache www server site configuration file" {
    assert_exists "/etc/apache2/sites-available/www.$username.aula82.local.conf"  
    run egrep "ServerName" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "www.$username.aula82.local"    
    run egrep "SSLCertificateFile" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "/etc/apache2/ssl/www.$username.aula82.local.pem"
    run egrep "SSLCertificateKeyFile" "/etc/apache2/sites-available/www.$username.aula82.local.conf"
    assert_line --partial "/etc/apache2/ssl/private/$username.aula82.local.key.pem"    
}

@test "24.Apache www server site enabled via a2ensite" {
    assert_exists "/etc/apache2/sites-enabled/www.$username.aula82.local.conf"  
    run stat -c '%F' /etc/apache2/sites-enabled/www.$username.aula82.local.conf
    refute_output 'regular file'   
}


@test "25.Apache server www site running" {
    apache2ctl -S | egrep "443.+www.$username.aula82.local"

}


@test "26.Resolving aula82 own servername" {
    echo www.$username.aula82.local | nslookup
}

@test "27.Check certificates from own server" {
    server_name=www.${username}.aula82.local
    run bats_pipe echo echo \| openssl s_client -showcerts -servername ${server_name} -connect ${server_name}:443 2>/dev/null \| openssl x509 -noout -subject -issuer
    assert_line "issuer=CN = ASIR2 Root CA"    
    assert_line --partial "CN = www.$username.aula82.local"    
}

@test "28.Check Web page is served" {
    run curl "https://www.$username.aula82.local"
    assert_line --partial "$username"
}





