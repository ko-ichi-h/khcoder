package gui_window::topic_fitting;
use base qw(gui_window);
use utf8;

use strict;
use Tk;

use gui_widget::words;
use mysql_crossout;

#-------------#
#   GUI作製   #

sub _new{
	my $self = shift;
	my $mw = $::main_gui->mw;
	my $win = $self->{win_obj};
	$win->title($self->gui_jt($self->label));

	my $lf_w = $win->LabFrame(
		-label       => kh_msg->get('gui_window::word_cls->u_w'), # 集計単位と抽出語の選択
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'both', -expand => 0, -side => 'left',-anchor => 'w');

	my $rf = $win->Frame()
		->pack(-fill => 'x', -expand => 1, -anchor => 'n');

	my $lf = $rf->LabFrame(
		-label       => kh_msg->get('opt'), # トピックモデルのオプション
		-labelside   => 'acrosstop',
		-borderwidth => 2,
		-foreground  => 'blue',
	)->pack(-fill => 'x', -expand => 1, -anchor => 'n');

	$self->{words_obj} = gui_widget::words->open(
		parent => $lf_w,
		verb   => kh_msg->get('gui_window::doc_cls->verb'), # 使用
		sampling     => 0,
		command      => sub{
			$self->calc;
		},
		tani_gt_1    => 1,
	);

	# トピックモデルのオプション

	my $f_f = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$f_f->Label(
		-text => kh_msg->get('n_topics'), # N of topics
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_n_topics} = $f_f->Entry(
		-font       => "TKFN",
		-width      => 4,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);

	$self->{entry_n_topics}->insert(0, '12');
	$self->{entry_n_topics}->bind("<Key-Return>", sub{ $self->calc; });
	$self->{entry_n_topics}->bind("<KP_Enter>", sub{ $self->calc; });
	gui_window->config_entry_focusin( $self->{entry_n_topics} );
	
	my $f_c = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 2
	);

	$rf->Checkbutton(
			-text     => kh_msg->gget('r_dont_close'),
			-variable => \$self->{check_rm_open},
			-anchor => 'nw',
	)->pack(-anchor => 'nw');

	$win->Button(
		-text => kh_msg->gget('cancel'),
		-font => "TKFN",
		-width => 8,
		-command => sub{$self->withd;}
	)->pack(-side => 'right',-padx => 2, -pady => 2, -anchor => 'se');

	$win->Button(
		-text => kh_msg->gget('ok'),
		-width => 8,
		-font => "TKFN",
		-command => sub{$self->calc;}
	)->pack(-side => 'right', -pady => 2, -anchor => 'se')->focus;

	return $self;
}

sub start_raise{
	my $self = shift;
	$self->{words_obj}->settings_load;
}

sub start{
	my $self = shift;

	# Windowを閉じる際のバインド
	$self->win_obj->bind(
		'<Control-Key-q>',
		sub{ $self->withd; }
	);
	$self->win_obj->bind(
		'<Key-Escape>',
		sub{ $self->withd; }
	);
	$self->win_obj->protocol('WM_DELETE_WINDOW', sub{ $self->withd; });
}

#----------#
#   実行   #

sub calc{
	my $self = shift;
	
	# 入力のチェック
	unless ( eval(@{$self->hinshi}) ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->get('gui_window::word_corresp->select_pos'), # please select at least 1 POS
		)
	;
		return 0;
	}

	# number of cases
	my $cases = mysql_exec->select("select count(*) from ".$self->tani,1)->hundle->fetch->[0];
	unless ( $cases > 1 ){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('to_few_cases')." [$cases]",
		);
		return 0;
	}

	my $check_num = mysql_crossout::r_com->new(
		tani     => $self->tani,
		tani2    => $self->tani,
		hinshi   => $self->hinshi,
		max      => $self->max,
		min      => $self->min,
		max_df   => $self->max_df,
		min_df   => $self->min_df,
	)->wnum;
	$check_num =~ s/,//g;

	if ($check_num < 12){
		gui_errormsg->open(
			type => 'msg',
			msg  => kh_msg->gget('select_3words'), # You need more words to perform this analysis
		);
		return 0;
	}

	$self->{words_obj}->settings_save;

	my $w = gui_wait->start;

	# Extract data for the analysis
	my $r_data_obj = mysql_crossout::r_com->new(
		tani   => $self->tani,
		tani2  => $self->tani,
		hinshi => $self->hinshi,
		max    => $self->max,
		min    => $self->min,
		max_df => $self->max_df,
		min_df => $self->min_df,
		rownames => 0,
		sampling => $self->{words_obj}->sampling_value,
		not_word_but_id => 1,
	);
	my $r_command = $r_data_obj->run;
	$r_command .= "\n# END: DATA\n";
	my %names = %{$r_data_obj->{wName}};
	$r_data_obj = undef;

	# Commands for fitting the Topic Model
	my $n_topics = gui_window->gui_jgn( $self->{entry_n_topics}->get );
	$r_command .= &r_command_lda( $n_topics );
	
	$::config_obj->R->send( $r_command );
	print $::config_obj->R->read();
	#print "$r_command\n\n";

	# Save the result into tmp files 1: R data
	my $save_r = $::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_topicR'
	;
	if ( -e $save_r ){
		unlink $save_r;
	}
	$::config_obj->R->send(
		"save(result_lda, file=\""
		.$::config_obj->uni_path( $save_r )
		."\" )\n"
	);
	print $::config_obj->R->read();

	# Save the result into tmp files 2: Term
	my $save_tm = $::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_topicTM'
	;
	if ( -e $save_tm ){
		unlink $save_tm;
	}
	$::config_obj->R->send(
		'write.table(posterior(result_lda)$terms, file = "'
		.$::config_obj->uni_path( $save_tm )
		.'",fileEncoding="UTF-8",sep="\t",quote=F,col.names=NA )'
	);
	print $::config_obj->R->read();

	# Save the result into tmp files 3: Topic
	my $save_tp = $::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_topicTP'
	;
	if ( -e $save_tp ){
		unlink $save_tp;
	}
	$::config_obj->R->send(
		'write.table(posterior(result_lda)$topics, file = "'
		.$::config_obj->uni_path( $save_tp )
		.'",fileEncoding="UTF-8",sep="\t",quote=F,col.names=NA )'
	);
	print $::config_obj->R->read();

	# Save the result into tmp files 4: Topic-CSV
	my $save_tp_csv = $::config_obj->cwd
		.'/config/R-bridge/'
		.$::project_obj->dbname
		.'_topicTP.csv'
	;
	
	my $tsv = Text::CSV_XS->new({            # open source file
		binary => 1,
		auto_diag => 2,
		sep_char  => "\t"
	} );
	use File::BOM;
	File::BOM::open_bom (my $fh, $save_tp, ":encoding(utf8)" );
	gui_errormsg->open(
		type => 'file',
		file => $save_tp
	) unless $fh;
	
	use File::BOM;                          # open export file
	open (my $of, '>:encoding(utf8):via(File::BOM)', $save_tp_csv) or
		gui_errormsg->open(
			type    => 'file',
			thefile => $save_tp_csv
		)
	;
	my $csv = Text::CSV_XS->new ( { binary => 1, auto_diag => 2 } );
	
	my $max = mysql_exec->select(           # export
		"SELECT count(*) FROM ".$self->tani
	)->hundle->fetch->[0];
	
	my @dummy = ();
	$dummy[$n_topics] = "";
	
	my $n = 1;
	my $flag = 0;
	while ( my $row = $tsv->getline($fh) ){
		if ($flag == 0) {                   # the 1st line
			my $col = 0;
			foreach my $i (@{$row}){
				if ($col) {
					if ($i < 10){
						$i = '0'."$i";
					}
					$i = '_topic_'.$i;
				} else {
					$i = '_topic_docid'
				}
				++$col;
			}
			$csv->print($of, $row);
			print $of "\n";
			++$flag;
			next;
		}
		
		if ($row->[0] > $n) {               # 2nd and so on
			while ( $row->[0] > $n ) {
				my $current = \@dummy;
				$current->[0] = $n;
				$csv->print($of, $current);
				print $of "\n";
				++$n;
			}
		}
		$csv->print($of, $row);
		print $of "\n";
		++$n;
	}
	
	while ($n <= $max) {
		my $current = \@dummy;
		$current->[0] = $n;
		$csv->print($of, $current);
		print $of "\n";
		++$n;
	}
	close ($fh);
	close ($of);
	
	#$::config_obj->R->send("print( terms(result_lda, 10) )");
	#print $::config_obj->R->read;

	$w->end(no_dialog => 1);
	unless (-e $save_r && -e $save_tm && -e $save_tp && -e $save_tp_csv){
		gui_errormsg->open(
			type => 'msg',
			msg  => 'Error in fitting the model...',
		);
		return 0;
	}
	unless ( $self->{check_rm_open} ){
		$self->withd;
	}
	
	if ($::main_gui->if_opened('w_topic_result')){
		$::main_gui->get('w_topic_result')->close;
	}
	
	gui_window::topic_result->open(
		tani            => $self->tani,
		used_words      => $check_num,
		n_topics        => $n_topics,
		file_r          => $save_r,
		file_term       => $save_tm,
		file_topics     => $save_tp,
		file_topics_csv => $save_tp_csv,
		names           => \%names,
	);
	return 1;
}


#--------------#
#   アクセサ   #


sub label{
	return kh_msg->get('win_title');
}

sub win_name{
	return 'w_topic_fitting';
}

sub min{
	my $self = shift;
	return $self->{words_obj}->min;
}
sub max{
	my $self = shift;
	return $self->{words_obj}->max;
}
sub min_df{
	my $self = shift;
	return $self->{words_obj}->min_df;
}
sub max_df{
	my $self = shift;
	return $self->{words_obj}->max_df;
}
sub tani{
	my $self = shift;
	return $self->{words_obj}->tani;
}
sub hinshi{
	my $self = shift;
	return $self->{words_obj}->hinshi;
}

sub r_command_lda{
	my $n_topics = shift;
	
	my $t = '
#dtm <- t(d)
dtm <- d
rownames(dtm) <- 1:nrow(dtm)
dtm <- dtm[rowSums(dtm) > 0,]

library(topicmodels)

result_lda <- topicmodels::LDA(dtm, k = '.$n_topics.', method = "Gibbs"';

	$t .= ", control = list(seed = 1234567,  burnin = 1000)";
	$t .= ')';

	return $t;
}


1;