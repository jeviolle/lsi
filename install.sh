#!/bin/bash
#
#
# install.sh - script for installation
#
#    lsi - A collection of scripts and programs that allow for the gathering
#    and reporting of Linux/Unix systems information.
#
#    Copyright (C) 2010, Rick Briganti
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
#

CWD=`dirname $0`

# check prerequisites for the client
$CWD/src/bin/verifyPreReq.sh
if [ "$?" -ne 0 ];then
    exit 1
fi


install() {
echo -n "Enter the install location (default: /usr/local/lsi): "
read prefix

if [ -z $prefix ];then
  prefix="/usr/local/lsi"
fi

echo -n "You have entered: $prefix, is this correct (Y/n): "
read confirm

if [ -z $confirm ];then
  confirm="y"
fi

}

# launch install
echo
install

# loop until
while [ "`echo $confirm | tr [A-Z] [a-z]`" != "y" ];do
    echo
    echo "You must enter 'y' to complete the install. You entered: $confirm"
    echo
    install
done

# set collection server ip addresses
while [ "`echo $ipconfirm | tr [A-Z] [a-z]`" != "y" ]; do
  echo
  echo -n "Enter the Collection server IP Address (default: 127.0.0.1): "
  read ipaddr

  if [ -z $ipaddr ];then
    ipaddr="127.0.0.1"
  fi

  echo -n "You have entered: $ipaddr, is this correct (Y/n): "
  read ipconfirm

  if [ -z $ipconfirm ];then
    ipconfirm="y"
  fi
done

# set port in /etc/services for xinetd
while [ "`echo $tcpconfirm | tr [A-Z] [a-z]`" != "y" ]; do
  echo
  echo -n "Enter the desired TCP Port number (default: 8730): "
  read tcpport

  if [ -z $tcpport ];then
    tcpport="8730"
  fi

  PORT=`grep -v "^#" /etc/services | grep -P "\s+$tcpport\/tcp"`
  if [ $? -eq 0 ];then
    echo
    echo "WARNING: $tcpport/tcp found in /etc/services!" 
    echo "WARNING: $PORT"
    echo
    echo -n "Are you sure you want to use $tcpport/tcp (Y/n): "
    read tcpconfirm
  else
    echo -n "You have entered: $tcpport, is this correct (Y/n): "
    read tcpconfirm
  fi

  if [ -z $tcpconfirm ];then
    tcpconfirm="y"
  fi

done

echo
echo "Setup will continue in 5 seconds, press CTRL+C to exit setup..." 
sleep 5

echo
echo "Installing to $prefix ..."
echo
mkdir -p $prefix
cp -Rv $CWD/src/* $prefix

echo 
echo "Updating default LSI configurations with the new install"
echo "location."
REPLACE=$(printf "%s\n" "$prefix" | sed 's/[][\.*^$/]/\\&/g')
sed -i -e "s/PREFIX/$REPLACE/g" $prefix/etc/stunnel/*.conf
sed -i -e "s/PREFIX/$REPLACE/g" $prefix/share/doc/xinetd-example

if [ -f /etc/xinetd.d/lsi ];then
  echo
  echo "Backing up existing /etc/xinetd.d/lsi"
  echo
  cp -v /etc/xinetd.d/lsi /etc/xinetd.d/lsi.$$.`date +%Y%m%d`
fi

echo
echo "Creating new /etc/xinetd.d/lsi"
echo
cp -v $prefix/share/doc/xinetd-example /etc/xinetd.d/lsi

echo
echo "Backing up existing /etc/services"
cp /etc/services /etc/services.$$.`date +%Y%m%d`
echo "Added the following to /etc/services"
echo
echo "lsi		$tcpport/tcp			# lsi service" | tee -a /etc/services
echo

# create hosts.allow entry for lsi
if [ -f /etc/hosts.allow ];then
  echo "Backing up existing /etc/hosts.allow"
  cp /etc/hosts.allow /etc/hosts.allow.$$.`date +%Y%m%d`
  grep -q "^lsi:" /etc/hosts.allow

  if [ $? -eq 0 ];then
    sed -i -e 's/^lsi:.*//g' /etc/hosts.allow
  fi

  echo "Adding lsi to /etc/hosts.allow"
  echo "lsi: $ipaddr" >> /etc/hosts.allow
fi

echo

# create hosts.deny entry for lsi
if [ -f /etc/hosts.deny ];then
  echo "Backing up existing /etc/hosts.deny"
  cp /etc/hosts.deny /etc/hosts.deny.$$.`date +%Y%m%d`
  grep -q "^lsi:" /etc/hosts.deny

  if [ $? -eq 0 ];then
    sed -i -e 's/^lsi:.*//g' /etc/hosts.deny
  fi

  echo "Adding lsi to /etc/hosts.deny"
  echo "lsi: ALL" >> /etc/hosts.deny
fi

echo
echo "Installation complete, please review installation output for"
echo "errors. Please start/restart xinetd for the changes to take effect."
