package gui_errormsg::print::gui_tk;
use strict;
use base qw(gui_errormsg::print);

# ダイアログボックス表示
sub print{
	use Tk;
	my $self = shift;

	# 親Windowが存在するかどうかを確認
	my $window;
	if (Exists(${$self->{window}})){
		$window = ${$self->{window}};
	}
	elsif (Exists($::main_gui->mw)) {
		$window = $::main_gui->mw;
	}
	
	if ($window){
		$window->messageBox(
			-icon => $self->icon,
			-type => 'OK',
			-title => 'KH Coder',
			-message => gui_window->gui_jchar("$self->{msg}"),
		);
	} else {
		# use Win32;
		# Win32::MsgBox("$self->{msg}",'16','KH Coder');
		print "$self->{msg}\n";
	}

}

# デフォルトのダイアログ形式

sub icon{
	my $self = shift;
	if ($self->{icon}){
		return $self->{icon};
	} else {
		return 'warning';
	}
}


1;
