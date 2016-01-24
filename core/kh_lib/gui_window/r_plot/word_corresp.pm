package gui_window::r_plot::word_corresp;
use base qw(gui_window::r_plot);

sub option1_options{
	my $self = shift;

	if (@{$self->{plots}} == 2){
		return [
			kh_msg->get('d_l'), # ドットとラベル
			kh_msg->get('d'), # ドットのみ
		] ;
	} else {
		return [
			kh_msg->get('col'), # カラー
			kh_msg->get('gray'), # グレースケール
			kh_msg->get('var'), # 変数のみ
			kh_msg->get('d'), # ドットのみ
		] ;
	}
}

sub save{
	my $self = shift;

	# 保存先の参照
	my @types = (
		[ "PDF",[qw/.pdf/] ],
		[ "Encapsulated PostScript",[qw/.eps/] ],
		[ "SVG",[qw/.svg/] ],
		[ "PNG",[qw/.png/] ],
		[ "CSV",[qw/.csv/] ],
		[ "R Source",[qw/.r/] ],
	);
	@types = ([ "Enhanced Metafile",[qw/.emf/] ], @types)
		if $::config_obj->os eq 'win32';

	my $path = $self->win_obj->getSaveFile(
		-defaultextension => '.pdf',
		-filetypes        => \@types,
		-title            =>
			$self->gui_jt(kh_msg->get('gui_window::r_plot->saving')), # プロットを保存
		-initialdir       => $self->gui_jchar($::config_obj->cwd)
	);

	$path = $self->gui_jg_filename_win98($path);
	$path = $self->gui_jg($path);
	$path = $::config_obj->os_path($path);

	$self->{plots}[$self->{ax}]->save($path) if $path;

	return 1;
}

sub option1_name{
	return kh_msg->get('view'); #  表示：
}

sub win_title{
	return kh_msg->get('win_title'); # 抽出語・対応分析
}

sub win_name{
	return 'w_word_corresp_plot';
}

sub base_name{
	return 'word_corresp';
}

1;