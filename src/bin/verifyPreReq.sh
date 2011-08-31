#!/bin/sh
#
# verifyPreReq.sh - installer script for lsi
#
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

# set path to the users path then append standard locations
# to increase the chance the binaries are located
PATH=/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin
export PATH

# get os type
OS=`uname -s | tr [A-Z] [a-z]`

# attempt to find required binaries and prompt if missing
CMDS="perl grep egrep sed awk wc head tail tr cut ifconfig uname hostname cat xmllint dmidecode lsb_release numactl hdparm fdisk udevinfo lspci tee"

# exit on error
exitOnError() {
    echo 
    echo "Missing required program location. See error above and verify"
    echo "that it is installed and in your PATH"
    echo
    echo "PATH=$PATH"
    exit 1
}

# iterate through the commands and grab
# their paths for inclusion
find_commands () {
  if [ -z "$1" ]
  then
    echo "Incorrect argument for find_commands()" 
    exit 1
  else
    for cmd in $1
    do

      which $cmd > /dev/null 2>&1

      # if the command can not be located in $PATH then warn
      if [ "$?" -ne 0 ]
      then
        echo "Checking for $cmd ... not found"
        exitOnError
      else 
        echo "Checking for $cmd ... found"
      fi
    done
  fi
}

# BEGIN PROGRAM
echo "###########################################"
echo "Starting preinstallation requirements check"
echo "###########################################"

# get additional binary paths depending on 
# the operating system type
case "$OS" in
   'linux' )
            find_commands "$CMDS"

            which rpm > /dev/null 2>&1
            RPMRC="$?"
            which dpkg-query > /dev/null 2>&1
            DPKGRC="$?"

            if [ "$RPMRC" -ne 0 -a "$DPKGRC" -ne 0 ];then
                echo "Checking for rpm|dpkg-query ... not found"
                exitOnError
            else
                echo "Checking for rpm|dpkg-query ... found"
                if [ "$RPMRC" -eq 0 ];then
                    rpm -q xinetd > /dev/null 2>&1
                    if [ "$?" = 0 ];then
                      echo "Checking for xinetd ... found"
                    else
                      echo "Checking for xinetd ... not found"
                      exitOnError
                    fi
                fi

                if [ "$DPKGRC" -eq 0 ];then
                    dpkg-query -l xinetd > /dev/null 2>&1
                    if [ "$?" = 0 ];then
                      echo "Checking for xinetd ... found"
                    else
                      echo "Checking for xinetd ... not found"
                      exitOnError
                    fi
                fi
            fi

            ;;
         * )
            echo "......................................................"
            echo "Install failed! Unable to match Operating System : $OS"
            echo "Please view the README for requirements."

            exit 1 
            ;;
esac
