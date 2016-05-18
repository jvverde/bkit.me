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

sub saveData{
  my ($file,$data) = @_;
  open my $fhv, ">$file" or (warn "Cannot save info to $file" and return undef);
  print $fhv $data; 
  close $fhv;
  return $data;
} 

my $cd = dirname abs_path $0;
my $sysDir = "$cd\\sysInfo";
-d $sysDir or mkdir $sysDir;
my $wmiFile = "$sysDir\\wmi.info"; 
my $sysFile = "$sysDir\\sys.info";

my $perl = which 'perl';
my $rsync = "$cd\\cygwin\\rsync.exe";
$rsync = which 'rsync' or die "Cannot find rsync $rsync" unless -e $rsync;


my $osversion = [Win32::GetOSVersion()];
my $sysInfo = {
  version => $osversion
  ,displayName => Win32::GetOSDisplayName()
  ,arch => Win32::GetArchName()
  ,chip => Win32::GetChipName()
  ,oem => Win32::GetOEMCP()
  ,nodeName => Win32::NodeName() || '_'
  ,domainName => Win32::DomainName() || '_'
  ,product => Win32::GetProductInfo($osversion->[1], $osversion->[2], $osversion->[5], $osversion->[6])
  ,osName => ''.Win32::GetOSName() .''
};

saveData $sysFile, $json->encode($sysInfo);
 
my $wmi = qx|$perl $cd\\getinfo.pl|;
die "Cannot launch $cd\\getinfo.pl:$!" unless defined $wmi;
die "Error while running $cd\\getinfo.pl:$wmi($?)\n" if $?;

saveData $wmiFile, $wmi;

my $wmiInfo = $json->decode($wmi) or die "Cannot decode json data saved in $wmiFile";
defined $wmiInfo->{Win32_ComputerSystemProduct} or die "Win32_ComputerSystemProduct not defined in $wmiInfo";
defined $wmiInfo->{Win32_ComputerSystemProduct}->{UUID} or die "Win32_ComputerSystemProduct not defined in $wmiInfo";

my $uuid = $wmiInfo->{Win32_ComputerSystemProduct}->{UUID} || '_';
my $name = $sysInfo->{nodeName};
my $domain = $sysInfo->{domainName}; 

#open my $handler, "|-"
  print qq|${rsync} -rltvvhR --chmod=ugo=rwX --inplace --stats|
  .qq| ${sysDir}\\.\\ admin\@10.1.2.6::bkit.me/${uuid}/${domain}/${name}|
  .qq| 2>${sysDir}\\err.txt >${sysDir}\\logs.txt|;
#print $handler "4dm1n\n\n";

