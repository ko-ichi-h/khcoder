package gui_window::use_te_g;
use base qw(gui_window);
use strict;
use Tk;

#------------------#
#   Windowを開く   #

sub _new{
	my $self = shift;
	$self->{win_obj}->title(
		$self->gui_jchar('TermExtractによる複合語の検出','euc')
	);
	
	$self->{win_obj}->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => 'TKFN',
		-width => 8,
		-command => sub{
			$self->{win_obj}->after(10,sub{$self->close;})
		}
	)->pack(-anchor=>'e',-side => 'right',-padx => 2, -pady => 2);

	my $ok_btn = $self->{win_obj}->Button(
		-text  => 'OK',
		-font  => 'TKFN',
		-width => 8,
		-command => sub{ $self->{win_obj}->after
			(
				10,
				sub {
					$self->run;
				}
			);
		}
	)->pack(-anchor => 'e',-side => 'right',  -pady => 2);
	
	
	return $self;
}

#----------#
#   実行   #

sub run{
	my $self = shift;
	my $debug = 1;


	my $target_csv = $::project_obj->file_HukugoListTE;
	gui_OtherWin->open($target_csv);
}

#--------------#
#   アクセサ   #

sub win_name{
	return 'w_use_te_g';
}
1;