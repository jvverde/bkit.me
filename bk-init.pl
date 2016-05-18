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

print Win32::GetOSName();
my ($string, $major, $minor, $build, $id, $spmajor, $spminor, $suitemask, $producttype) = Win32::GetOSVersion();
print $string, $major, $minor, $build, $id, $spmajor, $spminor, $suitemask, $producttype;
print Win32::GetOSDisplayName();
print Win32::GetArchName();
print Win32::GetChipName();
print Win32::GetOEMCP();
print Win32::NodeName();
print Win32::DomainName();
print Win32::GetProductInfo($major, $minor, $spmajor, $spminor);



exit;

sub saveData{
  my ($file,$data) = @_;
  open my $fhv, ">$file" or (warn "Cannot save info to $file" and return undef);
  print $fhv $data; 
  close $fhv;
  return $data;
} 
sub drive2DevId{
  my ($drive,$lsv) = @_;
  my $volumes = $json->decode($lsv) or die "Not json:$!";
  my ($volume) = grep{defined $_->{DriveLetter} and uc $_->{DriveLetter} eq "$drive:"} @$volumes;
  return $volume->{DeviceID};
}
sub getShadowCopies{
  my ($volume,$lsh) = @_;
  my $shadows = $json->decode($lsh) or die "Not json:$!";
  return undef unless defined $shadows->{InstallDate} and defined $shadows->{DeviceObject} and defined $shadows->{VolumeName};
  my $volumes = $shadows->{VolumeName};
  return {map {
    $shadows->{InstallDate}->[$_] => {
      volume => $shadows->{DeviceObject}->[$_]
      ,id => $shadows->{ID}->[$_]
    }
  } grep {defined $volumes->[$_] and $volumes->[$_] eq $volume} 0..$#{$volumes}};
}


my $perl = which 'perl';
my $vssadmin = which 'vssadmin';
my $cd = dirname abs_path $0;
my $rsync = "$cd\\cygwin\\rsync.exe";
$rsync = which 'rsync' or die "Cannot find rsync $rsync" unless -e $rsync;
my $subinacl = (which 'subinacl') || "$cd\\3rd-party\\subinacl\\subinacl.exe";

my $dir = shift or die 'You must specify a directory';
my ($drive,$path) = ($dir =~ /^([a-z]):(.*)$/i) or die 'You must include drive letter in directory';
$drive = uc $drive;
$path =~ s/^[^\\]?/\\$&/; #garante um backslash no inicio do path
$path =~ s/[\\]/\//g;    #dos->unix 

my $bkitDir = '.bkit.me';
my $bkit = "$drive:\\$bkitDir";
-d $bkit or mkdir $bkit;
my ($logs,$perms,$vols) = map {-d $_ or mkdir $_; $_} map {"$bkit\\$_"} qw(logs perms vols);

my $acls = "$perms\\acls.txt";

my $mtime = (stat $acls)[9] if -e $acls;
$mtime //= 0;
print qx|$subinacl /noverbose /output=$acls /subdirectories $drive:\\| 
  if -e $subinacl and (time - $mtime) > 3600*24*8;#8 day

my $lsv = qx|$perl $cd\\getvol.pl| or die "Error code $? ($!)";
saveData "$vols\\volumes.txt", $lsv;

my $devId = drive2DevId $drive, $lsv or die "Cannot get DeviceId for drive $drive:$!";
system qq|$perl $cd\\csc.pl $drive| and die "Cannot create shadow copy, Error value: $? ($!)";
my $lsh = qx|$perl $cd\\lsh.pl| or die "Error code $? ($!)";
my $cvss = getShadowCopies $devId, $lsh;
die 'Cannot get shadow Copies' unless defined $cvss and scalar %$cvss;
my $lastVssKey = pop @{[sort keys %$cvss]};
my $cur = $cvss->{$lastVssKey}->{volume};
if (defined $cur){
  my ($shcN) = $cur =~ /(HarddiskVolumeShadowCopy\d+)/;
  open my $handler, "|-"
    ,qq|${rsync} -rltvvvhR --chmod=ugo=rwX --inplace --delete-after --stats --exclude-from=$cd\\conf\\excludes.txt|
    .qq| /proc/sys/Device/${shcN}/${bkitDir}/../.${path} me\@10.1.2.6::meatfeup/${drive}/|
    .qq| 2>${bkit}\\logs\\err.txt >${bkit}\\logs\\logs.txt|;
  print $handler "me\n\n";
}

END {
  if (defined $lastVssKey){
    my $last = $cvss->{$lastVssKey}->{id};
    print qx|$vssadmin Delete Shadows /Shadow=$last /Quiet|;
  }
}
