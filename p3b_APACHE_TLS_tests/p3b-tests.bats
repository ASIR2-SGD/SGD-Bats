setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "nfs pki exported" {
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'
}

@test "nfs pki exported insecure" {
    run cat /etc/exports
    assert_line --regexp '^/net/pki.+[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.+insecure'
}

@test "nfs exported directories exits" {    
    assert_exists '/net/pki/issued'    
    assert_exists '/net/pki/reqs'    
}

@test "nfs exported directories reqs is writable " {    
    touch /net/pki/reqs/test.txt
    #assert_file_permission 664 '/net/pki/reqs/test.txt'    
    rm /net/pki/reqs/test.txt
}


@test "nfs CA_Root mounted on /net/CA_Root " {    
    run ls -l /net/CA_Root/
}

@test "nfs CA_Root_aula82.pem readable" {    
    assert_exists /net/CA_Root/CA_Root_aula82.pem  
}

@test "CA_Root mounted" {    
    egrep '^.+:/net/pki.+/net/CA_Root' /etc/fstab
    #run cat /etc/fstab
    #assert_line --regexp '^/net/CA_Root.+192\.168\.0\.200:/net/pki$'
}

@test "CA_Intermediate mounted" {    
    egrep '^.+:/net/pki.+/net/CA_Intermediate' /etc/fstab
}

@test "OS aware of CA_Root" {    
    assert_exists /lib/ssl/certs/CA_Root_aula82.pem  
}

@test "Apache server certificate configuration" {
    #username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
    
    conf_file=$username.aula82.local.conf    

    egrep 'SSLCertificateFile.*'$username'_aula82_chain.crt' /etc/apache2/sites-enabled/$conf_file     
}

@test "Chain certficated exists and placed in /etc/ssl/certs" {
    #username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
    
    assert_exists '/etc/ssl/certs/'$username'_aula82_chain.crt'
}

@test "Chain certficated issued by CA_Root" {
    #username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
    
    run bats_pipe openssl crl2pkcs7 -nocrl -certfile '/etc/ssl/certs/'$username'_aula82_chain.crt' \| openssl pkcs7 -print_certs -noout 

    assert_line --partial 'SAD_Root_aula82.org'
}

@test "DNS configured" {
    run cat /etc/netplan/50-vagrant.yaml

    assert_line --partial 'nameservers'
}

@test "Resolving aula82 own servername" {
    echo $username.aula82.local | nslookup
}

@test "Resolving vinatasal.aula82.local" {    
    host vinatasal.aula82.local    
}

@test "Resolving ewaadd.aula82.local" {    
    host ewaadd.aula82.local    
}

@test "Resolving sangonort.aula82.local" {    
    host sangonort.aula82.local    
}

@test "Check certificates from own server" {
    server_name=${username}.aula82.local
    run bats_pipe echo "" \| openssl s_client -showcerts $server_name:443 \| openssl crl2pkcs7 -nocrl -certfile /dev/stdin \| openssl pkcs7 -noout -print_certs
    assert_line --partial 'SAD_Root_aula82.org'      
}




