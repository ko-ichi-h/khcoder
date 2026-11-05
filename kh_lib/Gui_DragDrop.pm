package Gui_DragDrop;
use strict;

#-----------------------#
#   Hlistへのドロップ   #
#-----------------------#

sub read_CodeFile_droped{
	my %args = @_;
	my $filename;

	eval {
		if ($^O eq 'MSWin32') {
			$filename = $args{widget}->SelectionGet(
				-selection => $args{selection},
				'STRING'
			);
		} else {
			$filename = $args{widget}->SelectionGet(
				-selection => $args{selection},
				'FILE_NAME'
			);
		}
	};
	
	if ($] > 5.008){
		utf8::decode($filename);
	}
	
	if (-e $filename) {
		$args{selected} = $filename;
		my @args_for_code = %args;
		my @return = Gui_lib::read_selected_coderule(@args_for_code);
		return (@return);
	}
}


#-----------------------#
#   Entryへのドロップ   #
#-----------------------#
# ・Entry上にドロップされたファイルの名前を挿入
#
# ・呼び出し
# $EntryWidget->DropSite(
# 	-dropcommand => [\&Gui_DragDrop::get_filename_droped, $EntryWidget,],
# 	-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
# );

sub get_filename_droped{
	my($widget, $selection) = @_;
	my $filename;
	#print "widg: $widget\n";
	#print "sele: $selection\n";
	unless (length($selection)){
		$selection = 'CLIPBOARD';
	}
	eval {
		if ($^O eq 'MSWin32') {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'STRING'
			);
		} else {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'FILE_NAME'
			);
		}
	};
	
	if ($] > 5.008){
		utf8::decode($filename);
		$filename =~ s/\\/\//g;
	}
	
	if (-e $filename) {
		$widget->delete('0','end');
		$widget->insert(0,gui_window->gui_jchar($filename));
	}
}

#----------------------#
#   Textへのドロップ   #
#----------------------#
# ・Text上にドロップされたファイル内容を読み込んで挿入
#
# ・呼び出し
# $TextWidget->DropSite(
# 	-dropcommand => [\&Gui_DragDrop::read_TextFile_droped,$t],
# 	-droptypes => ($^O eq 'MSWin32' ? 'Win32' : ['KDE', 'XDND', 'Sun'])
# );

sub read_TextFile_droped{
	my($widget, $selection) = @_;
	my $filename;
	eval {
		if ($^O eq 'MSWin32') {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'STRING'
			);
		} else {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'FILE_NAME'
			);
		}
	};

	if ($] > 5.008){
		# UTF8フラグ付なのに、Windowsのコマンドプロンプトにprintしても文字化
		# けしないという変なものが帰ってくるので、それに対応。なぜこれでうま
		# くいくのか今ひとつよく分からないのだが...
		utf8::decode($filename);
	}
	
	if (-e $filename) {
		my $icode = kh_jchar->check_code($filename);
		open (DROPED,"$filename") or
			gui_errormsg->open(
				type    => 'file',
				thefile => "$filename"
			);
		while (<DROPED>){
			chomp;
			my $t = gui_window->gui_jchar($_, $icode);
			$widget->insert('end',"$t\n");
		}
		close (DROPED);
	}
}

#-------------------------------------------------#
#   Drop to open the "New Project" window         #
#-------------------------------------------------#
# - When a data file is dropped on the main window or the suggest window,
#   open the "New Project" window and select the file as if it was chosen
#   with the "Browse" button.
# - Only the first file is used when multiple files are dropped at once.
#
# - Usage:
# Gui_DragDrop::new_project_site($Toplevel);

sub new_project_site{
	my $win = shift;
	return $win->DropSite(
		-dropcommand => [\&open_new_project_droped, $win],
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
}

my $new_project_droped = 0;

sub open_new_project_droped{
	my($widget, $selection) = @_;

	# Win32: the callback is called once per file. Ignore the rest.
	return 0 if $new_project_droped;

	unless (length($selection)){
		$selection = 'CLIPBOARD';
	}
	my $filename;
	eval {
		if ($^O eq 'MSWin32') {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'STRING'
			);
		} else {
			$filename = $widget->SelectionGet(
				-selection => $selection,
				'FILE_NAME'
			);
		}
	};
	return 0 unless defined($filename) && length($filename);

	# SelectionGet returns the raw bytes of the file system encoding
	# (as characters). Turn them back into bytes and decode them.
	utf8::downgrade($filename, 1);
	my $path = $::config_obj->uni_path($filename);

	# Supported file types: same as the "Browse" button
	unless ( gui_window::project_new->is_data_file($path) ){
		# STDOUT has the ":encoding(console_out)" layer:
		# print the decoded path, not the os_path() bytes
		print "Drag & Drop: not a supported file: $path\n";
		return 0;
	}

	$new_project_droped = 1;
	$widget->afterIdle(
		sub {
			$new_project_droped = 0;
			my $win = gui_window::project_new->open or return 0;
			$win->set_target_file($path);
			$win->win_obj->focusForce;
		}
	);
	return 1;
}

1;