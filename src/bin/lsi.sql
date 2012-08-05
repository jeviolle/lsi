--#
--# lsi.sql
--#
--#    lsi - A collection of scripts and programs that allow for the gathering
--#    and reporting of Linux/Unix systems information.
--#
--#    Copyright (C) 2012, Rick Briganti
--#
--#    This program is free software: you can redistribute it and/or modify
--#    it under the terms of the GNU General Public License as published by
--#    the Free Software Foundation, either version 3 of the License, or
--#    (at your option) any later version.
--#
--#    This program is distributed in the hope that it will be useful,
--#    but WITHOUT ANY WARRANTY; without even the implied warranty of
--#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--#    GNU General Public License for more details.
--#
--#    You should have received a copy of the GNU General Public License
--#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
--#
--

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

DROP SCHEMA IF EXISTS `lsi` ;
CREATE SCHEMA IF NOT EXISTS `lsi` DEFAULT CHARACTER SET latin1 ;
USE `lsi` ;

-- -----------------------------------------------------
-- Table `lsi`.`hosts`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`hosts` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`hosts` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `hostname` VARCHAR(255) NOT NULL ,
  `architecture` VARCHAR(10) NOT NULL ,
  `kernel` VARCHAR(45) NOT NULL ,
  `numa` TINYINT(1) NOT NULL ,
  `vendor` VARCHAR(30) NOT NULL ,
  `version` VARCHAR(30) NOT NULL ,
  `cpu_count` INT(11) NULL ,
  `part_count` INT(11) NULL ,
  `disk_count` INT(11) NULL ,
  `hba_count` INT(11) NULL ,
  `nic_count` INT(11) NULL ,
  `pkg_count` INT(11) NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `hostname` (`hostname` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`bios_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`bios_info` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`bios_info` (
  `id` INT NOT NULL ,
  `hostid` VARCHAR(30) NOT NULL ,
  `product` VARCHAR(50) NOT NULL ,
  `biosrev` CHAR(30) NOT NULL ,
  `date` DATE NOT NULL ,
  `memory_slots` INT(11) NULL ,
  `maximum_mem` INT(30) NULL ,
  `installed_mem` VARCHAR(45) NULL ,
  `mbperslot` INT(11) NULL ,
  INDEX `hostid` (`hostid` ASC) ,
  INDEX `fk_bios_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`disks`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`disks` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`disks` (
  `id` INT NOT NULL ,
  `device` VARCHAR(30) NOT NULL ,
  `interface` VARCHAR(10) NOT NULL ,
  `model` VARCHAR(30) NOT NULL ,
  `size` VARCHAR(15) NOT NULL ,
  INDEX `fk_disk_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`hba_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`hba_info` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`hba_info` (
  `id` INT NOT NULL ,
  `description` VARCHAR(200) NOT NULL ,
  INDEX `fk_hba_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`memory_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`memory_info` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`memory_info` (
  `id` INT NOT NULL ,
  `form` VARCHAR(10) NOT NULL ,
  `locator` VARCHAR(10) NOT NULL ,
  `size` VARCHAR(30) NOT NULL ,
  `speed` VARCHAR(10) NOT NULL ,
  INDEX `form` (`form` ASC) ,
  INDEX `locator` (`locator` ASC) ,
  INDEX `size` (`size` ASC) ,
  INDEX `speed` (`speed` ASC) ,
  INDEX `fk_mem_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`nic_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`nic_info` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`nic_info` (
  `id` INT NOT NULL ,
  `device` VARCHAR(10) NOT NULL ,
  `ipaddr` VARCHAR(255) NOT NULL ,
  `macaddr` VARCHAR(255) NOT NULL ,
  `netmask` VARCHAR(255) NOT NULL ,
  INDEX `fk_nic_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`packages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`packages` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`packages` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `package` VARCHAR(255) NOT NULL ,
  `maintainer` VARCHAR(100) NOT NULL ,
  `description` VARCHAR(255) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `id` (`id` ASC) ,
  INDEX `package` (`package` ASC) ,
  INDEX `maintainer` (`maintainer` ASC) ,
  INDEX `description` (`description` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`partitions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`partitions` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`partitions` (
  `id` INT NOT NULL ,
  `device` VARCHAR(50) NOT NULL ,
  `filesystem` VARCHAR(10) NOT NULL ,
  `mount` VARCHAR(255) NOT NULL ,
  `options` VARCHAR(255) NOT NULL ,
  INDEX `device` (`device` ASC) ,
  INDEX `filesystem` (`filesystem` ASC) ,
  INDEX `mount` (`mount` ASC) ,
  INDEX `options` (`options` ASC) ,
  INDEX `fk_part_hostId` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`processors`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`processors` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`processors` (
  `id` INT NOT NULL ,
  `cache` VARCHAR(10) NOT NULL ,
  `speed` VARCHAR(10) NOT NULL ,
  `model` VARCHAR(50) NOT NULL ,
  `vendor` VARCHAR(30) NOT NULL ,
  INDEX `cache` (`cache` ASC) ,
  INDEX `speed` (`speed` ASC) ,
  INDEX `model` (`model` ASC) ,
  INDEX `fk_proc_id` (`id` ASC) )
ENGINE = MyISAM
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `lsi`.`hostPackages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `lsi`.`hostPackages` ;

CREATE  TABLE IF NOT EXISTS `lsi`.`hostPackages` (
  `hostID` INT NOT NULL ,
  `packageID` INT NOT NULL ,
  `installDate` TIMESTAMP NOT NULL ,
  `status` VARCHAR(45) NULL ,
  INDEX `fk_hostID` (`hostID` ASC) ,
  INDEX `fk_pkgID` (`packageID` ASC) ,
  PRIMARY KEY (`hostID`, `packageID`) )
ENGINE = MyISAM;


-- -----------------------------------------------------
-- procedure pBios
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pBios`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pBios` (host varchar(255),product varchar(50),biosrev varchar(30),date date,hostid varchar(30))
BEGIN
  IF EXISTS (SELECT id FROM bios_info WHERE id=(SELECT id FROM hosts WHERE hostname=host)) THEN
    UPDATE bios_info SET hostid=hostid,product=product,biosrev=biosrev,date=date WHERE id=(SELECT id FROM hosts WHERE hostname=host);
  ELSE
    INSERT INTO bios_info (id,hostid,product,biosrev,date) VALUES ((SELECT id FROM hosts WHERE hostname=host),hostid,product,biosrev,date); 
  END IF;
END 
$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pCPUCount
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pCPUCount`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pCPUCount` (host varchar(255),count INT(11))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET cpu_count=count WHERE hostname=host;
  END IF;
END $$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pCpu
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pCpu`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pCpu` (host VARCHAR(255),vendor VARCHAR(30),model VARCHAR(50),speed VARCHAR(10),cache VARCHAR(10))
BEGIN
INSERT INTO processors (id,vendor,model,speed,cache) VALUES ((SELECT id FROM hosts WHERE hostname=host),vendor,model,speed,cache);
END $$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pDiskCount
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pDiskCount`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pDiskCount` (host VARCHAR(255),count INT(11))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET disk_count=count WHERE hostname=host; 
  END IF;
END $$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pDisk
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pDisk`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pDisk` (host VARCHAR(255),device VARCHAR(30),size VARCHAR(15),model VARCHAR(30),interface VARCHAR(10))
BEGIN
INSERT INTO disks (id,device,size,model,interface) VALUES ((SELECT id FROM hosts WHERE hostname=host),device,size,model,interface); 
END $$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pHBACount
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pHBACount`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pHBACount` (host VARCHAR(255), count INT(11))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET hba_count=count WHERE hostname=host; 
  END IF; 
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pHba
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pHba`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pHba` (host VARCHAR(255),description VARCHAR(200))
BEGIN
SET @vDescription:=description;
  IF (SELECT @vDescription != " ") THEN
    INSERT INTO hba_info (id,description) VALUES ((SELECT id FROM hosts WHERE hostname=host),description); 
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pHost
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pHost`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pHost` (host VARCHAR(255),vendor VARCHAR(30),version VARCHAR(30),kernel VARCHAR(45),arch VARCHAR(10),numa TINYINT(1))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET vendor=vendor,version=version,kernel=kernel,architecture=architecture,numa=numa WHERE hostname=host; 
  ELSE
    INSERT INTO hosts (hostname,vendor,version,kernel,architecture,numa) VALUES (host,vendor,version,kernel,arch,numa); 
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pMem
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pMem`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pMem` (host VARCHAR(255),installed VARCHAR(45), max INT(30), mbperslot INT(11),slots INT(11))
BEGIN
  IF EXISTS (SELECT id FROM bios_info WHERE id=(SELECT id FROM hosts WHERE hostname=host)) THEN
    UPDATE bios_info SET installed_mem=installed,maximum_mem=max,mbperslot=mbperslot,memory_slots=slots WHERE id=(SELECT id FROM hosts WHERE hostname=host);
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pDimm
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pDimm`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pDimm` (host VARCHAR(255),form VARCHAR(10),locator VARCHAR(10),size VARCHAR(30),speed VARCHAR(10))
BEGIN
INSERT INTO memory_info (id,form,locator,size,speed) VALUES ((SELECT id FROM hosts WHERE hostname=host),form,locator,size,speed);
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pPartCount
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pPartCount`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pPartCount` (host VARCHAR(255),count INT(11))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET part_count=count WHERE hostname=host; 
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pPart
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pPart`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pPart` (host VARCHAR(255),device VARCHAR(50),fs VARCHAR(10),mount VARCHAR(255),options VARCHAR(255))
BEGIN
INSERT INTO partitions (id,device,filesystem,mount,options) VALUES ((SELECT id FROM hosts WHERE hostname=host),device,fs,mount,options);
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pPkg
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pPkg`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pPkg` (host VARCHAR(255),name VARCHAR(100),version VARCHAR(30),revision VARCHAR(30),architecture VARCHAR(10),installdate TIMESTAMP,maintainer VARCHAR(100), description VARCHAR(255),status VARCHAR(45))
BEGIN
  # get host id
  SELECT id INTO @hostid FROM hosts WHERE hostname=host;
  
  # Generate package name based on the type
  # RPM do not have a installed status
  IF (status = " ") THEN
    SET @pkgname = concat(name,"-",version,"-",revision,".",architecture);
  ELSE
    SET @pkgname = concat(name,"_",version,"-",revision,"_",architecture);
  END IF;

  SELECT count(*) INTO @pkgcount FROM packages 
  WHERE package=@pkgname 
  AND maintainer=maintainer 
  AND description=description;
    
  IF (@pkgcount = 0) THEN
    INSERT INTO packages (package,maintainer,description) VALUES (
    @pkgname,
    maintainer,
    description);
  END IF;

  # populate host pacakages to map packages to hosts
  SELECT id INTO @pkgid FROM packages WHERE package=@pkgname AND maintainer=maintainer AND description=description;
  INSERT IGNORE INTO hostPackages (hostID,packageID,installDate,status) VALUES (@hostid,@pkgid,installdate,status);  

  # update the package count from the host packages table
  UPDATE hosts SET pkg_count=(SELECT count(*) FROM hostPackages WHERE hostID=@hostid) WHERE id=@hostid; 

END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pNicCount
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pNicCount`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pNicCount` (host VARCHAR(255),count INT(11))
BEGIN
  IF EXISTS (SELECT id FROM hosts WHERE hostname=host) THEN
    UPDATE hosts SET nic_count=count WHERE hostname=host; 
  END IF;
END$$

DELIMITER ;

-- -----------------------------------------------------
-- procedure pNic
-- -----------------------------------------------------

USE `lsi`;
DROP procedure IF EXISTS `lsi`.`pNic`;

DELIMITER $$
USE `lsi`$$
CREATE PROCEDURE `lsi`.`pNic` (host VARCHAR(255),device VARCHAR(10),ipaddr VARCHAR(255),netmask VARCHAR(255),macaddr VARCHAR(255))
BEGIN
INSERT INTO nic_info (id,device,ipaddr,netmask,macaddr) VALUES ((SELECT id FROM hosts WHERE hostname=host),device,ipaddr,netmask,macaddr); 
END $$

DELIMITER ;
USE `lsi`;

DELIMITER $$

USE `lsi`$$
DROP TRIGGER IF EXISTS `lsi`.`bd_host` $$
USE `lsi`$$


# automatically delete on host dependent information
# in all tables
CREATE TRIGGER bd_host
BEFORE DELETE on hosts
FOR EACH ROW
BEGIN
  DELETE FROM bios_info WHERE bios_info.id=OLD.id;
  DELETE FROM disks WHERE disks.id=OLD.id;
  DELETE FROM memory_info WHERE memory_info.id=OLD.id;
  DELETE FROM processors WHERE processors.id=OLD.id;
  DELETE FROM hba_info WHERE hba_info.id=OLD.id;
  DELETE FROM hostPackages WHERE hostPackages.hostID=OLD.id;
  DELETE FROM nic_info WHERE nic_info.id=OLD.id;
  DELETE FROM partitions WHERE partitions.id=OLD.id;
END
$$


DELIMITER ;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
