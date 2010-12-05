package kh_morpho::linux::mecab;
# use strict;
use base qw( kh_morpho::linux );

#---------------------#
#   MeCabの実行関係   #
#---------------------#

sub _run_morpho{
	my $self = shift;	
	
	# 初期化
	$self->{store} = '';
	
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	if (-e $self->output){
		unlink $self->output or 
			gui_errormsg->open(
				thefile => $self->output,
				type => 'file'
			);
	}
	
	$self->{cmdline} = "mecab -Ochasen -o \"$self->{output_temp}\" \"$self->{target_temp}\"";
	#print "morpho: $self->{cmdline}\n";
	
	# 処理開始
	open (TRGT,$self->target) or 
		gui_errormsg->open(
			thefile => $self->target,
			type => 'file'
		);
	while ( <TRGT> ){
		my $t   = $_;
		while ( index($t,'<') > -1){
			my $pre = substr($t,0,index($t,'<'));
			my $cnt = substr(
				$t,
				index($t,'<'),
				index($t,'>') - index($t,'<') + 1
			);
			unless ( index($t,'>') > -1 ){
				gui_errormsg->open(
					msg => '山カッコ（<>）による正しくないマーキングがありました。',
					type => 'msg'
				);
				exit;
			}
			substr($t,0,index($t,'>') + 1) = '';
			
			$self->_mecab_run($pre);
			$self->_mecab_outer($cnt);
			
			#print "[[$pre << $cnt >> $t]]\n";
		}
		$self->_mecab_store($t);
	}
	close (TRGT);
	$self->_mecab_run();
	return(1);
}


sub _mecab_run{
	my $self = shift;
	my $t    = shift;

	$self->_mecab_store($t) if length($t);
	$self->_mecab_store_out;

	return 1 unless -s $self->{target_temp} > 0;
	unlink $self->{output_temp} if -e $self->{output_temp};

	# MeCabの実行
	system "$self->{cmdline}";
	
	unless (-e $self->{output_temp}){
		$self->Exec_Error("No output file");
	}

	# 結果の取り出し
	my $cut_eos;
	if ( $self->{stlast} =~ /\n\Z/o){
		$cut_eos = 0;
	} else {
		$cut_eos = 1;
	}
	
	open (OTEMP,"$self->{output_temp}") or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	open (OTPT,">>",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);
	
	my $last_line = '';
	while( <OTEMP> ){
		if ( length($last_line) > 0 ){
			print OTPT $last_line;
		}
		
		$last_line = $_;
	}
	
	if ($last_line =~ /^EOS\n/o && $cut_eos){
	
	} else {
		print OTPT $last_line; 
	}
	
	close (OTEMP);
	close (OTPT);
	
	unlink $self->{output_temp} or
		gui_errormsg->open(
			thefile => $self->{output_temp},
			type => 'file'
		);
	unlink $self->{target_temp} or 
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);
	$self->{store} = '';
}

sub _mecab_outer{
	my $self = shift;
	my $t    = shift;
	my $name = 'タグ';

	open (OTPT,">>",$self->output) or 
		gui_errormsg->open(
			thefile => $self->output,
			type => 'file'
		);

	print OTPT "$t\t$t\t$t\t$name\t\t\n";

	close (OTPT);
}

sub _mecab_store{
	my $self = shift;
	my $t    = shift;
	
	return 1 unless length($t) > 0;
	
	$self->{store} .= $t;
	$self->{stlast} = $t;
	
	if ( length($self->{store}) > 1048576 ){
		$self->_mecab_store_out;
	}

	return $self;
}


sub _mecab_store_out{
	my $self = shift;

	return 1 unless length($self->{store}) > 0;

	open (TMPO,">>", $self->{target_temp}) or 
		gui_errormsg->open(
			thefile => $self->{target_temp},
			type => 'file'
		);
	print TMPO $self->{store};
	close (TMPO);

	$self->{store} = '';
	return $self;
}



sub exec_error_mes{
	return "KH Coder Error!!\nMeCabの起動に失敗しました！";
}


1;
