#!/usr/bin/perl
#
# lsi.pl
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

#-------perldoc--------#
=pod

=head1 NAME

lsi.pl - report system information

=head1 SYNOPSIS

lsi.pl -[a|bcdhHmnpP] -[x|s]

  Help:
    -?             displays this menu      

  Collection Options:
    -a             all system information
    -b             bios information
    -c             cpu information
    -d             disk information
    -h             host information
    -H             hba information
    -m             memory information
    -n             network information
    -p             partition information
    -P             package information

  Output Options (pick only one):
    -x             prints the output in XML format (XML)
    -s             prints the output in spreadsheet format (CSV)

=head1 DESCRIPTION

lsi uses various linux tools and subsets to determine multiple aspects of system information. The 
results should be fairly accurate depending on the type of hardware available and the information 
returned from the existing tools on the system.

=cut

# modules
use strict qw(subs vars);
use warnings;
use Sys::Hostname;
use Getopt::Std;
use Pod::Usage;

# force path
$ENV{'PATH'} = '/sbin:/usr/sbin:/usr/local/sbin:/bin:/usr/bin:/usr/local/bin';

# check os from perl settings (linux required)
if ( $^O ne "linux" ) {
    die "Linux is required in order to run this application!\n";
}

# vars
my %opts;
my %HoH;
my $host = hostname;

# get command line options and display usage for no, help, or bad options
getopts('abcdhHmnpP?xs' => \%opts) or die pod2usage(3);

# must select 1 data option and output option
# can't select 2 data options
pod2usage(2) if (!%opts) or defined($opts{'?'}) or (scalar(keys %opts) == 1 and (defined($opts{'x'}) or defined($opts{'s'}))) or (defined($opts{'x'}) and defined($opts{'s'})) or (!defined($opts{'x'}) and !defined($opts{'s'}));

# gather system, svctag/hostid, bios/firmware/date
sub biosinfo {
    my $hostid=`dmidecode -s system-serial-number`;
    my $biosproduct=`dmidecode -s system-product-name`;
    my $biosrev=`dmidecode -s bios-version`;
    my $biosdate=`dmidecode -s bios-release-date`;

    chomp($hostid,$biosproduct,$biosrev,$biosdate);

    $HoH{'bios'}{'hostid'} = $hostid;
    $HoH{'bios'}{'product'} = $biosproduct;
    $HoH{'bios'}{'revision'} = $biosrev;
    $HoH{'bios'}{'date'} = $biosdate;
}

# memory
sub meminfo {
    my $mbperslot=`dmidecode -t 5 | grep "Maximum Total Memory Size" | awk '{print \$5}'`;
    my $memslots=`dmidecode -t 5 | grep "Associated Memory Slots" | awk '{print \$4}'`;
    my $maxmem;
    my @slotinfo;
    my $count = 0;
    my $any = 0;

    # handle blank values
    if ( ($mbperslot eq "") || ($memslots eq "") ) {
        $maxmem=0;
    } else {
        $maxmem=$mbperslot * $memslots;
    }

    my $memory;
    open(MEMINFO, "/proc/meminfo");
        while (<MEMINFO>) {
            if ( /^MemTotal:\s+(\d+\s+\w+)/ ) {
                $memory=uc($1);
            }
        }
    close(MEMINFO);

    # parse dmidecode memory slot information
    # shane style 
    open(DMI, "dmidecode -t 17|") or die "Failed to run dmidecode: $!\n";

    # set default count
    $count=1;

    # read the ouput of the command
    while (defined (my $line = <DMI>)) {

        # remove newlines
        chomp $line;

        # match anything from Package to the end of that packages
        # output
        my $match = ( $line =~ /Array Handle/ .. $line =~ /^$/ );

        # if match exists and it doesn't equal the end of the file
        if ( $match && $match !~ /E0/ ) {

            #################
            # FIELDS NEEDED #
            #################
            # size
            # locator
            # speed
            # form factor
            
            # check the line for the required field
            if ( $line =~ /\cI(Array Handle|Size|Locator|Speed|Form Factor):\s*(.*)$/ ) {
                my ($key, $value) = ($1, $2);
                if ( $key =~ /Array Handle/ ) { 
                    $count++;
                } else {
                    # Locator,Size,Speed,Form Factor
                    if ( $key =~ /Form Factor/ ) { $key = "form"; }
                    $HoH{'memory'}{$count}{lc($key)} = $value;
                }
            }
        } 
    }
    close(DMI);

    chomp($mbperslot);
    chomp($memslots);
    $HoH{'memory'}{'mbperslot'} = $mbperslot;
    $HoH{'memory'}{'slots'} = $memslots;
    $HoH{'memory'}{'maximum'} = $maxmem;
    $HoH{'memory'}{'installed'} = $memory;
}

# function for parsing cpuinfo
sub cpuinfo {
    my $cpucount=`grep "^processor" /proc/cpuinfo | wc -l`;
    my $count=0;
    my @cpu;

    chomp($cpucount);
    $HoH{'cpus'}{'count'} = $cpucount;

    open(CPUINFO, "cat /proc/cpuinfo|");
    while (<CPUINFO>) {
        if ( /processor/ ) { 
            $count++; 
        }

        if ( /(vendor_id|model name|cpu MHz|cache size)\s+:\s+(.+)/ ) { 
            my ( $key, $value ) = ($1, $2);
            $key =~ s/\s/_/;
            $HoH{'cpus'}{$count}{$key} = $value;
        }
    }
    close(CPUINFO);
}

# gather vendor, version, kernel, numa info
# hopefully the lsb_release command on red-hack provides the same
# information as normal linux
sub hostinfo {
    my $vendor=`lsb_release -i | awk '{print \$3}'`;
    my $version=`lsb_release -r | awk '{print \$2}'`;
    my $kernel=`uname -r`;
    my $arch=`uname -m`;
    my $numa;

    system("numactl -s > /dev/null 2>&1");
    if ( ($? >> 8) == 0 ) { 
        $numa="true";
    } else {
        $numa="false";
    }

    chomp($host,$vendor,$version,$kernel,$arch,$numa);

    $HoH{'host'}{'vendor'} = $vendor;
    $HoH{'host'}{'version'} = $version;
    $HoH{'host'}{'kernel'} = $kernel;
    $HoH{'host'}{'arch'} = $arch;
    $HoH{'host'}{'numa'} = $numa;
}

# function to gather disk, model, interface (scsi,sas,etc), size
sub diskinfo {

    # gather storage and disk information
    my $diskcount=`fdisk -l 2>/dev/null | grep -v mapper | grep "^Disk /" | wc -l`;

    chomp($diskcount);
    $HoH{'disks'}{'count'} = $diskcount;

    my ($model, $disk, $size, $interface, $count);
    open(FDISK, "fdisk -l 2> /dev/null |") or die "Failed to execute fdisk: $!\n";
        while (<FDISK>) {
            if (/(\/\w+\/\w+)\:\s+(\d+.+\w+)\,/) {
                $disk = $1;
                $size = $2;
                $count += 1;

                open(HDPARM, "hdparm -i $disk 2> /dev/null |") or die "Failed to execute hdparm: $!\n";
                    while (<HDPARM>) {
                        if (/Model=(.+?)\,/) {
                            $model = $1;
                        }
                    }
                close(HDPARM);

                my $interface;
                if ( -e '/sbin/udevadm' ) {
                    open(IFACE, "udevadm info -q symlink -n $disk|") or die "Failed to execute udevinfo: $!\n";
                        while (<IFACE>) {
                            if (/disk\/by-path\/\w+-\d+:\d+:\d+\.\d+-(\w+)-\d+:\d+/) {
                                $interface = $1;
                            }
                        }
                    close(IFACE);
                } else {
                    open(IFACE, "udevinfo -q symlink -n $disk|") or die "Failed to execute udevinfo: $!\n";
                        while (<IFACE>) {
                            if (/disk\/by-path\/\w+-\d+:\d+:\d+\.\d+-(\w+)-\d+:\d+/) {
                                $interface = $1;
                            }
                        }
                    close(IFACE);
                }

            $HoH{'disks'}{$count}{'device'} = $disk;
            $HoH{'disks'}{$count}{'model'} = $model;
            $HoH{'disks'}{$count}{'interface'} = $interface;
            $HoH{'disks'}{$count}{'size'} = $size;
            }
        }
    close(FDISK);
}

# gather partition information
sub partinfo {
    my $partcount=`mount | grep "^/" | wc -l`;
    my $count;

    chomp($partcount);
    $HoH{'partitions'}{'count'} = $partcount;

    open(PART, "mount |") or die "Failed to execute 'mount'! $!\n";
        while (<PART>) {
            if ( /^(\/.+) on (\/.*) type (.+) (.+)/ ) {
                $count += 1;
                $HoH{'partitions'}{$count}{'device'} = $1;
                $HoH{'partitions'}{$count}{'mount'} = $2;
                $HoH{'partitions'}{$count}{'filesystem'} = $3;
                $HoH{'partitions'}{$count}{'options'} = $4;
            }
        }

    close(PART);
}

# get all available intefaces' information
sub netinfo {

    my ($nic, $ip, $mask, $mac, $count);

    open(NETDEV, "/proc/net/dev");
        while (<NETDEV>) {
            if (/(\w+\d+):/) {
                if ((defined($1)) && ($1 !~ /sit\d+/)) {
                    $nic = $1;
                    open(IFCONFIG, "ifconfig $nic \| tr [:space:] \" \"|");
                        while (<IFCONFIG>) {
                            if ( /HWaddr (.+?)\s+(?:inet addr\:(\d+\.\d+\.\d+\.\d+))?(?:.+?Mask\:(\d+\.\d+\.\d+\.\d+))?/ ) {
                                $count += 1;
                                ($ip,$mask,$mac) = ($2,$3,$1); 
                            }
                        }
                    close(IFCONFIG);

                    $HoH{'nics'}{$count}{'device'} = $nic;
                    $HoH{'nics'}{$count}{'ip'} = $ip;
                    $HoH{'nics'}{$count}{'netmask'} = $mask;
                    $HoH{'nics'}{$count}{'mac'} = $mac;
                }
            }
        }
    close(NETDEV);

    $HoH{'nics'}{'count'} = $count;
}

# Get Fibre and HBA list from lspci
# Example: QLogic Corp. SP202-based 2Gb Fibre Channel to PCI-X HBA (rev 03)
sub hbainfo {
    my @lspci=`lspci | grep -i -e fib -e hba`;
    my $count;

    foreach (@lspci) {
        if (/.+?:\s+(.+)/) {
            $count += 1;
            $HoH{'hbas'}{$count}{'description'} = $1;
        }
    }

    $HoH{'hbas'}{'count'} = $count;
}

# parse package manager output
sub rpmparse {

    # scalars and such
    my $count = 0;
    my $rpmquery='rpm -qa --queryformat "Package: %{NAME}\nVersion: %{VERSION}\nRelease: %{RELEASE}\nArchitecture: %{ARCH}\nMaintainer: %{VENDOR}\nDescription: %{SUMMARY}\nInstallDate: %{INSTALLTIME:date}\n\n"';

    # hash to convert month names to numbers
    my %month2num = qw { 
       jan 01  feb 02  mar 03  apr 04  may 05  jun 06
       jul 07  aug 08  sep 09  oct 10  nov 11  dec 12
    };

    # shane style 
    open(PKGS, "$rpmquery|") or die "Failed to run $rpmquery: $!\n";

    # read the ouput of the command
    while (defined (my $line = <PKGS>)) {

        # remove newlines
        chomp $line;

        # match anything from Package to the end of that packages
        # output
        my $match = ( $line =~ /Package:/ .. $line =~ /^$/ );

        # if match exists and it doesn't equal the end of the file
        if ( $match && $match !~ /E0/ ) {

            #################
            # FIELDS NEEDED #
            #################
            # name (Package)
            # arch (Architecture)
            # vendor (Maintainer)
            # summary (Description)
            # version (Version)
            # release (Release)
            # installdate (INSTDATE)
            
            # check the line for the required field
            if ( $line =~ /^(Package|Version|Release|Architecture|Maintainer|Description|InstallDate):\s+(.*)$/ ) {
                my ($key, $value) = (lc($1), $2);
                if ( $key =~ /package/ ) { 
                    $count++;
                    $HoH{'packages'}{$count}{$key} = $value;
                } elsif ( $key =~ /installdate/ ) {
                    my ($dow, $day, $month, $year, $time) = split(" ",$value);
                    my $mon = $month2num{ lc substr($month, 0, 3) };
                    $HoH{'packages'}{$count}{$key} = "$year-$mon-$day $time";
                } else {
                    $HoH{'packages'}{$count}{$key} = $value;
                }
            }
        }
    }
    close(PKGS);
}

sub dpkgparse {
    # scalars and such
    my $count = 0;
    my $pkglist="/var/lib/dpkg/info";
    my $dpkgquery="dpkg-query -W -f='Package: \${Package}\nVersion: \${Version}\nArchitecture: \${Architecture}\nMaintainer: \${Maintainer}\nDescription: \${Description}\nStatus: \${Status}\n\n'";

    # shane style 
    open(PKGS, "$dpkgquery|") or die "Failed to run $dpkgquery: $!\n";

    # read the ouput of the command
    while (defined (my $line = <PKGS>)) {

        # remove newlines
        chomp $line;

        # match anything from Package to the end of that packages
        # output
        my $match = ( $line =~ /Package:/ .. $line =~ /^$/ );

        # if match exists and it doesn't equal the end of the file
        if ( $match && $match !~ /E0/ ) {

            #################
            # FIELDS NEEDED #
            #################
            # name (Package)
            # arch (Architecture)
            # vendor (Maintainer)
            # summary (Description)
            # version (Version)
            #----------------------------
            # version (VERSION | cut -f1 -d\,)
            # release (VERSION | cut -f2 -d\= )
            # installdate (INSTDATE)
            # status (Status)
            
            # check the line for the required field
            if ( $line =~ /^(Package|Version|Architecture|Maintainer|Description|Status):\s+(.*)$/ ) {
                my ($key, $value) = (lc($1), $2);
                if ( $key =~ /package/ ) { 
                    $count++;
                    $HoH{'packages'}{$count}{$key} = $value;
                    chomp($HoH{'packages'}{"installdate"}=`ls -l --time-style=long-iso $pkglist/$value.list | awk '{print \$6 " " \$7}'`);
                } elsif ( $key =~ /version/ ) {
                    my ($ver, $rel) = split(/\-/, $value);                        
                    $HoH{'packages'}{$count}{"version"} = $ver;
                    $HoH{'packages'}{$count}{"release"} = $rel;
                } else {
                    $HoH{'packages'}{$count}{$key} = $value;
                }
            }
        }
    }
    close(PKGS);
}

# determine which package managers available based on which $PATH
sub pkginfo {
    my $rc;

    # try and detect package managers
    system("which rpm > /dev/null 2>&1");
    my $rpm = $? >> 8;

    system("which dpkg-query > /dev/null 2>&1");
    my $dpkg = $? >> 8;

    if ( $rpm == 0 ) {
        my $packagecount=`rpm -qa | wc -l`;
        rpmparse;
    } elsif ( $dpkg == 0 ) {
        my $packagecount=0;
        dpkgparse;
    }
}

# run subroutines
sub main($) {
    my $infoArg = $_[0];

    # merge the gathered hash data into a larger Hash of Hashes
    if ( $infoArg eq 'h' ) { hostinfo;}
    if ( $infoArg eq 'b' ) { biosinfo;}
    if ( $infoArg eq 'm' ) { meminfo; }
    if ( $infoArg eq 'c' ) { cpuinfo; }
    if ( $infoArg eq 'd' ) { diskinfo;}
    if ( $infoArg eq 'p' ) { partinfo;}
    if ( $infoArg eq 'n' ) { netinfo; }
    if ( $infoArg eq 'H' ) { hbainfo; }
    if ( $infoArg eq 'P' ) { pkginfo; }
}

# sanitize data for output
# &lt;    <   less than
# &gt;    >   greater than
# &amp;   &   ampersand 
# &apos;  '   apostrophe
# &quot;  "   quotation mark
sub sanitizeData($$) {
    my $data = $_[0];
    my $format = $_[1];

    if ( !defined($data) ) { $data = "empty"; }
    if ( ($data eq " ") || ($data eq "") ) { $data = "empty"; }

    if ( $format eq "XML" ) {
        $data =~ s/\</\&lt\;/g;
        $data =~ s/\>/\&gt\;/g;
        $data =~ s/\'/\&apos\;/g;
        $data =~ s/\"/\&quot\;/g;
    } elsif ( $format eq "CSV" ) {
        $data =~ s/\"//g;
    }

    # return data and fix blank data
    return $data;
}

# expected and defined hash of hashes depth is 3
sub printXML() {
    my $format = "XML";

    print "<?xml version=\"1.0\" encoding='UTF-8'?>\n";
    print '<systeminfo host="' . $host . '">' . "\n";
    foreach my $key (sort keys %HoH) {
    print "  <$key>\n";
    if (ref($HoH{$key}) eq "HASH") {
        foreach my $key2 (sort keys %{$HoH{$key}}) {
            # if the key equal count then print the instance number
            if ($key2 =~ /\d+/) {
                if ($key ne "memory") { 
                    my $tag = substr($key, 0, -1);
                    print "    <$tag>\n";
                } elsif ($key eq "memory") {
                    print "    <dimm>\n";
                }
            }
            # check if the key is a hash 
            if (ref($HoH{$key}{$key2}) eq "HASH") {
                # loop through all the hash elements
                foreach my $key3 (sort keys %{$HoH{$key}{$key2}}) {
                    # check if the element is a hash
                    if (ref($HoH{$key}{$key2}{$key3}) ne "HASH") {
                        # handle undefined element output
                        print "      <$key3>" . sanitizeData($HoH{$key}{$key2}{$key3},$format) . "</$key3>\n";
                    }
                }
            } else {
                # if the element wasn't a hash we expect a scalar 
                # so print
                print "    <$key2>" . sanitizeData($HoH{$key}{$key2},$format) . "</$key2>\n";
            }
            # close the tag for the instance number
            if ($key2 =~ /\d+/) {
                if ($key ne "memory") { 
                    my $tag = substr($key, 0, -1);
                    print "    </$tag>\n";
                } elsif ($key eq "memory") {
                    print "    </dimm>\n";
                }
            }
        }
    } 
    # print the main hash key
    print "  </$key>\n";
    }
    print "</systeminfo>\n";
}    


# return the data is csv format
sub printCSV() {
    my $format = "CSV";

    # print csv header
    print '"host",';

    foreach my $yek ( sort keys %HoH ) {
        foreach my $yek2 ( sort keys %{$HoH{$yek}} ) {
            if ($yek2 =~ /\d+/) {
                foreach my $yek3 ( sort keys %{$HoH{$yek}{$yek2}} ) {
                    print '"' . $yek . "_" . $yek3 . '",';
                }   
            } else {
                print '"' . $yek . "_" . $yek2 . '",';
            }
        }
    }

    print "\n";
    print '"' . $host . '",';

    foreach my $key (sort keys %HoH) {
    if (ref($HoH{$key}) eq "HASH") {
        foreach my $key2 (sort keys %{$HoH{$key}}) {
            # check if the key is a hash 
            if (ref($HoH{$key}{$key2}) eq "HASH") {
                # loop through all the hash elements
                foreach my $key3 (sort keys %{$HoH{$key}{$key2}}) {
                    # check if the element is a hash
                    if (ref($HoH{$key}{$key2}{$key3}) ne "HASH") {
                        # handle undefined element output
                        print '"' . sanitizeData($HoH{$key}{$key2}{$key3},$format) . '",';
                    }
                }
            } else {
                # if the element wasn't a hash we expect a scalar 
                # so print
                print '"' . sanitizeData($HoH{$key}{$key2},$format) . '",';
            }
        }
    } 
    }
    print "\n";
}

# determine what to run based on user options
if ( defined($opts{'a'}) ) {
    # run all 
    my @allArgs = ('h','b','m','c','d','p','n','H','P');
    foreach my $key ( @allArgs ) {
        main($key);
    }

} else { 
    foreach my $key (sort keys %opts) {
        #run only the user specific options
        main($key);
    }
}

# determine how to ouput the results
if ( defined($opts{'x'}) ) {
    printXML;
} else {
    printCSV;
}

1;
