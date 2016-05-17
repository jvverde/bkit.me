use strict;
use Win32::OLE;

($,,$\) =("\t","\n");

my $drive =  uc shift or die 'You should pass a drive letter';
chomp $drive;
$drive =~ /^[A-Z]$/ or die 'The drive letter can only have 1 char';
print "Create a shadow copy for drive $drive";

my $wmi = Win32::OLE->GetObject("winmgmts:\\\\.\\root\\cimv2:Win32_ShadowCopy") or die "Cannot get Win32_ShadowCopy Object";
my $r = $wmi->Create("$drive:\\","ClientAccessible");
die "Error: $r(".Win32::OLE->LastError().')' unless defined $r && $r == 0;
print "---done---\n";

