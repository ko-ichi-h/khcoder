package kh_sysconfig::win32;
use base qw(kh_sysconfig);
use strict;

#------------------#
#   設定の初期化   #
#------------------#
sub reset_parm{
		my $self = shift;
		print "Resetting parameters...\n";
		mkdir "config";
		open (CON,">$self->{ini_file}") or 
			gui_errormsg->open(
				type    => 'file',
				thefile => "m: $self->{ini_file}"
			);
		close (CON);
		# 品詞定義ファイルを作成
		use DBI;
		use DBD::CSV;
		my $dbh = DBI->connect("DBI:CSV:f_dir=./config") or die;
		$dbh->do(
			"CREATE TABLE hinshi_chasen (
				hinshi_id INTEGER,
				kh_hinshi CHAR(225),
				condition1 CHAR(225),
				condition2 CHAR(225)
			)"
		) or die;
		my @table = (
				"7, '地名', '名詞-固有名詞-地域', undef",
				"6, '人名', '名詞-固有名詞-人名', undef",
				"5,'組織名','名詞-固有名詞-組織', undef",
				"'4','固有名詞','名詞-固有名詞', undef",
				"'2','サ変名詞','名詞-サ変接続', undef",
				"'3','形容動詞','名詞-形容動詞語幹', undef",
				"'8','ナイ形容','名詞-ナイ形容詞語幹', undef",
				"'16','名詞B','名詞-一般','ひらがな'",
				#"'16','名詞B','名詞-副詞可能','ひらがな'",
				"'20','名詞C','名詞-一般','一文字'",
				#"'20','名詞C','名詞-副詞可能','一文字'",
				"'21','否定助動詞','助動詞','否定'",
				"'1','名詞','名詞-一般', undef",
				"'9','副詞可能','名詞-副詞可能', undef",
				"'10','未知語','未知語', undef",
				"'12','感動詞','感動詞', undef",
				"'12','感動詞','フィラー', undef",
				"'99999','HTMLタグ','タグ', 'HTML'",
				"'11','タグ','タグ', undef",
				"'17','動詞B','動詞-自立','ひらがな'",
				"'13','動詞','動詞-自立', undef",
				"'22','形容詞（非自立）','形容詞-非自立', undef",
				"'18','形容詞B','形容詞','ひらがな'",
				"'14','形容詞','形容詞', undef",
				"'19','副詞B','副詞','ひらがな'",
				"'15','副詞','副詞', undef"
		);
		foreach my $i (@table){
			$dbh->do("
				INSERT INTO hinshi_chasen
					(hinshi_id, kh_hinshi, condition1, condition2 )
				VALUES
					( $i )
			") or die($i);
		}

		$dbh->disconnect;
}

#----------------------------#
#   設定の読み込みルーチン   #
#----------------------------#

sub _readin{
	use Jcode;
	use kh_sysconfig::win32::chasen;
	use kh_sysconfig::win32::juman;

	my $self = shift;



	# Chasenの設定
	if (-e $self->{chasen_path}){
		my $pos = rindex($self->{chasen_path},'\\');
		$self->{grammercha} = substr($self->{chasen_path},0,$pos);
		$self->{chasenrc} = "$self->{grammercha}".'\\dic\chasenrc';
		$self->{grammercha} .= '\dic\grammar.cha';
		
		my $flag = 0; my $msg = '(連結品詞';
		Jcode::convert(\$msg,'sjis','euc');
		if (-e $self->{chasenrc}){
			open (CRC,"$self->{chasenrc}") or
				gui_errormsg->open(
					type    => 'file',
					thefile => "$self->{chasenrc}"
				);
			while (<CRC>){
				chomp;
				if ($_ eq '; by KH Coder, start.'){
					$flag = 1;
					next;
				}
				elsif ($_ eq '; by KH Coder, end.'){
					$flag = 0;
					next;
				}

				unless ($flag){
					next;
				}
				if ($_ eq "$msg"){
					$self->{use_hukugo} = 1;
				}
			}
			close (CRC);
		}
		unless ($self->{use_hukugo}){
			$self->{use_hukugo} = 0;
		}
	}

	return $self;
}

#------------------#
#   設定値の保存   #
#------------------#

sub save{
	my $self = shift;
	$self = $self->refine_cj;
	if ($self->path_check){
		$self->config_morph;
		my @outlist = (
			'chasen_path',
			'juman_path',
			'c_or_j',
			'sqllog',
			'mail_if',
			'mail_smtp',
			'mail_from',
			'mail_to',
			'use_heap',
			'color_DocView_info',
			'color_DocView_search',
			'color_DocView_force',
			'color_DocView_html',
			'color_DocView_CodeW',
			'DocView_WrapLength_on_Win9x',
			'DocSrch_CutLength',
		);
		
		my $f = $self->{ini_file};
		open (INI,">$f") or
			gui_errormsg->open(
				type    => 'file',
				thefile => ">$f"
			);
		foreach my $i (@outlist){
			print INI "$i\t".$self->$i( undef,'1')."\n";
		}
		foreach my $i (keys %{$self}){
			if ( index($i,'w_') == 0 ){
				print INI "$i\t".$self->win_gmtry($i)."\n";
			}
		}
		if ($self->{main_window}){
			print INI "main_window\t$self->{main_window}";
		}
		close (INI);
		return 1;
	} else {
		return 0;
	}
}



#--------------------------------#
#   以下は設定値を返すルーチン   #
#--------------------------------#


#--------------------#
#   形態素解析関係   #


sub chasen_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{chasen_path} = $new;
	}
	return $self->{chasen_path};
}

sub juman_path{
	my $self = shift;
	my $new = shift;
	if ($new){
		$self->{juman_path} = $new;
	}
	return $self->{juman_path};
}

#-------------#
#   GUI関係   #

sub underline_conv{
	my $self = shift;
	my $n    = shift;
	return $n;
}

sub mw_entry_length{
	return 20;
}

#------------#
#   その他   #


sub os_path{
	my $self = shift;
	my $c = shift;

	$c = Jcode->new("$c")->euc;
	$c =~ tr/\//\\/;
	$c = Jcode->new("$c")->sjis;

	return $c;
}


1;

__END__
