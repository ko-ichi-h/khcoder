package screen_code::negationchecker;
use strict;
use utf8;

use screen_code::plugin_path;

use gui_window::main::menu;
use Encode qw/encode decode/;
use Tk::DialogBox;

my $use_plug_flag;
my $image_file = File::Spec->catfile('screen', 'MonkinNegationChecker', '/systemicon_q.png');
my $icon_file = File::Spec->catfile('screen', 'MonkinNegationChecker', '/1.ico');

sub plugin_dialog{
	#プラグインが存在しない場合は戻って通常の前処理を行う
	return 0 unless (-f &screen_code::plugin_path::negationchecker_path);
	
	my $self = shift;
	my $mw = shift;
	
	my $reload = 0;
	$use_plug_flag = &screen_code::plugin_path::read_inifile("use_NagationChecker", 0);
	my $buttons;
	my $messeage;
	my $add_width = 0;
	my $add_height = 0;
	if ( $::project_obj->reloadable) {
		$buttons = [kh_msg->get('screen_code::assistant->dialog_yes'), kh_msg->get('screen_code::assistant->dialog_no'), kh_msg->get('screen_code::assistant->dialog_cancel')];
		$messeage = kh_msg->get('gui_window::main::menu->prepro_reload');
		$add_width = 100;
		$add_height = 40;
	} else {
		$buttons = [kh_msg->get('screen_code::assistant->dialog_ok'), kh_msg->get('screen_code::assistant->dialog_cancel')];
		$messeage = kh_msg->gget('cont_big_pros');
	}
	my $d = $mw->DialogBox(-title => "KH Coder", -buttons => $buttons,);
	$d->resizable(0,0);
	$d->iconbitmap("$icon_file");
	
	my $image = $mw->Photo(-file => $image_file);
	
	$d->add(
		'Canvas',
		-bg => 'white',
		-width => 300 + $add_width,
		-height => 120 + $add_height,
	)->pack(
		-anchor => 'n',
		-side  => 'top',
	);
	$d->add(
		'Label',
		-bg => 'white',
		-image => $image,
	)->place(-x => 30, -y => 30);
	$d->add(
		'Label',
		-bg => 'white',
		-justify => 'left',
		-text => $messeage,
	)->place(-x => 65, -y => 27);
	
	my $use_check = $d->add(
		'Checkbutton',
		-bg => 'white',
		-text => kh_msg->get('screen_code::assistant->dialog_use_plugin'),
		-variable => \$use_plug_flag
	)->place(-x => 65, -y => 80 + $add_height);
	
	my $ans = $d->Show;
	unless ($ans){ return 1; }
	if ($ans =~ /cancel|キャンセル/i){ return 1; }
	if ($ans =~ /Yes|はい/i) { $reload = 1; }
	#iniファイルに記録する
	&screen_code::plugin_path::save_inifile("use_NagationChecker", $use_plug_flag);
	#プラグインライセンス確認
	if ($use_plug_flag) {
		return 1 unless(system(&screen_code::plugin_path::negationchecker_path, 1));
	}
	
	$self->mc_morpho($reload);
	
	return 1;
}


sub add_label{
	my $self = shift;
	my $mw = shift;
	
	if (-f &screen_code::plugin_path::negationchecker_path) {
		my $f = $mw->Frame(-relief => 'flat')->pack(-anchor => 'w', -side => 'left');
		$f->Label(
			-text => kh_msg->get('screen_code::assistant->label_use_plugin'),
			-font => 'TKFN',
			-justify => 'left',
		)->pack(-anchor => 'n', -side => 'top');
		if (&screen_code::plugin_path::read_inifile("use_NagationChecker", 0)) {
			$f->Label(
				-text => kh_msg->get('screen_code::assistant->label_enable'),
				-foreground => 'Blue',
				-font => 'TKFN',
				-justify => 'left',
			)->pack(-anchor => 'n', -side => 'top');
		} else {
			$f->Label(
				-text => kh_msg->get('screen_code::assistant->label_disable'),
				-foreground => 'red',
				-font => 'TKFN',
				-justify => 'left',
			)->pack(-anchor => 'n', -side => 'top');
		}
	}
}

sub add_menu{
	my $self = shift;
	my $mw = shift;
	my $f = shift;
	my $menu0_ref = shift;
	
	$use_plug_flag = 0;
	
	if (-f &screen_code::plugin_path::negationchecker_path) {
		
		
		push @{$menu0_ref}, 'm_b1_plugin';
		$self->{m_b1_plugin} = $f->command(
			-label => kh_msg->get('screen_code::assistant->use_negationchecker'),
			-font => "TKFN",
			-command => sub{
				$use_plug_flag = 0;
				my $d = $mw->DialogBox(-title => "Title", -buttons => ["Yes", "No", "Cancel"],);
				$d->resizable(0,0);
				
				$d->add(
					'Canvas',
					-bg => 'white',
					-width => 300,
					-height => 120,
				)->pack(
					-anchor => 'w',
					-side  => 'left',
				);
				
				#$d->add(
				#	'Label',
				#	-bitmap => 'info',
				#	-text => kh_msg->gget('cont_big_pros'),
				#)->pack(
				#	-anchor => 'w',
				#	-side  => 'left',
				#);
				
				$d->add(
					'Label',
					-bg => 'white',
					-bitmap => 'info',
				)->place(-x => 30, -y => 30);
				
				#$d->add(
				#	'Label',
				#	-text => kh_msg->gget('cont_big_pros'),
				#)->pack(
				#	-anchor => 'w',
				#	-side  => 'left',
				#);
				$d->add(
					'Label',
					-bg => 'white',
					-justify => 'left',
					-text => kh_msg->gget('cont_big_pros'),
				)->place(-x => 55, -y => 27);
				
				my $use_check = $d->add(
					'Checkbutton',
					-bg => 'white',
					-text => 'use plugin',
					-variable => \$use_plug_flag
				)->place(-x => 30, -y => 80);
				
				
				#$use_check->configure(-state => 'disabled');
				$d->Show;
				return 0;
			
				#プラグインライセンス確認
				return 0 unless(system(&screen_code::plugin_path::negationchecker_path, 1));
				my $ans = $mw->messageBox(
					-message => kh_msg->gget('cont_big_pros'),
					-icon    => 'question',
					-type    => 'OKCancel',
					-title   => 'KH Coder'
				);
				unless ($ans =~ /ok/i){ return 0; }
				$use_plug_flag = 1;
				$self->mc_morpho;
			},
			-state => 'disable',
		);
	}
}

sub check_use_plug{
	if ($use_plug_flag) {
		my $file = $::config_obj->os_path( $::project_obj->file_MorphoOut );
		system(&screen_code::plugin_path::negationchecker_path, "$file", $::config_obj->c_or_j);
	}
	$use_plug_flag = 0;
}

1;