use strict;
use warnings;
use Cwd qw|abs_path|;
use File::Basename qw |dirname|;
use File::Which;

$\ = "\n";
$, = "\t";
my $dir = shift or die 'You must specify a directory';
my ($drive,$path) = ($dir =~ /^([a-z]):(.*)$/i) or die 'You must include drive letter in directory';
$drive = uc $drive;
$path =~ s/^[^\\]/\\$&/;
my $perl = which 'perl';
my $cd = dirname abs_path $0;

my $result = system qq|$perl $cd\\csc.pl $drive| and die "Cannot create shadow copy, Error value: $? ($!)";

