#username=$(ls -1 /etc/apache2/sites-enabled/ | egrep '^.+\.aula82\.local\.conf$' | sed -E 's/^(.+)\.aula82.*$/\1/')
#arithmetic format('%02d'%i)
#incus file push -r SGD-Bats/* acl/tmp/bats 

setup() {  
    load "${BATS_TEST_DIRNAME}/../common/common_setup"
    _common_setup  
}

@test "00.LVM instance is a virtual machine (no container)" {    
    systemd-detect-virt | grep kvm
}

@test "01.LVM installed" {    
    run bats_pipe dpkg-query -l lvm2 \| awk '/un|ii/ { print $1 }'
    assert_line 'ii'
}

@test "02.Devices created and attached" {    
    lsblk | grep 'sd[bcd].*20M'
    lsblk | grep 'sd[ef].*10M'    
}

@test "03.Phisical Volumes created" {
    pvs | grep '\/dev\/sd[bcdef]'    
}

@test "04.Volumen hdd_vg and sdd_vg groups created with phisical extension of 1MiB" {    
    vgdisplay hdd_vg | grep  'PE Size\s*1\.00\sMiB'    
    vgdisplay sdd_vg | grep  'PE Size\s*1\.00\sMiB'    
}

@test "05.Volumen hdd_vg and sdd_vg have three and two volumes respectively" { 
    vgs | grep 'hdd_vg\s*3'  
    vgs | grep 'sdd_vg\s*2'      
}

@test "06.Phisical volumes belongs to correspondent volumen group" { 
    pvs | grep '\/dev\/sd[bcd]\s*hdd_vg'  
    pvs | grep '\/dev\/sd[ef]\s*sdd_vg'  
    
}


@test "05. TODO" { 
    id -nG asir2_1 | grep "\bstudent\b"
    id -nG asir2_2 | grep "\bstudent\b"
    id -nG asir1_1 | grep "\bstudent\b"
    id -nG asir1_2 | grep "\bstudent\b"
    id -nG smr1a_1 | grep "\bstudent\b"
    id -nG smr1a_2 | grep "\bstudent\b"
    id -nG teacher1 | grep "\bteacher\b"
    id -nG teacher2 | grep "\bteacher\b"    
}

@test "06. TODO" {    
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