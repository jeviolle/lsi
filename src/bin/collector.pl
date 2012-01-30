#!/usr/bin/perl
#
# collector.pl - script to gather data from the lsi clients
#                read host,port csv file for processing
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

use warnings;
use strict;
use IO::Socket;
use File::Basename;
use POSIX qw/strftime/;

# initialize host and port
my $clientFile = dirname(__FILE__) . "/../etc/clients.conf";
my $outputDir = dirname(__FILE__) . "/../var/www/data";
my $datetime = strftime('%Y%m%d%H%M', localtime);
my @clients;
my $line;

open(FH, '<', $clientFile ) or die "Failed to open: $clientFile $!\n";
    @clients = <FH>;
close(FH);

foreach my $client (@clients) {
  my ($host, $port) = split(',', $client);
  chomp($host, $port);

  # if the host data directory doesn't exist, create it
  if ( ! -d "$ouputDir/$host" ) {
      `mkdir "$outputDir/$host"`;
  }

  # create the socket, connect to the port
  my $remote = IO::Socket::INET->new( Proto => "tcp", PeerAddr => "$host", PeerPort => "$port" ) or die "Failed to connect to $host:$port - $!\n";

  open(OF, '>', "$outputDir/$host/$datetime.xml") or die "Failed to open $outputDir/$host/$datetime.xml $!\n";
    while ($line = <$remote>) {
        print OF "$line";
    }
  close(OF);
}

