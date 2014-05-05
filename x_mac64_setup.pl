use strict;
use Cwd;

# Edit KH Coder's config file
my $file_setup = cwd.'/config/coder.ini';
my %config =();

open (my $fh, '<', $file_setup) or die;
while (<$fh>){
	chomp;
	my @temp = split /\t/, $_;
	$config{$temp[0]} = $temp[1] if length($temp[0]);
}
close ($fh);

$config{chasenrc_path}     = cwd.'/deps/ipadic-2.7.0/chasenrc';
$config{grammarcha_path}   = cwd.'/deps/ipadic-2.7.0/grammar.cha';
$config{stanf_jar_path}    = cwd.'/deps/stanford-postagger/stanford-postagger.jar';
$config{stanf_tagger_path} = cwd.'/deps/stanford-postagger/models/left3words-wsj-0-18.tagger';
$config{sql_username}      = 'root';
$config{sql_password}      = 'khc';
$config{sql_host}          = '127.0.0.1';
$config{sql_port}          = '3308';
$config{c_or_j}            = 'chasen';
$config{all_in_one_pack}   = 1;
$config{app_html}          = 'open %s &';
$config{app_csv}           = 'open %s &';
$config{app_pdf}           = 'open %s &';
$config{font_main}         = 'Hiragino Kaku Gothic ProN,-13';

open (my $fh, '>', $file_setup) or die;
foreach my $i (keys %config){
	print $fh "$i\t$config{$i}\n";
}
close ($fh);

