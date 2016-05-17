use strict;
use warnings;
use Cwd qw|abs_path|;
use File::Basename qw |dirname|;
use File::Which;
use JSON;
use Data::Dumper;

$\ = "\n";
$, = "\t";
my $json = (new JSON)->utf8->pretty;
my $perl = which 'perl';
my $vssadmin = which 'vssadmin';
my $cd = dirname abs_path $0;
my $rsync = "$cd\\cygwin\\rsync.exe";
$rsync = which 'rsync' or die "Cannot find rsync $rsync" unless -e $rsync;
-d "$cd\\logs" or mkdir "$cd\\logs";

my $dir = shift or die 'You must specify a directory';
my ($drive,$path) = ($dir =~ /^([a-z]):(.*)$/i) or die 'You must include drive letter in directory';
$drive = uc $drive;
$path =~ s/[\\]/\//g;    #dos->unix 
$path =~ s/^[^\/]?/\/$&/; #garante um slash no inicio do path

sub drive2DevId{
  my $drive = shift;
  my $lsv = qx|$perl $cd\\lsv.pl| or die "Error code $? ($!)";
  my $volumes = $json->decode($lsv) or die "Not json:$!";
  my $letters = $volumes->{DriveLetter} or return undef;
  my ($index) = grep {defined $letters->[$_] and uc $letters->[$_] eq "$drive:"} 0..$#{$letters};
  my $devId = $volumes->{DeviceID}->[$index] if defined $index and defined $volumes->{DeviceID};
  return $devId; 
}

sub getShadowCopies{
  my $volume = shift;
  my $lsh = qx|$perl $cd\\lsh.pl| or die "Error code $? ($!)";
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

-d "$drive:/.bkit.me" or mkdir "$drive:/.bkit.me";
my $devId = drive2DevId $drive or die "Cannot get DeviceId for drive $drive:$!";
# my $vss = getShadowCopies $devId;
# my $prev = $vss->{pop @{[sort keys %$vss]}} if defined $vss and scalar %$vss;
#print $prev;
#print Dumper $vss;
#print Dumper $volumes;
my $result = system qq|$perl $cd\\csc.pl $drive| and die "Cannot create shadow copy, Error value: $? ($!)";
my $cvss = getShadowCopies $devId;
die 'Cannot get shadow Copies' unless defined $cvss and scalar %$cvss;
my $lastVssKey = pop @{[sort keys %$cvss]};
my $cur = $cvss->{$lastVssKey}->{volume};
if (defined $cur){
  my ($shcN) = $cur =~ /(HarddiskVolumeShadowCopy\d+)/;
  #my $backup = qx|${rsync} -rltvvhR --chmod=ugo=rwX --inplace --delete-after /proc/sys/Device/${shcN}/.bkit.me/../.${path} me\@10.1.2.6::meatfeup/${drive}/ 2>${cd}\\logs\\err.txt >${cd}\\logs\\logs.txt < ${cd}\\conf\\secret.txt|;
  open my $handler, "|-"
    ,qq|${rsync} -rltvvhR --chmod=ugo=rwX --inplace --delete-after --stats /proc/sys/Device/${shcN}/.bkit.me/../.${path}|
    .qq| me\@10.1.2.6::meatfeup/${drive}/ 2>${cd}\\logs\\err.txt >${cd}\\logs\\logs.txt|;
  print $handler "me\n";

  #print $backup;
}

END {
  if (defined $lastVssKey){
    my $last = $cvss->{$lastVssKey}->{id};
    print qx|$vssadmin Delete Shadows /Shadow=$last /Quiet|;
  }
}
