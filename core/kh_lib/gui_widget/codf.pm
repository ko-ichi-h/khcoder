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
		text => Jcode->new('コーディングルール・ファイル：')->sjis,
		font => "TKFN",
	)->pack(anchor =>'w',side => 'left');
	
	$self->{button} = $f1->Button(
		-text => Jcode->new('参照')->sjis,
		-font => "TKFN",
		-borderwidth => '1',
		-command => sub{ $f1->after(10,sub{$self->_sansyo;});}
	)->pack( -side => 'left');
	
	my $e1 = $f1->Entry(
		-state      => 'disable',
		-font       => "TKFN",
		-background => 'gray',
		-width      => 17,
	)->pack(-side => 'left',-padx => 2);
	
	if ($::project_obj->last_codf){
		my $path = $::project_obj->last_codf;
		$self->{cfile} = $path;
		substr($path, 0, rindex($path, '/') + 1 ) = '';
		$e1->configure(-state,'normal');
		$e1->insert('0',"$path");
		$e1->configure(-state,'disable');
	} else {
		$e1->configure(-state,'normal');
		$e1->insert('0',Jcode->new('選択ファイル無し')->sjis);
		$e1->configure(-state,'disable');
	}
	$self->{entry} = $e1;
	return $self;
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
		-title      => Jcode->new('コーディング・ルール・ファイルを選択してください')->sjis,
		-initialdir => $::config_obj->cwd
	);
	
	if ($path){
		$::project_obj->last_codf($path);
		$self->{cfile} = $path;
		substr($path, 0, rindex($path, '/') + 1 ) = '';
		$self->entry->configure(-state,'normal');
		$self->entry->delete(0, 'end');
		$self->entry->insert('0',Jcode->new("$path")->sjis);
		$self->entry->configure(-state,'disable');
		&{$self->{command}};
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