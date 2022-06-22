package gui_window::r_plot::doc_cls;
use base qw(gui_window::r_plot);
use strict;
use utf8;

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "PNG",[qw/.png/] ],
	);
	
	@types = (
		@types,
		$self->extra_save_types,
		[ "R Source",[qw/.r/] ],
	);
	
	if ($::config_obj->os eq 'win32'){
		@types = (
			[ "Enhanced Metafile",[qw/.emf/] ],
			[ "SVG",[qw/.svg/] ],
			[ "PDF",[qw/.pdf/] ],
			@types,
		);
	} elsif ($^O eq 'darwin') {
		@types = (
			[ "PDF",[qw/.pdf/] ],
			@types,
		);
	} else {
		@types = (
			[ "PDF",[qw/.pdf/] ],
			[ "SVG",[qw/.svg/] ],
			@types,
		);
	}

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.eps',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::r_plot->saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);
	
	# Rファイルを保存する場合は別途処理に
	if ($path =~ /.*\.r$/){
		$self->save_r($path);
	} else {
		$self->{plots}[$self->{ax}]->save($path) if $path;
	}
	return 1;
}

# Rファイルを保存する処理
sub save_r{
	my $self = shift;
	my $path = shift;
	
	# tmpファイル名取得
	my $file_tmp = '';
	if (
		$self->{plots}[0]->{command_f}
		=~ /read.csv\("(.+?)"/
	) {
		$file_tmp = $1;
		$file_tmp =~ s/\\\\/\\/g;
		$file_tmp = $::config_obj->os_path($file_tmp);
	}

	# tmpファイルを保存用にコピー
	my $file_csv = $path.'.csv';
	if (-e $file_csv){
		my $ans = $self->win_obj->messageBox(
			-message => 
				   kh_msg->get('gui_window::cls_height::doc->overwr') # このファイルを上書きしてよろしいですか：
				   ."\n"
				   .$::config_obj->uni_path($file_csv),
			-icon    => 'question',
			-type    => 'OKCancel',
			-title   => 'KH Coder',
		);
		unless ($ans =~ /ok/i){ return 0; }
		unlink($file_csv);
	}
	use File::Copy;
	copy($file_tmp, $file_csv)
		or gui_errormsg->open(
			type => 'file',
			file => $file_csv,
	);

	# rコマンドの変更
	$file_csv = $::config_obj->uni_path($file_csv);
	$file_csv =~ s/\\/\\\\/g;

	$self->{plots}[0]->{command_f} =~ s/\x0D\x0A|\x0D|\x0A/\n/g;
	my $backup = $self->{plots}[0]->{command_f};
	$self->{plots}[0]->{command_f}
		=~ s/d <\- read\.csv.+?\n/\n/;
	$self->{plots}[0]->{command_f} =
		'd <- read.csv("'.$file_csv.'", fileEncoding="UTF-8-BOM")'."\n"
		.$self->{plots}[0]->{command_f};

	$self->{plots}[0]->save($path) if $path;
	$self->{plots}[0]->{command_f} = $backup;

	return 1;
}


sub photo_pane_width{
	return 490;
}

sub option1_options{
	return [ 'nothing' ];
}

sub option1_name{
	return '';
}

sub win_title{
	return kh_msg->get('win_title'); # 文書のデンドログラム
}

sub win_name{
	return 'w_doc_cls_plot';
}


sub base_name{
	return 'doc_cls';
}

1;