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

1;