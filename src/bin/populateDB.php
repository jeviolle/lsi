#!/usr/bin/env php
<?php
#
# populateDB.php - script to query and ouput stored data
#
#    lsi - A collection of scripts and programs that allow for the gathering
#    and reporting of Linux/Unix systems information.
#
#    Copyright (C) 2012, Rick Briganti
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

// Set the access info
define ('DB_USER', 'lsi');
define ('DB_PASSWD', 'lsi');
define ('DB_HOST', 'localhost:/tmp/mysql.sock');
define ('DB_NAME', 'lsi');

// Setup the database connection.
$dh = mysql_connect(DB_HOST, DB_USER, DB_PASSWD) OR die ('Error connecting to database: ' . mysql_error());
mysql_select_db(DB_NAME) OR die ('Error connecting to table: ' . mysql_error());
mysql_set_charset('utf8',$dh);

# set timezone
date_default_timezone_set('America/New_York');

# generic function for error handling
function myerr() {
  echo "MySQL Error " . mysql_errno() . " : " . mysql_error() . "\n";
}

class lsi {
    function biosinfo($host,$systeminfo) {
        $myDate = date("Y-m-d H:i:s", strtotime($systeminfo->bios->date));
        $pBios="CALL pBios(\"$host\",\"{$systeminfo->bios->product}\",\"{$systeminfo->bios->revision}\",\"$myDate\",\"{$systeminfo->bios->hostid}\")";

        if(!mysql_query($pBios)) { myerr(); }
    }

    function cpuinfo($host,$systeminfo) {
    
        $pCPUCount="CALL pCPUCount(\"$host\",\"{$systeminfo->cpus->count}\")";
        if(!mysql_query($pCPUCount)) { myerr(); }

        $cleanCPU="DELETE FROM processors WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if(!mysql_query($cleanCPU)) { 
	  myerr();
        } else {
          foreach ($systeminfo->cpus->cpu as $cpu) {
            $pCPU="CALL pCpu(\"$host\",\"$cpu->vendor_id\",\"$cpu->model_name\",\"$cpu->cpu_MHz\",\"$cpu->cache_size\")";
            if(!mysql_query($pCPU)) { myerr(); }
          }
        }
    }

    function diskinfo($host,$systeminfo) {

        $pDiskCount="CALL pDiskCount(\"$host\",\"{$systeminfo->disks->count}\")";
        if (!mysql_query($pDiskCount)) { myerr(); }

        $cleanDisk="DELETE FROM disks WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if(!mysql_query($cleanDisk)) { 
	  myerr();
	} else {
          foreach ($systeminfo->disks->disk as $disk) {
            $pDisk="CALL pDisk(\"$host\",\"$disk->device\",\"$disk->size\",\"$disk->model\",\"$disk->interface\")";
            if (!mysql_query($pDisk)) { myerr(); }
          }
        }
    }

    function hbainfo($host,$systeminfo) {
        $pHBACount="CALL pHBACount(\"$host\",\"{$systeminfo->hbas->count}\")";
	if (!mysql_query($pHBACount)) { myerr(); }

        $cleanHba="DELETE FROM hba_info WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if (!mysql_query($cleanHba)) {
          myerr();
        } else {
          $pHba="CALL pHba(\"$host\",\"{$systeminfo->hbas->description}\")";
	  if (!mysql_query($pHba)) { myerr(); }
        }
    }

    function hostinfo($host,$systeminfo) {
        $pHost="CALL pHost(\"$host\",\"{$systeminfo->host->vendor}\",\"{$systeminfo->host->version}\",\"{$systeminfo->host->kernel}\",\"{$systeminfo->host->arch}\",\"{$systeminfo->host->numa}\")";
        if (!mysql_query($pHost)) { myerr(); }
        
    }

    function meminfo($host,$systeminfo) {

        $pMem="CALL pMem(\"$host\",\"{$systeminfo->memory->installed}\",\"{$systeminfo->memory->maximum}\",\"{$systeminfo->memory->mbperslot}\",\"{$systeminfo->memory->slots}\")";
	if (!mysql_query($pMem)) { myerr(); }

        $cleanDimm="DELETE FROM memory_info WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if (!mysql_query($cleanDimm)) {
          myerr();
        } else {
          foreach ($systeminfo->memory->dimm as $dimm) {
            $pDimm="CALL pDimm(\"$host\",\"$dimm->form\",\"$dimm->locator\",\"$dimm->size\",\"$dimm->speed\")";
	    if (!mysql_query($pDimm)) { myerr(); }
          }
        }
    }

    function partinfo($host,$systeminfo) {

        $pPartCount="CALL pPartCount(\"$host\",\"{$systeminfo->partitions->count}\")";
	if (!mysql_query($pPartCount)) { myerr(); }

        $cleanPart="DELETE FROM partitions WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if (!mysql_query($cleanPart)) {
	  myerr();
	} else {
          foreach ($systeminfo->partitions->partition as $partition) {
            $pPart="CALL pPart(\"$host\",\"$partition->device\",\"$partition->filesystem\",\"$partition->mount\",\"$partition->options\")";
	    if (!mysql_query($pPart)) { myerr(); }
          }
        }
    }

    function pkginfo($host,$systeminfo) {
        $cleanHostPackages="DELETE FROM hostPackages WHERE hostID=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if (!mysql_query($cleanHostPackages)) {
          myerr();
        } else {
          foreach ($systeminfo->packages->package as $package) {
	    # escape strings since descriptions and maintainer stuff might contain quotes etcs
            $desc=mysql_real_escape_string($package->description);
            $maint=mysql_real_escape_string($package->maintainer);
	    
            $pPkg="CALL pPkg(\"$host\",\"$package->package\",\"$package->version\",\"$package->release\",\"$package->architecture\",\"$package->installdate\",\"$maint\",\"$desc\",\"$package->status\")";
	    if (!mysql_query($pPkg)) { 
	        myerr(); 
            }
          }
        }
    }

    function nicinfo($host,$systeminfo) {
        $pNicCount="CALL pNicCount(\"$host\",\"{$systeminfo->nics->count}\")";
        if (!mysql_query($pNicCount)) { myerr(); }

	$cleanNic="DELETE FROM nic_info WHERE id=(SELECT id FROM hosts WHERE hostname=\"$host\");";
        if (!mysql_query($cleanNic)) {
	  myerr();
	} else {
          foreach ($systeminfo->nics->nic as $nic) {
            $pNic="CALL pNic(\"$host\",\"$nic->device\",\"$nic->ip\",\"$nic->netmask\",\"$nic->mac\")";
            if (!mysql_query($pNic)) { myerr(); }
          }
	}
    }
}

# search all xml data
$command = 'find ./data -type f';
exec($command, $xmlfiles);
foreach($xmlfiles as $file){
    # read xml data
    $xmldata = file_get_contents($file);
    $systeminfo = new SimpleXMLElement($xmldata);

    #print_r($systeminfo);
    $host=$systeminfo['host'];

    # create new class instance
    $lsi = new lsi();

    $lsi->hostinfo($host,$systeminfo);
    $lsi->biosinfo($host,$systeminfo);
    $lsi->cpuinfo($host,$systeminfo);
    $lsi->meminfo($host,$systeminfo);
    $lsi->diskinfo($host,$systeminfo);
    $lsi->nicinfo($host,$systeminfo);
    $lsi->hbainfo($host,$systeminfo);
    $lsi->partinfo($host,$systeminfo);
    $lsi->pkginfo($host,$systeminfo);
}
?>
