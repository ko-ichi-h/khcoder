package gui_window::doc_view::win32;
use base qw(gui_window::doc_view);
use strict;

sub wrap{
	require Win32;
	if ( Win32::IsWinNT() ){
		return;
	}
	
	my $self = shift;
	my $line = 1;
	my $wrap = int($::config_obj->DocView_WrapLength_on_Win9x / 2);
	my $wrap2;
	my $sjis = q{
		  [\x00-\x7F]
		| [\x81-\x9F][\x40-\x7E]
		| [\x81-\x9F][\x80-\xFC]
		| [\xE0-\xEF][\x40-\x7E]
		| [\xE0-\xEF][\x80-\xFC]
	};
	my $srtxt = $self->text;
	$srtxt->configure(-wrap,'none');

	while (1){
		my $check_t = $srtxt->get("$line.0", "$line.$wrap");
		my $leng = length($check_t);
		if ($leng == $wrap){                       # 長かったら折り返し
			unless ( $check_t =~ /^(?: $sjis)*$/x){
				$wrap2 = $wrap + 1;
			} else {
				$wrap2 = $wrap;
			}
			$srtxt->insert("$line.$wrap2","\n");
		} else {                                   # 短かったら終了チェック
			my $lastline = $srtxt->index('end');
			my @temp = split /\./, $lastline;
			$lastline = $temp[0];
			if ($line >= $lastline){
				last;
			}
		}
		++$line;
	}
}


1;
