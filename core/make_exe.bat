move plugin plugin_bak
attrib -h kh_lib\Tk\CVS
move kh_lib\Tk\CVS CVS_bak
perlapp --add Encode::Guess;Encode::JP::H2Z;Encode::JP;feature;Encode::EUCJPMS;kh_project_io;YAML::Dumper;YAML::Loader --icon memo\1.ico --lib .\kh_lib --shared private --tmpdir config --norunlib --verbose --force --info "CompanyName=Ritsumeikan Univ.;FileDescription=KH Coder;FileVersion=2;InternalName=kh_coder.exe;LegalCopyright=Higuchi Koichi;OriginalFilename=kh_coder.exe;ProductName=KH Coder;ProductVersion=2" --exe kh_coder.exe kh_coder.pl
move plugin_bak plugin
move CVS_bak kh_lib\Tk\CVS
attrib +h kh_lib\Tk\CVS