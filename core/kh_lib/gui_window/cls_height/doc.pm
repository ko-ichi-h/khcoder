package gui_window::cls_height::doc;
use strict;
use utf8;
use base qw(gui_window::cls_height);

use File::Copy;

sub _save{
	my $self = shift;
	my $path = shift;
	
	if ($path =~ /\.r$/){
		# tmpファイル名取得
		my $file_tmp = '';
		if (
			$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
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
				-message => $self->gui_jchar
					(
					   kh_msg->get('overwr') # このファイルを上書きしてよろしいですか：
					   ."\n"
					   .$::config_obj->uni_path($file_csv)
					),
				-icon    => 'question',
				-type    => 'OKCancel',
				-title   => 'KH Coder'
			);
			unless ($ans =~ /ok/i){ return 0; }
			unlink($file_csv);
		}
		copy($file_tmp, $file_csv)
			or gui_errormsg->open(
				type => 'file',
				file => $file_csv,
			);

		# rコマンドの変更
		$file_csv = $::config_obj->uni_path($file_csv);
		if ($::config_obj->os eq 'win32'){
			$file_csv =~ s/\\/\\\\/g;
		}
		$self->{plots}{$self->{type}}{$self->{range}}->{command_f}
			=~ s/^.+read.csv\(.+?\)\n/\n/;
		$self->{plots}{$self->{type}}{$self->{range}}->{command_f} =
			'd <- read.csv("'.$file_csv.'",fileEncoding="UTF-8-BOM")'."\n"
			.$self->{plots}{$self->{type}}{$self->{range}}->{command_f};
	}
	
	$self->{plots}{$self->{type}}{$self->{range}}->save($path) if $path;
}

sub win_title{
	my $self = shift;
	return $self->gui_jt(kh_msg->get('win_title')); # 文書のクラスター分析：併合水準','euc
}

sub win_name{
	return 'w_doc_cls_height';
}

1;