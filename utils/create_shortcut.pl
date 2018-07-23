use strict;

# exe
my $exe_path = Win32::GetCwd();

# desktop
use Win32::OLE;
my $wsh = new Win32::OLE 'WScript.Shell';
my $desktop_path = $wsh->SpecialFolders('Desktop');

# name
my $name = " Folder";
if ( length($ARGV[0]) ){
	$name = $ARGV[0];
}

# link
use Win32::Shortcut;
my $LINK = Win32::Shortcut->new();
$LINK->{'Path'} = $exe_path;
$LINK->{IconLocation} = $exe_path.'\kh_coder.exe';
$LINK->{'WorkingDirectory'} = Win32::GetCwd();
$LINK->{'Description'} = "KH Coder 3$name";
$LINK->Save("$desktop_path\\KH Coder 3$name.lnk");
$LINK->Close();
