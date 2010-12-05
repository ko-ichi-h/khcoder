package kh_morpho::win32::mecab;
# use strict;
use base qw( kh_morpho::win32 );

#--------------------#
#   茶筌の実行関係   #
#--------------------#

sub _run_morpho{
	my $self = shift;	
	my $path = $self->config->mecab_path;
	
	unless (-e $path){
		gui_errormsg->open(
			msg => '事前にKH Coderの設定（形態素解析）を行ってください',
			type => 'msg'
		);
		exit;
	}
	
	$self->{target_temp} = $self->target.'.tmp';
	$self->{output_temp} = $self->output.'.tmp';
	
	unlink $self->{target_temp} if -e $self->{target_temp};
	unlink $self->{output_temp} if -e $self->{output_temp};
	
	open (TRGT,$self->target) or 
		gui_errormsg->open(
			file => $self->target,
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
			
			print "$pre [[ $cnt ]] $t\n";
		}
		$self->_macab_store($t);
	}
	close (TRGT);
	$self->_mecab_run();
	
	
	exit;
	
sub _mecab_run{
	my $self = shift;
	my $t    = shift;
	
	$self->_mecab_store($t);
	
	
}

sub _mecab_store{
	my $self = shift;
	my $t    = shift;
	
	open (TMPO,">>", $self->{target_temp}) or 
		gui_errormsg->open(
			file => $self->{target_temp},
			type => 'file'
		);
	print TMPO $t;
	close (TMPO);
}
	
	
	my $pos = rindex($path,"\\bin\\");
	$self->{dir} = substr($path,0,$pos);
	my $chasenrc = $self->{dir}."\\etc\\mecabrc";
	$self->{cmdline} = "mecab -Ochasen -r \"$chasenrc\" -o \"".$self->output."\" \"".$self->target."\"";

	print "morpho: $self->{cmdline}\n";

	require Win32::Process;
	# Win32::Process->import; # これではうまくいかない？

	my $ChasenObj;
	Win32::Process::Create(
		$ChasenObj,
		$path,
		$self->{cmdline},
		0,
		Win32::Process->CREATE_NO_WINDOW,
		$self->{dir},
	) || $self->Exec_Error("Wi32::Process can not start");
	$ChasenObj->Wait( Win32::Process->INFINITE )
		|| $self->Exec_Error("Wi32::Process can not wait");
	
	return(1);
}

sub exec_error_mes{
	return "KH Coder Error!!\nMeCabの起動に失敗しました！";
}


1;
