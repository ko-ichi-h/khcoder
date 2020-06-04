package kh_morpho::linux::stanford::cn;
use base qw(kh_morpho::linux::stanford);
use strict;
use utf8;

sub init{
	my $self = shift;
	return $self;
}

sub _sentence{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;
	
	unless (length($t)){
		#print "Empty!\n";
		return 1;
	}
	
	if ( $t eq '< NEW-LINE >') {
		print $fh "EOS\n";
		return 1;
	}
	
	my $r = $self->_tokenize_stem($t, $fh);

	return 1;
}

sub _tag{
	my $self = shift;
	my $t    = shift;
	my $fh   = shift;

	$t =~ s/ //g;
	
	print $fh "$t\t$t\t$t\tTAG\t\tTAG\n";
}



sub segment{
	my $self = shift;
	my $icode = shift;
	print "icode: $icode\n";
	
	# 文ごとに分ける
	my $file_sentences = $::project_obj->file_TempTXT;
	
	open(my $fhi, "<:encoding($icode)", $self->target) or die
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	
	open(my $fho, ">:encoding(utf8)", $file_sentences) or die
		gui_errormsg->open(
			thefile => $file_sentences,
			type => 'file'
		);
	
	while (<$fhi>) {
		chomp;
		unless ( length($_) ){
			next;
		}
		
		# 見出し行はそのまま出力
		if ($_ =~ /^(<h[1-5]>)(.+)(<\/h[1-5]>)$/io){
			print $fho "$_\n";
			print $fho "<NEW-LINE>\n";
		}
		# それ以外は1文1行に
		else {
			my $t = $_;
			my $pos = -1;
			while ( index($t, '。') > -1 ) {
				$pos = index($t, '。');
				print $fho substr($t, 0, $pos + 1)."\n";
				substr($t, 0, $pos + 1) = '';
			}
			if ( length($t) ) {
				print $fho "$t\n"
			}
			print $fho "<NEW-LINE>\n";
		}
	}
	close $fho;
	close $fhi;
	
	# 単語ごとに分ける
	unlink($self->target);

	my $seg_dir = $::config_obj->stanf_seg_path;
	$seg_dir =~ s/\\/\//g;
	$seg_dir .= '/' unless $seg_dir =~ /\/$/;
	$seg_dir = $::config_obj->os_path( $seg_dir );
	
	die( "Could not execute Stanford Segmenter!\n$seg_dir" ) unless -d $seg_dir;
	
	my $cmd_line  =
		 'java -showversion -mx'.$::config_obj->stanford_ram.' -cp "'
		.$seg_dir
		.'*:" edu.stanford.nlp.ie.crf.CRFClassifier -sighanCorporaDict "'
		.$seg_dir.'data'
		.'" -textFile "'
		.$file_sentences
		.'" -inputEncoding utf8 -sighanPostProcessing true -keepAllWhitespaces true -loadClassifier "'
		.$seg_dir.'data/ctb.gz'
		.'" -serDictionary "'
		.$seg_dir.'data/dict-chris6.ser.gz'
		.'" "" > "'
		.$self->target
		.'"'
	;
	print "$cmd_line\n";

	system($cmd_line);
	
	unlink ($file_sentences);
}



1;