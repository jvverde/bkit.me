use strict;
use warnings;
use Cwd qw|abs_path|;
use File::Basename qw |dirname|;
use File::Which;
use JSON;
use Data::Dumper;
use Win32;

($\,$,) = ("\n","\t");
my $json = (new JSON)->utf8->pretty;

my $perl = which 'perl';
my $cd = dirname abs_path $0;
my $rsync = "$cd\\cygwin\\rsync.exe";
$rsync = which 'rsync' or die "Cannot find rsync $rsync" unless -e $rsync;

my $osversion = [Win32::GetOSVersion()];
my $sysInfo = {
  version => $osversion
  ,displayName => Win32::GetOSDisplayName()
  ,arch => Win32::GetArchName()
  ,chip => Win32::GetChipName()
  ,oem => Win32::GetOEMCP()
  ,nodeName => Win32::NodeName()
  ,domainName => Win32::DomainName()
  ,product => Win32::GetProductInfo($osversion->[1], $osversion->[2], $osversion->[5], $osversion->[6])
  ,osName => ''.Win32::GetOSName() .''
};

my $sysDir = "$cd\\sysInfo";
-d $sysDir or mkdir $sysDir;
my $wmiFile = "$sysDir\\wmi.info"; 
my $sysFile = "$sysDir\\sys.info"; 
system qq|$perl $cd\\getinfo.pl > $wmiFile| and die "Error while getting wmi info:$? ($!)";
open my $h, ">$sysFile" or die "Cannot open $sysFile: $!"; 
print $h $json->encode($sysInfo);
close $h;
exit;

my $node = $sysInfo->{nodeName};
# open my $handler, "|-"
  # ,qq|${rsync} -rltvvvhR --chmod=ugo=rwX --inplace --stats|
  # .qq| /proc/sys/Device/${shcN}/${bkitDir}/../.${path} me\@10.1.2.6::bkit.me/${drive}/|
  # .qq| 2>${bkit}\\logs\\err.txt >${bkit}\\logs\\logs.txt|;
# print $handler "me\n\n";

