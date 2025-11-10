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


@test "07. Logical volumes created" { 
    lvs | grep -E '(db|media|web)\s*hdd.*(19|25|11)\.00m'
    lvs | grep -E '(boot|home)\s*sdd.*(1|16)\.00m'    
}

@test "08. Logical volumes partion type (ext4)" {    
    blkid | grep -E '^\/dev\/mapper\/(sdd|hdd)_vg-(home|db|web|media|boot).*TYPE=\"ext4\"$'
}

@test "09. Logical volumes mounted" {    
    mount | grep -E '^\/dev\/mapper\/(sdd|hdd)_vg-(home|db|web|media|boot)\son\s\/data/(home|db|web|media|boot)\stype ext4'    
}

@test "10. /etc/fstab has the mounts" {    
    cat /etc/fstab | grep -E '^\/dev\/(sdd|hdd)_vg\/(home|db|web|media|boot)\s+\/data\/(home|db|web|media|boot)\s+ext4\s+defaults\s+0 0$'
}

@test "11. write on some logical volumes" {    
    dd if=/dev/random of=/data/media/test bs=1024KiB count=5
    dd if=/dev/random of=/data/web/test bs=1024KiB count=2
    dd if=/dev/random of=/data/db/test bs=1024KiB count=5
    dd if=/dev/random of=/data/home/test bs=1024KiB count=5    
}

@test "11. remove from some logical volumes" {    
    rm /data/{media,web,db,home}/test
}


