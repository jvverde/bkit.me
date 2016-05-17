use strict;
use Win32::OLE('in');use Data::Dumper;
use JSON;

my $json = (new JSON)->utf8->pretty;
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\CIMV2") or die "WMI connection failed.\n";
my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_Volume", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
my $result = {};

my @attr = qw|Access Automount Availability BlockSize Capacity Caption Compressed ConfigManagerErrorCode ConfigManagerUserConfig 
  CreationClassName Description DeviceID DirtyBitSet DriveLetter DriveType ErrorCleared ErrorDescription ErrorMethodology FileSystem 
  FreeSpace IndexingEnabled InstallDate Label LastErrorCode MaximumFileNameLength Name NumberOfBlocks PNPDeviceID 
  PowerManagementCapabilities PowerManagementSupported Purpose QuotasEnabled QuotasIncomplete QuotasRebuilding Status StatusInfo 
  SystemCreationClassName SystemName SerialNumber SupportsDiskQuotas SupportsFileBasedCompression
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

