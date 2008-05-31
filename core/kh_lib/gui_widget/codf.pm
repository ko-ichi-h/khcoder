package gui_widget::codf;
use base qw(gui_widget);
use strict;
use Tk;
use Jcode;

sub _new{
	my $self = shift;
	my $f1 = $self->parent->Frame()->pack();
	$self->{win_obj} = $f1;
	
	$self->{label} = $f1->Label(
		-text => gui_window->gui_jchar('コーディングルール・ファイル：'),
		-font => "TKFN",
	)->pack(-anchor =>'w',-side => 'left');
	
	$self->{button} = $f1->Button(
		-text => gui_window->gui_jchar('参照'),
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $f1->after(10,sub{$self->_sansyo;});}
	)->pack( -side => 'left');
	
	if ($self->{r_button}){
		$self->{button} = $f1->Button(
			-text => gui_window->gui_jchar('リロード'),
			-font => "TKFN",
			-borderwidth => '1',
			-command => sub{ $f1->after(10,sub{
				if (defined($self->{command})){
					&{$self->{command}};
				}
			});}
		)->pack( -side => 'left', -padx => 2);
	}
	
	my $e1 = $f1->Entry(
		-state      => 'disable',
		-font       => "TKFN",
		-background => 'gray',
		-width      => 17,
	)->pack(-side => 'left',-padx => 2, -fill => 'x', -expand => '1');
	gui_window->disabled_entry_configure($e1);
	
	$f1->DropSite(
		-dropcommand => sub{ $self->_drop(@_); },
		-droptypes   => ($^O eq 'MSWin32' ? 'Win32' : ['XDND', 'Sun'])
	);
	
	if ($::project_obj->last_codf){
		my $path = $::project_obj->last_codf;
		#print "$path\n";
		$self->{cfile} = $path;
		substr($path, 0, rindex($path, '/') + 1 ) = '';
		$e1->configure(-state,'normal');
		$e1->insert('0',gui_window->gui_jchar($path));
		$e1->configure(-state,'disable');
	} else {
		$e1->configure(-state,'normal');
		$e1->insert('0',gui_window->gui_jchar('選択ファイル無し'));
		$e1->configure(-state,'disable');
	}
	$self->{entry} = $e1;
	return $self;
}

sub _drop{
	my $self      = shift;
	my $selection = shift;

	my $path;

	eval {
		if ($^O eq 'MSWin32') {
			$path = $self->{win_obj}->SelectionGet(
				-selection => $selection,
				'STRING'
			);
		} else {
			$path = $self->{win_obj}->SelectionGet(
				-selection => $selection,
				'FILE_NAME'
			);
		}
	};

	if ($] > 5.008){
		utf8::decode($path);
	}
	# else {
	# 	$path = gui_window->gui_jg($path);
	# }

	$path = $::config_obj->os_cod_path($path);

	if (-e $path) {
		$::project_obj->last_codf($path);
		$self->{cfile} = $path;
		substr($path, 0, rindex($path, '/') + 1 ) = '';
		$self->entry->configure(-state,'normal');
		$self->entry->delete(0, 'end');
		$self->entry->insert('0',gui_window->gui_jchar("$path"));
		$self->entry->configure(-state,'disable');
		if (defined($self->{command})){
			&{$self->{command}};
		}
	}
}

#------------------#
#   参照ルーチン   #
sub _sansyo{
	my $self = shift;

	my @types = (
		[ "coding rule files",[qw/.txt .cod/] ],
		["All files",'*']
	);

	my $path = $self->win_obj->getOpenFile(
		-filetypes  => \@types,
		-title      => gui_window->gui_jchar('コーディング・ルール・ファイルを選択してください'),
		-initialdir => gui_window->gui_jchar($::config_obj->cwd),
	);
	
	if ($path){
		$path = gui_window->gui_jg($path);
		$path = $::config_obj->os_cod_path($path);

		$::project_obj->last_codf($path);
		$self->{cfile} = $path;
		substr($path, 0, rindex($path, '/') + 1 ) = '';
		$self->entry->configure(-state,'normal');
		$self->entry->delete(0, 'end');
		$self->entry->insert('0',gui_window->gui_jchar("$path"));
		$self->entry->configure(-state,'disable');
		if (defined($self->{command})){
			&{$self->{command}};
		}
	}
}

#--------------#
#   アクセサ   #

sub normal{
	my $self = shift;
	$self->{button}->configure(-state => 'normal');
	$self->{label}->configure(-foreground => 'black');
}
sub disable{
	my $self = shift;
	$self->{button}->configure(-state => 'disable');
	$self->{label}->configure(-foreground => 'gray');
}

sub cfile{
	my $self = shift;
	return $self->{cfile};
}

sub entry{
	my $self = shift;
	return $self->{entry};
}

1;