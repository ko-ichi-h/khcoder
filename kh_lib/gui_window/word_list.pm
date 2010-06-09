package gui_window::word_list;
use base qw(gui_window);

use strict;

use kh_cod::pickup;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt('抽出語リスト - カスタム'));

	#--------------#
	#   表の形式   #

	my $lf0 = $win->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill => 'x');

	$lf0->Label(
		-text => $self->gui_jchar('表の形式：'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f1 = $lf0->Frame->pack(-fill => 'x');
	
	$f1->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	$f1->Radiobutton(
		-text             => $self->gui_jchar('品詞別'),
		-font             => "TKFN",
		-variable         => \$self->{radio_type},
		-value            => 'def',
	)->pack(-side => 'left', -padx => 4);

	$f1->Radiobutton(
		-text             => $self->gui_jchar('頻出150語'),
		-font             => "TKFN",
		-variable         => \$self->{radio_type},
		-value            => '150',
	)->pack(-side => 'left', -padx => 4)->invoke;

	$f1->Radiobutton(
		-text             => $self->gui_jchar('1列'),
		-font             => "TKFN",
		-variable         => \$self->{radio_type},
		-value            => '1c',
	)->pack(-side => 'left', -padx => 4);

	#----------#
	#   数値   #

	$lf0->Label(
		-text => $self->gui_jchar('数値：'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f2 = $lf0->Frame->pack(-fill => 'x');
	
	$f2->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	my $inv0 = $f2->Radiobutton(
		-text             => $self->gui_jchar('出現回数（TF）'),
		-font             => "TKFN",
		-variable         => \$self->{radio_num},
		-value            => 'tf',
		-command          => sub {
			$self->{tani_obj}->win_obj->configure(-state, 'disabled');
		},
	)->pack(-side => 'left', -padx => 4);

	$f2->Radiobutton(
		-text             => $self->gui_jchar('文書数（DF）'),
		-font             => "TKFN",
		-variable         => \$self->{radio_num},
		-value            => 'df',
		-command          => sub {
			$self->{tani_obj}->win_obj->configure(-state, 'normal');
		},
	)->pack(-side => 'left', -padx => 4);

	$self->{tani_obj} = gui_widget::tani->open(
		parent => $f2,
		pack   => {
			-anchor => 'w',
			-pady   => 1,
			-side   => 'left'
		}
	);

	$inv0->invoke;

	#------------------#
	#   ファイル形式   #

	$lf0->Label(
		-text => $self->gui_jchar('ファイル形式：'),
		-font => "TKFN",
	)->pack(-anchor => 'w');

	my $f3 = $lf0->Frame->pack(-fill => 'x');
	
	$f3->Label(
		-text => '   ',
		-font => "TKFN",
	)->pack(-side => 'left', -padx => 2);

	$f3->Radiobutton(
		-text             => $self->gui_jchar('カンマ区切り (*.csv)'),
		-font             => "TKFN",
		-variable         => \$self->{radio_ftype},
		-value            => 'csv',
	)->pack(-side => 'left', -padx => 4)->invoke;

	$f3->Radiobutton(
		-text             => $self->gui_jchar('Excel (*.xls)'),
		-font             => "TKFN",
		-variable         => \$self->{radio_ftype},
		-value            => 'excel',
	)->pack(-side => 'left', -padx => 4);


	$win->Button(
		-text => $self->gui_jchar('キャンセル'),
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$win->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->save;});}
	)->pack(-side => 'right');
	
	return $self;
}

sub save{
	my $self = shift;
	my $target_file = mysql_words->word_list_custom(
		type  => $self->gui_jg( $self->{radio_type}  ),
		num   => $self->gui_jg( $self->{radio_num}   ),
		ftype => $self->gui_jg( $self->{radio_ftype} ),
		tani  => $self->{tani_obj}->tani,
	);
	$self->close;
	gui_OtherWin->open($target_file);
	
	return 1;
}

sub win_name{
	return 'w_word_list';
}

1;