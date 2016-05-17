use strict;
use Win32::OLE('in');

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;

my $objWMIService = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\CIMV2") or die "WMI connection failed.\n";
my $colItems = $objWMIService->ExecQuery("SELECT * FROM Win32_ShadowCopy", "WQL", wbemFlagReturnImmediately | wbemFlagForwardOnly);
foreach my $objItem (in $colItems) {
  print "Caption: $objItem->{Caption}\n";
  print "ClientAccessible: $objItem->{ClientAccessible}\n";
  print "Count: $objItem->{Count}\n";
  print "Description: $objItem->{Description}\n";
  print "DeviceObject: $objItem->{DeviceObject}\n";
  print "Differential: $objItem->{Differential}\n";
  print "ExposedLocally: $objItem->{ExposedLocally}\n";
  print "ExposedName: $objItem->{ExposedName}\n";
  print "ExposedPath: $objItem->{ExposedPath}\n";
  print "ExposedRemotely: $objItem->{ExposedRemotely}\n";
  print "HardwareAssisted: $objItem->{HardwareAssisted}\n";
  print "ID: $objItem->{ID}\n";
  print "Imported: $objItem->{Imported}\n";
  print "InstallDate: $objItem->{InstallDate}\n";
  print "Name: $objItem->{Name}\n";
  print "NoAutoRelease: $objItem->{NoAutoRelease}\n";
  print "NotSurfaced: $objItem->{NotSurfaced}\n";
  print "NoWriters: $objItem->{NoWriters}\n";
  print "OriginatingMachine: $objItem->{OriginatingMachine}\n";
  print "Persistent: $objItem->{Persistent}\n";
  print "Plex: $objItem->{Plex}\n";
  print "ProviderID: $objItem->{ProviderID}\n";
  print "ServiceMachine: $objItem->{ServiceMachine}\n";
  print "SetID: $objItem->{SetID}\n";
  print "State: $objItem->{State}\n";
  print "Status: $objItem->{Status}\n";
  print "Transportable: $objItem->{Transportable}\n";
  print "VolumeName: $objItem->{VolumeName}\n";
  print "\n";
}

