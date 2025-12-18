#username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
#arithmetic format('%02d'%i)

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "01.nfs pki exported" {   
    skip 
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
}

@test "02.nfs pki exported insecure" {
    skip
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+insecure'
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+all_squash'
}

@test "03.nfs exported directories exits" {    
    skip
    assert_exists '/net/pki/issued'    
    assert_exists '/net/pki/reqs'    
}

@test "04.nfs exported directories reqs is writable " { 
    skip
    run stat  -L -c '%a %U %G' '/net/pki/reqs'
    assert_output --partial '777 vagrant vagrant' 
     run stat  -L -c '%a %U %G' '/net/pki/issued'
    assert_output --partial '755 vagrant vagrant'  
}

@test "05.root-ca mounted" {    
    skip
    egrep '^.+:/net/pki.+/net/root_ca' /etc/fstab
    #run cat /etc/fstab
    #assert_line --regexp '^/net/CA_Root.+192\.168\.0\.200:/net/pki$'
}

@test "06.sshfs root_ca mounted on /net/root_ca " {        
    ls -l ~/certs/signed/root-ca/root-ca.crt
}

@test "07.sshfs root-ca.crt exists" {    
    assert_exists ~/certs/signed/root-ca/root-ca.crt 
}

@test "08.Check CA Root Certificate ready to be installed " {    
    assert_exists '/usr/local/share/ca-certificates/root-ca.crt'    
}

@test "09.Check CA Root Certificated installed" {
    assert_exists '/etc/ssl/certs/root-ca.pem'    
}


@test "10.Check CA Root Certificated installed properly via update-ca-certificates (creates a link)" {
    run stat -c '%F' '/etc/ssl/certs/root-ca.pem'
    refute_output 'regular file'    
}

@test "11.Check root-ca certificatee " {    
    run openssl x509 -in /etc/ssl/certs/root-ca.pem -noout -issuer
    assert_output "issuer=DC = edu, DC = ies-grao, O = IES Grao Inc, CN = IES Grao Root CA, subjectAltName = IES GRAO Root CA"
    run openssl x509 -in /etc/ssl/certs/root-ca.pem -noout -subject
    assert_output "subject=DC = edu, DC = ies-grao, O = IES Grao Inc, CN = IES Grao Root CA, subjectAltName = IES GRAO Root CA"
    run openssl x509 -in /etc/ssl/certs/root-ca.pem -noout -ext keyUsage 
    assert_line --partial  "Certificate Sign"
    run openssl x509 -in /etc/ssl/certs/root-ca.pem -noout -ext subjectKeyIdentifier
    assert_line --partial 25:5D:2F:6F:66:E9:D5:78:5D:59:1C:52:2A:1C:CC:CF:DC:25:F4:84
}


#CSR and SERVER CERT
@test "12.Check certs folder proper permissions" {    
    run stat  -L -c '%a %U %G' '/home/ubuntu/certs'
    assert_output --partial '775 ubuntu ubuntu' 

    run stat  -L -c '%a %U %G' '/home/ubuntu/certs/etc'
    assert_output --partial '775 ubuntu ubuntu' 

    run stat  -L -c '%a %U %G' '/home/ubuntu/certs/private'
    assert_output --partial '750 ubuntu ubuntu' 
}

@test "13.check private key" {            
    openssl rsa -in ~/certs/private/apache.$username.local.key -check  
}


@test "14. Verify the Integrity of an SSL/TLS certificate and Private Key Pair" {
    private_key_hash=$(openssl x509 -modulus -noout -in ~/certs/signed/apache.$username.local.crt | openssl md5)
    cert_private_key_hash=$(openssl rsa -noout -modulus -in ~/certs/private/apache.$username.local.key | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "15.Check certificate signing request info file" {            
    egrep "^DNS\..+= apache\.$username\.local$" ~/certs/etc/apache.$username.local.conf

}

@test "16.Check certificate signing request(CSR)" {            
    run openssl req -text -noout -verify -in ~/certs/csr/apache.$username.local.csr -subject
    assert_output --partial "CN = apache.$username.local"
    run bats_pipe openssl req -in ~/certs/csr/apache.$username.local.csr -noout -text -verify \| grep -A 1 "Extended Key Usage" 
    assert_line --partial "TLS Web Server Authentication"
    run bats_pipe openssl req -in ~/certs/csr/apache.$username.local.csr -noout -text -verify \| grep -A 1 "Subject Alternative Name" 
    assert_line --partial DNS:apache.$username.local    
    my_ip=$(hostname -I)    
    assert_line --partial IP Address:$my_ip
}

@test "17.Check www certificate in certs folder" {    
    run openssl x509 -in ~/certs/signed/apache.$username.local.crt -noout -issuer
    assert_output "issuer=DC = edu, DC = ies-grao, O = IES Grao Inc, CN = IES Grao Root CA, subjectAltName = IES GRAO Root CA"
    run openssl x509 -in ~/certs/signed/apache.$username.local.crt -noout -subject
    assert_output --partial "CN = apache.$username.local"    
    run openssl x509 -in ~/certs/signed/apache.$username.local.crt -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in ~/certs/signed/apache.$username.local.crt -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
    run openssl x509 -in ~/certs/signed/apache.$username.local.crt -noout -ext authorityKeyIdentifier
    assert_line --partial "25:5D:2F:6F:66:E9:D5:78:5D:59:1C:52:2A:1C:CC:CF:DC:25:F4:84"
}

#APACHE CONF
@test "18.Apache ssl directory exists and is readable" {    
    assert_exists '/etc/apache2/ssl'   
    run stat  -L -c '%a %U %G' '/etc/apache2/ssl'
    assert_output --partial '755 root www-data' 
    assert_exists '/etc/apache2/ssl/private'   
    run stat  -L -c '%a %U %G' '/etc/apache2/ssl/private'
    assert_output --partial '750 root www-data' 
}

@test "19.Check www certificate in apache folder" { 
    run openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -issuer
    assert_output "issuer=DC = edu, DC = ies-grao, O = IES Grao Inc, CN = IES Grao Root CA, subjectAltName = IES GRAO Root CA"
    run openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -subject
    assert_output --partial "CN = apache.$username.local"    
    run openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -ext keyUsage 
    assert_line --partial  "Digital Signature, Key Encipherment"
    run openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -ext extendedKeyUsage
    assert_line --partial "TLS Web Server Authentication"
    run openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -ext authorityKeyIdentifier
    assert_line --partial "25:5D:2F:6F:66:E9:D5:78:5D:59:1C:52:2A:1C:CC:CF:DC:25:F4:84"
    run bats_pipe openssl x509 -in /etc/apache2/ssl/apache.$username.local.crt -noout -text -verify \| grep -A 1 "Subject Alternative Name" 
    assert_line --partial DNS:apache.$username.local    
    my_ip=$(hostname -I)    
    assert_line --partial IP Address:$my_ip

    
}

@test "20.Check perms on private key" { 
    run sudo -u root stat  -L -c '%a %U %G' "/etc/apache2/ssl/private/apache.$username.local.key"
    assert_output --partial '640 root www-data'
}

@test "21.check private key" {            
    sudo -u root openssl rsa -in /etc/apache2/ssl/private/apache.$username.local.key -check  
}


@test "22. Verify the Integrity of an SSL/TLS certificate and Private Key Pair" {
    private_key_hash=$(openssl x509 -modulus -noout -in /etc/apache2/ssl/apache.$username.local.crt | openssl md5)
    cert_private_key_hash=$(sudo -u root openssl rsa -noout -modulus -in /etc/apache2/ssl/private/apache.$username.local.key | openssl md5)
    [[ "${private_key_hash}"  == "${cert_private_key_hash}" ]]
}

@test "23.Apache www server site configuration file" {
    assert_exists "/etc/apache2/sites-available/apache.$username.local.conf"  
    run egrep "ServerName" "/etc/apache2/sites-available/apache.$username.local.conf"
    assert_line --partial "apache.$username.local"    
    run egrep "SSLCertificateFile" "/etc/apache2/sites-available/apache.$username.local.conf"
    assert_line --partial "/etc/apache2/ssl/apache.$username.local.crt"
    run egrep "SSLCertificateKeyFile" "/etc/apache2/sites-available/apache.$username.local.conf"
    assert_line --partial "/etc/apache2/ssl/private/apache.$username.local.key"    
}

@test "24.Apache www server site enabled via a2ensite" {
    assert_exists "/etc/apache2/sites-enabled/apache.$username.local.conf"  
    run stat -c '%F' /etc/apache2/sites-enabled/apache.$username.local.conf
    refute_output 'regular file'   
}


@test "25.Apache server www site running" {
    apache2ctl -S | egrep "443.+apache.$username.local"

}


@test "26.Resolving WebServer DNS name" {
    host apache.$username.local
}

@test "27.Check certificates from own server" {
    server_name=apache.${username}.local
    run bats_pipe echo echo \| openssl s_client -showcerts -servername ${server_name} -connect ${server_name}:443 2>/dev/null \| openssl x509 -noout -subject -issuer
    assert_line "issuer=DC = edu, DC = ies-grao, O = IES Grao Inc, CN = IES Grao Root CA, subjectAltName = IES GRAO Root CA"    
    assert_line --partial "CN = apache.$username.local"    
}

@test "28.Check Web page is served" {
    run curl "https://apache.$username.local"
    assert_line --partial "$username"
}





