package gui_window::outvar_read;
use base qw(gui_window);
use strict;
use Tk;

use mysql_outvar;
use gui_errormsg;

#---------------------#
#   Window オープン   #
#---------------------#

sub _new{
	my $self = shift;
	
	my $mw = $::main_gui->mw;
	my $wmw= $mw->Toplevel;
	$wmw->focus;
	$wmw->title(Jcode->new('外部変数の読み込み')->sjis);

	my $fra4 = $wmw->LabFrame(
		-label => 'Options',
		-labelside => 'acrosstop',
		-borderwidth => 2,
	)->pack(-fill=>'x');

	# ファイル名指定のフレーム
	my $fra4e = $fra4->Frame()->pack(-expand => 'y', -fill => 'x',-pady => 3);
	
	$fra4e->Label(
		-text => Jcode->new('CSVファイル：')->sjis,
		-font => "TKFN",
	)->pack(-side => 'left');
	
	$fra4e->Button(
		-text    => Jcode->new('参照')->sjis,
		-font    => "TKFN",
		-command => sub {$mw->after(10,sub { $self->file; });},
	)->pack(-side => 'left');
	
	$self->{entry} = $fra4e->Entry(
		-font  => "TKFN",
		-width => 20
	)->pack(-side => 'left',-padx => 2);

	# 読み込み単位の指定
	my $fra4f = $fra4->Frame()->pack(-expand => 'y', -fill => 'x', -pady =>3);
	
	$fra4f->Label(
		text => Jcode->new('読み込み単位：')->sjis,
		font => "TKFN"
	)->pack(anchor => 'w', side => 'left');

	my %pack = (
			-anchor => 'w',
			-pady   => 1,
#			-side   => 'right'
	);
	$self->{tani_obj} = gui_widget::tani->open(
		parent => $fra4f,
		pack   => \%pack
	);

	$wmw->Button(
		-text => Jcode->new('キャンセル')->sjis,
		-font => "TKFN",
		-width => 8,
		-command => sub{ $mw->after(10,sub{$self->close;});}
	)->pack(-side => 'right',-padx => 2);

	$wmw->Button(
		-text => 'OK',
		-width => 8,
		-font => "TKFN",
		-command => sub{ $mw->after(10,sub{$self->_read;});}
	)->pack(-side => 'right');

	MainLoop;
	
	$self->{win_obj} = $wmw;
	return $self;
}

# ファイル参照

sub file{
	my $self = shift;

	my @types = (
		[ "CSV files",[qw/.csv/] ],
		["All files",'*']
	);
	
	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => Jcode->new('CSVファイルを選択してください')->sjis,
		-initialdir => $::config_obj->cwd
	);
	
	if ($path){
		# substr($path, 0, rindex($path, '/') + 1 ) = '';
		$self->{entry}->delete(0, 'end');
		$self->{entry}->insert('0',Jcode->new("$path")->sjis);
	}
}

#--------------#
#   読み込み   #
#--------------#

sub _read{
	my $self = shift;
	
	# 入力チェック
	
	unless (-e $self->{entry}->get){
		gui_errormsg->open(
			type   => 'msg',
			msg    => Jcode->new('CSVファイルを正しく指定して下さい。')->sjis,
			window => \$self->{win_obj},
		);
		return 0;
	}
	
	my $rtrn = mysql_outvar->read(
		file => $self->{entry}->get,
		tani => $self->{tani_obj}->tani,
	);
	
	if ($rtrn){
		$self->close;
		my $list = gui_window::outvar_list->open;
		$list->_fill;
	}
}

#--------------#
#   アクセサ   #
#--------------#


sub win_name{
	return 'w_outvar_read';
}


1;
