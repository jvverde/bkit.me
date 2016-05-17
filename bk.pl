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
my $cd = dirname abs_path $0;

my $dir = shift or die 'You must specify a directory';
my ($drive,$path) = ($dir =~ /^([a-z]):(.*)$/i) or die 'You must include drive letter in directory';
$drive = uc $drive;
$path =~ s/^[^\\]/\\$&/;

sub drive2DevId{
  my $drive = shift;
  my $lsv = qx|$perl $cd\\lsv.pl| or die "Error code $? ($!)";
  my $volumes = $json->decode($lsv) or die "Not json:$!";
  my $letters = $volumes->{DriveLetter} or return undef;
  my ($index) = grep {defined $letters->[$_] and uc $letters->[$_] eq "$drive:"} 0..$#{$letters};
  print Dumper $volumes->{DeviceID};
  print $index;
  my $devId = $volumes->{DeviceID}->[$index] if defined $index and defined $volumes->{DeviceID};
  return $devId; 
}

sub getShadowCopies{
  my $volume = shift;
  my $lsh = qx|$perl $cd\\lsh.pl| or die "Error code $? ($!)";
  my $shadows = $json->decode($lsh) or die "Not json:$!";
  #print Dumper $shadows;
  my $volumes = $shadows->{VolumeName} or return undef;
  #print Dumper $volumes;
  my (@indexes) = grep {defined $volumes->[$_] and $volumes->[$_] eq $volume} 0..$#{$volumes};
  # print Dumper $volumes->{DeviceID};
  return undef unless defined $shadows->{InstallDate} and defined $shadows->{DeviceObject};
  my %dates = map {$shadows->{InstallDate}->[$_] => $shadows->{DeviceObject}->[$_]} @indexes;
  #print Dumper \%dates;
  return \%dates;
}

-d "$drive:/.bkit.me" or mkdir "$drive:/.bkit.me";
my $devId = drive2DevId $drive or die "Cannot get DeviceId for drive $drive:$!";
my $vss = getShadowCopies $devId;
my $last = $vss->{pop @{[sort keys %$vss]}};
print $last;
print Dumper $vss;
#print Dumper $volumes;
#my $result = system qq|$perl $cd\\csc.pl $drive| and die "Cannot create shadow copy, Error value: $? ($!)";

print 'fim';