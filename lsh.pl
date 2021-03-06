use strict;
use Win32::OLE('in');use Data::Dumper;
use JSON;

my $json = (new JSON)->utf8->pretty;
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\CIMV2") or die "WMI connection failed.\n";
my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_ShadowCopy", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
my $result = {};

my @attr = qw|Caption ClientAccessible Count Description DeviceObject Differential ExposedLocally ExposedName ExposedPath ExposedRemotely 
  HardwareAssisted ID Imported InstallDate Name NoAutoRelease NotSurfaced NoWriters OriginatingMachine Persistent Plex ProviderID 
  ServiceMachine SetID State Status Transportable VolumeName
|; 
my $r;
foreach my $objItem (in $colItems) {
  my $obj = {};
  foreach (@attr){
    $result->{$_} //= []; 
    push @{$result->{$_}}, $objItem->{$_};
  };
}
print $json->encode($result);

