package kh_all_in_mac;
use strict;
use Cwd;

#--------------------------------#
#   All In One package for Mac   #
#--------------------------------#

sub init{
	print "Executing Mac OS X 64-bit Package\n";
	my $config_flg = 0;

	#-------------------------------#
	#   Configuration of KH Coder   #

	# chasen
	if (
		not -e $::config_obj->chasenrc_path
		and -e $::config_obj->cwd.'/deps/ipadic-2.6.1/chasenrc'
	) {
		$::config_obj->chasenrc_path( $::config_obj->cwd.'/deps/ipadic-2.6.1/chasenrc' );
		$config_flg = 1;
	}
	if (
		not -e $::config_obj->grammarcha_path
		and -e $::config_obj->cwd.'/deps/ipadic-2.6.1/grammar.cha'
	) {
		$::config_obj->grammarcha_path( $::config_obj->cwd.'/deps/ipadic-2.6.1/grammar.cha' );
	}

	# stanford pos tagger
	if (
		not -e $::config_obj->stanf_tagger_path_en
		and -e $::config_obj->cwd.'/deps/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_en(
			$::config_obj->cwd.'/deps/stanford-postagger/models/wsj-0-18-left3words-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_tagger_path_cn
		and -e $::config_obj->cwd.'/deps/stanford-postagger/models/chinese-distsim.tagger'
	) {
		$::config_obj->stanf_tagger_path_cn(
			$::config_obj->cwd.'/deps/stanford-postagger/models/chinese-distsim.tagger'
		);
	}

	if (
		not -e $::config_obj->stanf_jar_path
		and -e $::config_obj->cwd.'/deps/stanford-postagger/stanford-postagger.jar'
	) {
		$::config_obj->stanf_jar_path(
			$::config_obj->cwd.'/deps/stanford-postagger/stanford-postagger.jar'
		);
	}

	# Stanford segmenter
	if (
		not -d $::config_obj->stanf_seg_path
		and -d $::config_obj->cwd.'/deps/stanford-segmenter'
	) { 
		$::config_obj->stanf_seg_path(
			$::config_obj->cwd.'/deps/stanford-segmenter'
		);
	}

	# HanDic
	if (
		not -d $::config_obj->han_dic_path
		and -d $::config_obj->cwd.'/deps/handic'
	) { 
		$::config_obj->han_dic_path(
			$::config_obj->cwd.'/deps/handic'
		);
	}

	# mecabrc
	if (
		not -e $::config_obj->mecabrc_path
		and -e $::config_obj->cwd.'/deps/mecab/etc/mecabrc'
	) {
		$::config_obj->mecabrc_path(
			$::config_obj->cwd.'/deps/mecab/etc/mecabrc'
		);
	}

	# FreeLing
	if (
		not -d $::config_obj->freeling_dir
		and -d $::config_obj->cwd.'/deps/freeling40/share/freeling'
	) { 
		$::config_obj->freeling_dir(
			$::config_obj->cwd.'/deps/freeling40/share/freeling'
		);
	}

	#---------------------------#
	#   Configuration of deps   #

	if ( $config_flg ){
		print "Setting up deps...\n";

		# Edit configurations of MeCab
		my $dic_dir = cwd.'/deps/mecab/lib/mecab/dic/ipadic';
		my $mecabrc;
		open (my $fh, '<', cwd.'/deps/mecab/etc/mecabrc') or die("could not read file: mecabrc\n");
		{
			local $/ = undef;
			$mecabrc = <$fh>;
		}
		close ($fh);
		undef $fh;
		
		$mecabrc =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
		$mecabrc =~ s/\ndicdir = .+?\n/\ndicdir = $dic_dir\n/;
		
		open ($fh, '>', cwd.'/deps/mecab/etc/mecabrc') or die("could not write file: mecabrc\n");
		print $fh $mecabrc;
		close($fh);
		undef $fh;
		
		# Edit configurations of Chasen
		my $dici_dir = '"'.cwd.'/deps/ipadic-2.6.1"';
		my $chasenrc;
		open ($fh, '<', cwd.'/deps/ipadic-2.6.1/chasenrc') or die("could not read file: chasenrc\n");
		{
			local $/ = undef;
			$chasenrc = <$fh>;
		}
		close ($fh);
		undef $fh;
		
		$chasenrc =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
		$chasenrc =~ s/\n\(GRAMMAR .+?\n/\n\(GRAMMAR $dici_dir\)\n/;
		
		open ($fh, '>', cwd.'/deps/ipadic-2.6.1/chasenrc') or die("could not write file: chasenrc\n");
		print $fh $chasenrc;
		close($fh);
		undef $fh;
		
		# Edit configurations of R
		my $file_r = cwd.'/deps/R-3.1.0/Versions/3.1/Resources/bin/R';
		my $r_home = '"'.cwd.'/deps/R-3.1.0/Resources"';
		
		my $r;
		open ($fh, '<', $file_r) or die("could not read file: $file_r\n");
		{
			local $/ = undef;
			$r = <$fh>;
		}
		close ($fh);
		undef $fh;
		
		$r =~ s/\nR_HOME_DIR=\/.+?\n/\nR_HOME_DIR=$r_home\n/;
		
		open ($fh, '>', $file_r) or die("could not write file: $file_r\n");
		print $fh $r;
		close ($fh);
		undef $fh;
		
		# Edit configurations of MySQL
		my $file_mysql = cwd.'/deps/mysql-5.6.17/khc.cnf';
		my $mysal_b = cwd.'/deps/mysql-5.6.17';
		my $mysal_d = cwd.'/deps/mysql-5.6.17/data';
		
		my $cnf;
		open ($fh, '<', $file_mysql) or die("could not read file: $file_mysql\n");
		{
			local $/ = undef;
			$cnf = <$fh>;
		}
		close ($fh);
		undef $fh;
		
		$cnf =~ s/\nbasedir = .+?\n/\nbasedir = $mysal_b\n/;
		$cnf =~ s/\ndatadir = .+?\n/\ndatadir = $mysal_d\n/;
		
		open ($fh, '>', $file_mysql) or die("could not write file: $file_mysql\n");
		print $fh $cnf;
		close ($fh);
		undef $fh;

	}

	#-----------------------------#
	#   Configuration of %::ENV   #

	# R's path
	unless ($::ENV{PATH} =~ /deps\/R\-3\.1\.0\/Resources\/bin:/){
		system "export PATH=\"".$::config_obj->cwd."/deps/R-3.1.0/Resources/bin\":\$PATH";
		$::ENV{PATH} = $::config_obj->cwd."/deps/R-3.1.0/Resources/bin:".$::ENV{PATH};
	}
	$ENV{R_LIBS_USER} = 'DO_NOT_LOAD_FROM_USER_DIR';

	# Chasen, MeCab, FreeLing, JDK, pandoc
	unless ($::ENV{PATH} =~ /deps\/chasen:/){
		#system "export PATH=".$::config_obj->cwd."/deps/chasen/bin:".$::config_obj->cwd."/deps/mecab/bin:\$PATH";
		$::ENV{PATH} =
			 $::config_obj->cwd."/deps/chasen/bin:"
			.$::config_obj->cwd."/deps/mecab/bin:"
			.$::config_obj->cwd."/deps/freeling40/bin:"
			.$::config_obj->cwd."/deps/AdoptOpenJDK/bin:"
			.$::config_obj->cwd."/deps/pandoc-2.7.3/bin:"
			.$::ENV{PATH}
		;
		
		#system 'export DYLD_FALLBACK_LIBRARY_PATH='.$::config_obj->cwd.'/deps/chasen/lib:'.$::config_obj->cwd."/deps/mecab/lib:\$DYLD_FALLBACK_LIBRARY_PATH";
		$::ENV{DYLD_FALLBACK_LIBRARY_PATH} =
			 $::config_obj->cwd.'/deps/chasen/lib:'
			.$::config_obj->cwd.'/deps/mecab/lib:'
			.$::config_obj->cwd.'/deps/freeling40/lib:'
			.$::config_obj->cwd.'/deps/AdoptOpenJDK/lib:'
			.$::ENV{DYLD_FALLBACK_LIBRARY_PATH};
	}

	# Start MySQL
	#unless (-e '/tmp/mysql.sock.khc3'){
	unless (mysql_exec->connection_test){
		print "Starting MySQL...\n";
		system '"'.$::config_obj->cwd."/deps/mysql-5.6.17/bin/mysqld\" --defaults-file=\"".$::config_obj->cwd."/deps/mysql-5.6.17/khc.cnf\" &"
	}

	# Start UIM
	my $gr1 = `ps aux | grep uim-helper`;
	unless ($gr1 =~ /uim\-helper\-server/){
		system '/Library/Frameworks/UIM.framework/Versions/Current/bin/uim-xim --engine=anthy &';
		system 'xterm -e echo ok';
	}

	return 1;
}

sub mysql_stop{
	mysql_exec->shutdown_db_server;
}

1;


__END__
