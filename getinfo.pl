use strict;
use Win32::OLE('in');use Data::Dumper;
use JSON;

my $json = (new JSON)->utf8->pretty;
use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\CIMV2") or die "WMI connection failed.\n";
sub get{
  my ($class, $attr) = @_;
  my $colItems = $objWMIService->ExecQuery("SELECT * FROM $class", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
  my $result = [];
        

  foreach my $objItem (in $colItems) {
    push @$result, {map {$_ => $objItem->{$_}} @$attr};
  }
  return $result->[0];
}
my %obj = (
  Win32_OperatingSystem => [qw|BootDevice BuildNumber BuildType Caption CodeSet CSName Locale Name 
    OperatingSystemSKU OSLanguage OSProductSuite ProductType SerialNumber ServicePackMajorVersion 
    ServicePackMinorVersion SystemDevice SystemDirectory SystemDrive Version WindowsDirectory
  |]
  ,Win32_ComputerSystemProduct => [qw|IdentifyingNumber Name SKUNumber Vendor Version UUID|]
  ,Win32_ComputerSystem => [qw|DNSHostName Domain DomainRole Manufacturer Model Name SystemSKUNumber Workgroup|]
  ,Win32_BIOS => [qw|BIOSVersion BuildNumber Manufacturer Name PrimaryBIOS SerialNumber SMBIOSBIOSVersion 
    SMBIOSMajorVersion SMBIOSMinorVersion SMBIOSPresent SoftwareElementState SystemBiosMajorVersion SystemBiosMinorVersion Version
  |]
);
my $result = {map {$_ => get $_, $obj{$_}} keys %obj}; 
print $json->encode($result);
