#username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
#arithmetic format('%02d'%i)
#incus file push -r SGD-Bats/* acl/tmp/bats 

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00.files and folders created" {    
    assert_exists '/shared'    
    assert_exists '/shared/aula82'    
    assert_exists '/shared/aula14'    
    assert_exists '/shared/aula13'    
    assert_exists '/shared/common'
    assert_exists '/shared/misc'            
}

@test "01.whole /shared tree created" {    
    diff <(tree -n /shared) <(cat $BATS_TEST_DIRNAME/tree_shared.txt)       
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
    grep student /etc/group
    grep teacher /etc/group
    grep asir2 /etc/group
    grep asir1 /etc/group
    grep smr1a /etc/group
}

@test "04. users belong to class groups" { 
    id -nG asir2_1 | grep "\basir2\b"
    id -nG asir2_2 | grep "\basir2\b"
    id -nG asir1_1 | grep "\basir1\b"
    id -nG asir1_2 | grep "\basir1\b"
    id -nG smr1a_1 | grep "\bsmr1a\b"
    id -nG smr1a_2 | grep "\bsmr1a\b"
    
}
@test "05. users belong to student and teacher groups" { 
    id -nG asir2_1 | grep "\bstudent\b"
    id -nG asir2_2 | grep "\bstudent\b"
    id -nG asir1_1 | grep "\bstudent\b"
    id -nG asir1_2 | grep "\bstudent\b"
    id -nG smr1a_1 | grep "\bstudent\b"
    id -nG smr1a_2 | grep "\bstudent\b"
    id -nG teacher1 | grep "\bteacher\b"
    id -nG teacher2 | grep "\bteacher\b"    
}

@test "06. check perms on /shared/misc" {    
    getfacl -p /shared/misc | grep 'default:group:student:rwx'
    getfacl -p /shared/misc | grep 'default:group:teacher:rwx'
    getfacl -p /shared/misc/misc_1.txt | grep 'group:student:rw-'        
}

@test "07. check perms on /shared/common" {    
    getfacl -p /shared/common | grep 'default:group:student:r-x'
    getfacl -p /shared/common | grep 'default:group:teacher:rwx'
    getfacl -p /shared/common/common_1.txt | grep 'group:student:r--'            
    getfacl -p /shared/common/common_1.txt | grep 'group:teacher:rw-'            
}

@test "08. check perms on /shared/aula82" {    
    getfacl -p /shared/aula82 | grep 'default:group:asir2:r-x'
    getfacl -p /shared/aula82/SAD | grep 'default:group:asir2:r-x'
    getfacl -p /shared/aula82/SAD/sad_1.txt | grep 'group:asir2:r--'
    getfacl -p /shared/aula82/SAD/sad_1.txt | grep 'group:teacher:rw-'
    getfacl -p /shared/aula82 | grep 'default:group:teacher:rwx'    
}

@test "09. check perms on /shared/aula13" {    
    getfacl -p /shared/aula13 | grep 'default:group:smr1a:r-x'
    getfacl -p /shared/aula13/RLO | grep 'default:group:smr1a:r-x'
    getfacl -p /shared/aula13/RLO/redes_1.txt | grep 'group:smr1a:r--'
    getfacl -p /shared/aula13/RLO/redes_1.txt | grep 'group:teacher:rw-'
    getfacl -p /shared/aula13 | grep 'default:group:teacher:rwx'    
}

@test "10. check perms on /shared/aula14" {    
    getfacl -p /shared/aula14 | grep 'default:group:asir1:r-x'
    getfacl -p /shared/aula14 | grep 'default:group:teacher:rwx'    
}


@test "11.Create files as student in allowed folders" {
    su -c 'touch /shared/misc/test' smr1a_1
    su -c 'rm /shared/misc/test' smr1a_1
}

@test "12.Create files as teacher in aula13 folders" {
    su -c 'touch /shared/aula13/test' teacher1
    getfacl -p /shared/aula13/test | grep 'group:smr1a:r-x'
    su -c 'rm /shared/aula13/test' teacher1
}

@test "13.Create files as asir2_1 in not allowed folders" {
    ! su -c 'touch /shared/common/test' asir2_1
    ! su -c 'touch /shared/asir1/test' asir2_1
}