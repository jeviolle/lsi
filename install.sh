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

echo
echo "Installing to $prefix ..."
echo
mkdir -p $prefix
cp -Rv $CWD/src/* $prefix

echo 
echo "If there were no errors, you can now run $prefix/bin/lsi.pl"

# check prerequisites for the server
# TODO
