package gui_window::suggest;
use base qw(gui_window);

use utf8;
use strict;

use Tk;

sub _new{
    my $self = shift;

    $self->{win_obj}->withdraw;
    $::main_gui->mw->update;

    my $win = $self->{win_obj};
    $win->title( kh_msg->get('win_title') );

    # Get Screen dpi / scale
    if ( $^O eq 'MSWin32' ) {
        require Win32::API;
        Win32::API->Import('user32', 'GetDC', 'N', 'N');
        Win32::API->Import('user32', 'ReleaseDC', 'NN', 'N');
        Win32::API->Import('gdi32',  'GetDeviceCaps', 'NI', 'I');

        my $hdc = GetDC(0);
        my $dpi = GetDeviceCaps($hdc, 88); # 88 = LOGPIXELSX
        ReleaseDC(0, $hdc);

        my $scale = $dpi / 96; # 96dpiが100%
        print "Monitor scale: " . ($scale * 100) . "%, ";

        my @scales = qw(100 125 150 175 200 225 300 350);
        foreach my $i (@scales) {
            $self->{scale} = $i;

            if ($scale * 100 <= $i) {
                print "Using scale: $i%\n";
                last;
            }
        }
    } else {
        # For Linux and Mac, we assume 100% scale
        $self->{scale} = 100;
    }


    require Tk::NoteBook;
    $self->{nb} = $win->NoteBook()->pack(-expand => 1, -fill => 'both');

    # Tabs
    my @tabs = (
        ['proj',  kh_msg->get('gui_window::main::menu->project'), 'P'], # 'プロジェクト',
        ['prep',  kh_msg->get('gui_window::main::menu->prep'),    'R'], # '前処理',
        ['words', kh_msg->get('words'),                           'W'], # '抽出語',
        ['codes', kh_msg->get('codes'),                           'C'], # 'コーディング',
    );

    foreach my $i (@tabs) {
        my $underline_pos = -1;
        if ( $i->[2] ) {
            $underline_pos = index($i->[1], $i->[2]);
            $underline_pos += 1 if $underline_pos >= 0; # Tk::NoteBook requires +1
        }
        $self->{"page_".$i->[0]} = $self->{nb}->add(
            $i->[0],
            -label     => ' '.$i->[1].' ',
            -underline => $underline_pos,
        );
    }

    $self->make_proj_tab;
    $self->make_prep_tab;
    $self->make_words_tab;
    $self->make_codes_tab;

    # Config checkbox: show on startup?
    my $show_on_startup = $::config_obj->show_suggest_on_startup;
    $win->Checkbutton(
        -text     => kh_msg->get('show_on_startup'), #起動時にサジェスト画面を表示
        -variable => \$show_on_startup,
        -font     => "TKFN",
        -command  => sub {
            $::config_obj->show_suggest_on_startup($show_on_startup);
            $::config_obj->save;
        },
    )->pack(-side => 'left', -anchor => 'w', -padx => $self->padx, -pady => 3);

    my $stands_with_main = $::config_obj->suggest_stands_with_main;
    $win->Checkbutton(
        -text     => kh_msg->get('stands_with_main'), #メイン画面に追従
        -variable => \$stands_with_main,
        -font     => "TKFN",
        -command  => sub {
            $::config_obj->suggest_stands_with_main($stands_with_main);
            $::config_obj->save;
            if ($stands_with_main) {
                $self->win_obj->after(
                    450,
                    sub {
                        $self->follow_main;
                    }
                )
            }
        },
    )->pack(-side => 'left', -anchor => 'w', -padx => $self->padx, -pady => 3);

    # Key bindings: tabs (this window only!)
    $win->bind('<Alt-p>' => sub { $self->{nb}->raise('proj'); });
    $win->bind('<Alt-P>' => sub { $self->{nb}->raise('proj'); });
    $win->bind('<Alt-r>' => sub { $self->{nb}->raise('prep'); });
    $win->bind('<Alt-R>' => sub { $self->{nb}->raise('prep'); });
    $win->bind('<Alt-w>' => sub { $self->{nb}->raise('words'); });
    $win->bind('<Alt-W>' => sub { $self->{nb}->raise('words'); });
    $win->bind('<Alt-c>' => sub { $self->{nb}->raise('codes'); });
    $win->bind('<Alt-C>' => sub { $self->{nb}->raise('codes'); });

    $self->refresh;
    $self->follow_main if $::config_obj->suggest_stands_with_main;

    # set to natural size
    $self->{win_obj}->geometry("");
    $self->{win_obj}->update;

    # not resizable
    $self->{win_obj}->resizable(0, 0);

	$self->{win_obj}->deiconify;
	$self->{win_obj}->raise;
	$self->{win_obj}->focus;

    return $self;
}

sub delayed_follow{
    my $self = shift;
    return 0 unless $::config_obj->suggest_stands_with_main;
    
    # currently no delay
    $self->follow_main;
}

sub follow_main{
    my $self = shift;

    my $g1 = $::main_gui->{main_window}->win_obj->geometry;
    #print "gui_window::suggest::_new: main window geometry: $g1\n";
    if ( $g1 =~ /(\d+)x(\d+)\+(\-?\d+)\+(\-?\d+)/ ) {
        my $w1 = $1;
        my $h1 = $2;
        my $x1 = $3;
        my $y1 = $4;
        

        my $g2 = $self->win_obj->geometry;
        #print "gui_window::suggest::_new: suggest window geometry: $g2\n";
        if ( $g2 =~ /(\-?\d+)x(\d+)\+(\-?\d+)\+(\-?\d+)/ ) {
            my $w2 = $1;
            my $h2 = $2;
            my $x2 = $3;
            my $y2 = $4;
            
            $x2 = $x1 + $w1 + 10 * $self->{scale} / 100; # 10px for 100% scale
            $y2 = $y1;

            my $g3 = $w2.'x'.$h2.'+'.$x2.'+'.$y2;
            #print "gui_window::suggest::_new: new suggest window geometry: $g3\n";
            $self->win_obj->geometry($g3);
        }

    }

    return 1;
}

sub get_icon{
    my $self = shift;
    my $name = shift;

    # Non-Japanese icons 
    if ($::config_obj->{msg_lang} ne 'jp') {
        my $name_tr = $name . '_en';
        if ( -e Tk->findINC('si_'.$name_tr.$self->{scale}.'.png') ) { # exists
            $name = $name_tr;
        }
        elsif ( -e Tk->findINC('si_'.$name_tr.'200.png') ){           # resize
            $name = $name_tr;
        }
    }

    my $fullname = 'si_'.$name.$self->{scale}.'.png';
    $fullname = Tk->findINC($fullname);

    # resize icon if it does not exist
    unless (-e $fullname) {
        # source icon file
        my $source = 'si_'.$name.'200.png';
        $source = Tk->findINC($source);
        unless (-e $source) {
            warn "Icon source file not found: $name\n";
            return undef;
        }

        # name of resized icon file
        my $target = $::config_obj->cwd.'/kh_lib/Tk/si_'.$name.$self->{scale}.'.png';
        unless (-d $::config_obj->cwd.'/kh_lib/Tk/') {
            mkdir $::config_obj->cwd.'/kh_lib/Tk/' or do {
                warn "Failed to create directory: $::config_obj->cwd/kh_lib/Tk/\n";
                return undef;
            };
        }
        
        # resize using Image::Magick
        my $size = $self->{scale} / 200; # 200 is the original size
        unless (eval 'require Image::Magick;'){
            warn "Image::Magick is not installed. Cannot resize icon: $name\n";
            return undef;
        }
        my $image = Image::Magick->new;
        my $x = $image->Read($source);
        my ($width, $height) = $image->Get('width', 'height');
        my $new_width  = int($width  * $size);
        my $new_height = int($height * $size);

        my $b;
        if ($size < 1) {
            $b = 0.8;
        } elsif ($size > 1) {
            $b = 1.1;
        }

        $x = $image->Resize(
            width => $new_width,
            height => $new_height,
            filter => 'Lanczos',
            blur => $b
        );
        die "Failed to resize image: $x" if $x;

        $x = $image->Write($target);
        die "Failed to write image: $x" if $x;

        print "Icon resized and saved as $target\n";
        $fullname = $target;
	}

    return $self->{win_obj}->Photo(-file => $fullname);
}

sub padx{
    my $self = shift;
    return 10 * $self->{scale} / 100; # 10px for 100% scale
}

sub make_codes_tab{
    my $self = shift;

    $self->{frame_codes} = $self->{page_codes}->Frame()->pack(
        -expand => 1,
        -fill   => 'both',
    );

    # "Freq" button
    $self->{button_codes_freq} = $self->{frame_codes}->Button(
        -image    => $self->get_icon('codes_freq'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->freq').'  Ctrl + D', #単純集計
        -font     => "TKFN",
        -command  => sub { gui_window::cod_count->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Crosstab" button
    $self->{button_codes_cross} = $self->{frame_codes}->Button(
        -image    => $self->get_icon('codes_cross'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->cross_vr').'  Ctrl + B', #クロス集計
        -font     => "TKFN",
        -command  => sub { gui_window::cod_outtab->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Cluster analysis" button
    $self->{button_codes_cls} = $self->{frame_codes}->Button(
        -image    => $self->get_icon('codes_cls'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->h_cluster')."\n".'  Ctrl + U', #階層的クラスター分析
        -font     => "TKFN",
        -command  => sub { gui_window::cod_cls->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "New" button
    $self->{frame_codes}->Button(
        -image    => $self->get_icon('codes_new'),
        -compound => 'top',
        -text     => kh_msg->get('codes_new'), #新規コーディングルール・ファイル
        -font     => "TKFN",
        -command  => sub { $self->_new_codingrule; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    return 1;
}


sub make_words_tab{
    my $self = shift;

    $self->{frame_words} = $self->{page_words}->Frame()->pack(
        -expand => 1,
        -fill   => 'both',
    );

    # "Frequency list" button
    $self->{button_words_freq} = $self->{frame_words}->Button(
        -image    => $self->get_icon('words_freq'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->word_search').'  Ctrl + A', #抽出語リスト
        -font     => "TKFN",
        -command  => sub { gui_window::word_search->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Net Cloud" button
    $self->{button_words_netcloud} = $self->{frame_words}->Button(
        -image    => $self->get_icon('words_netcloud'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->net_cloud').'  Ctrl + L', #文脈クラウド
        -font     => "TKFN",
        -command  => sub { gui_window::word_net_cloud->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);
    $self->{button_words_netcloud}->configure(-state => 'disabled');

    # "Network" button
    $self->{button_words_net} = $self->{frame_words}->Button(
        -image    => $self->get_icon('words_net'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->netg').'  Ctrl + E', #共起ネットワーク
        -font     => "TKFN",
        -command  => sub { gui_window::word_netgraph->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Correspondence" button
    $self->{button_words_corr} = $self->{frame_words}->Button(
        -image    => $self->get_icon('words_corr'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->corresp').'  Ctrl + P', #対応分析
        -font     => "TKFN",
        -command  => sub { gui_window::word_corresp->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    return 1;
}

# "Pre-Processing" tab creation
sub make_prep_tab{
    my $self = shift;

    $self->{frame_prep} = $self->{page_prep}->Frame()->pack(
        -expand => 1,
        -fill   => 'both',
    );

    # "Pre-Processing" button
    $self->{button_run_prep} = $self->{frame_prep}->Button(
        -image    => $self->get_icon('prep'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->run_prep').'  Ctrl + R',#"前処理の実行",
        -font     => "TKFN",
        -command  => sub { $::main_gui->menu->mc_morpho_dialog; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Force pickup" button
    $self->{button_force_pickup} = $self->{frame_prep}->Button(
        -image    => $self->get_icon('prep_force'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->words_selection').'  Ctrl + X', #"語の取捨選択",
        -font     => "TKFN",
        -command  => sub { gui_window::dictionary->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Possible phrases" button
    $self->{button_possible_phrases} = $self->{frame_prep}->Button(
        -image    => $self->get_icon('prep_possible'),
        -compound => 'top',
        -text     => kh_msg->get('gui_window::main::menu->words_cluster').'  Ctrl + H', #"複合語の検出",
        -font     => "TKFN",
        -command  => sub {
            if ($::config_obj->c_or_j eq 'chasen'){
                $::main_gui->menu->mc_hukugo;
            }
            elsif  ($::config_obj->c_or_j eq 'mecab'){
                $::main_gui->menu->mc_noun_phrases;
            }
		    elsif (
			    (
			    	( $::config_obj->c_or_j eq 'stanford' )
			     || ( $::config_obj->c_or_j eq 'freeling' )
			    )
			    && $::project_obj->morpho_analyzer_lang eq 'en'
		    ){
                $::main_gui->menu->mc_noun_phrases;
            }
            else {
                warn("unsupported morpho_analyzer: " . $::config_obj->c_or_j);
                return 0;
            }
        }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "check morpho" button
    $self->{button_check_morpho} = $self->{frame_prep}->Button(
        -image    => $self->get_icon('prep_check'),
        -compound => 'top',
        -text     => kh_msg->get('check_morpho').'  Ctrl + K', #語の抽出結果を確認
        -font     => "TKFN",
        -command  => sub { gui_window::morpho_check->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);


    return 1;
}

# "Project" tab creation
sub make_proj_tab{
    my $self = shift;

    $self->{frame_proj} = $self->{page_proj}->Frame()->pack(
        -expand => 1,
        -fill   => 'both',
    );

    # "new project" button
    $self->{button_new_proj} = $self->{frame_proj}->Button(
        -image    => $self->get_icon('proj_new'),
        -compound => 'top',
        -text     => kh_msg->get('proj_new').'  Ctrl + N',#新規プロジェクト作成,
        -font     => "TKFN",
        #-width    => 120,
        #-height   => 120,
        -command  => sub { gui_window::project_new->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "Open Project" button
    $self->{button_open_proj} = $self->{frame_proj}->Button(
        -image    => $self->get_icon('proj_open'),
        -compound => 'top',
        -text     => kh_msg->get('proj_open').'  Ctrl + O',#"プロジェクトを開く",
        -font     => "TKFN",
        #-width    => 120,
        #-height   => 120,
        -command  => sub { gui_window::project_open->open; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "tutorial project" button
    $self->{button_tutorial_proj} = $self->{frame_proj}->Button(
        -image    => $self->get_icon('proj_tuto'),
        -compound => 'top',
        -text     => kh_msg->get('proj_tuto').'  Ctrl + T',#"チュートリアルファイルで\nプロジェクト作成",
        -font     => "TKFN",
        #-width    => 120,
        #-height   => 120,
        -command  => sub { &_tutorial_proj; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    # "tutorial project folder" button
    $self->{button_tutorial_fold} = $self->{frame_proj}->Button(
        -image    => $self->get_icon('proj_tuto_folder'),
        -compound => 'top',
        -text     => kh_msg->get('proj_tuto_folder').'  Ctrl + F',#"チュートリアルフォルダを開く",
        -font     => "TKFN",
        #-width    => 120,
        #-height   => 120,
        -command  => sub { &_tutorial_fold; }
    )->pack(-side => 'left', -padx => $self->padx, -pady => 3);

    return 1;
}

sub _new_codingrule{
    my $self = shift;

    # Directory
    my $tuto_dir = $::config_obj->cwd;
    if ($::config_obj->{msg_lang} eq 'jp') {
        $tuto_dir .= '/tutorial_jp' if -d $tuto_dir.'/tutorial_jp';
    } else {
        $tuto_dir .= '/tutorial_en' if -d $tuto_dir.'/tutorial_en';
    }

    # File name
    my $n = 1;
    my $file = $tuto_dir.'/coding_rules'.$n.'.txt';
    while (-e $::config_obj->os_path($file)) {
        ++$n;
        $file = $tuto_dir.'/coding_rules'.$n.'.txt';
    }

    # Create a new coding rule file
    open ( my $fh, '>:utf8', $::config_obj->os_path($file) ) or
		gui_errormsg->open(
			type    => 'file',
			thefile => "write: $file"
		)
    ;
    if ($::config_obj->{msg_lang} eq 'jp') {
        print $fh "＊コードの名前A\n抽出語1\n\n";
        print $fh "＊コードの名前B\n抽出語1 or 抽出語2\n\n";
        print $fh "＊コードの名前C\n( 抽出語1 or 抽出語2 ) and 抽出語3\n\n";
        print $fh "＊コードの名前D（連続して出現）\n抽出語1+抽出語2\n\n";
        print $fh "＊コードの名前E\n'文字列'\n\n";
        print $fh "# 詳しくはマニュアルを参照してください";
    } else {
        print $fh "*Code_1\nWord_A\n\n";
        print $fh "*Code_2\nWord_A or Word_B\n\n";
        print $fh "*Code_3\n( Word_A or Word_B ) and Word_C\n\n";
        print $fh "*Code_4_phrase\nWord_A+Word_B\n\n";
        print $fh "*Code_5\n'String'\n\n";
        print $fh "# Please refer to the manual for more";
    }
    close $fh;

    # Open with the system's default editor
    gui_OtherWin->open( $::config_obj->os_path($file) );

    # Set as the default coding rule file (Is this too much?)
    if ( $::project_obj ){
        $::project_obj->last_codf($file);

        foreach my $i (
            'w_cod_count',
            'w_cod_outtab',
            'w_doc_search',
            'w_doc_ass',
            'w_cod_cls',
            'w_cod_corresp',
            'w_cod_jaccard',
            'w_cod_mds',
            'w_cod_netg',
            'w_cod_som',
        ) {
            my $the_win = $::main_gui->if_opened($i);
            if ($the_win){
                $the_win = $::main_gui->get($i);
                $the_win->{codf_obj}->set($file) if $the_win->{codf_obj};
            }
        }
    }


    return 1;
}

sub _tutorial_fold{
    my $tuto_dir = $::config_obj->cwd;
    if ($::config_obj->{msg_lang} eq 'jp') {
        $tuto_dir .= '/tutorial_jp';
    } else {
        $tuto_dir .= '/tutorial_en';
    }
    $tuto_dir = $::config_obj->uni_path($tuto_dir);
    $tuto_dir =~ s/\//\\/g;
    $tuto_dir = $::config_obj->os_path($tuto_dir);
    print "Opening tutorial folder: $tuto_dir\n";
    # open the tutorial folder
    if ($^O eq 'MSWin32') {
        system("explorer.exe \"$tuto_dir\"");
    } elsif ($^O eq 'darwin') {
        system("open \"$tuto_dir\"");
    } else {
        system('xdg-open', $tuto_dir);
    }
}

sub _tutorial_proj{
    my $tutorial_file = $::config_obj->cwd;
    if ($::config_obj->{msg_lang} eq 'jp') {
        $tutorial_file .= '/tutorial_jp/kokoro.xls';
    } else {
        $tutorial_file .= '/tutorial_en/anne.xls';
    }

    # Select the tutorial file
    my $win_new_proj = gui_window::project_new->open;
    $win_new_proj->e1->delete('0','end');
    $win_new_proj->e1->insert('0', $::config_obj->uni_path($tutorial_file));
    $win_new_proj->check_path($::config_obj->os_path($tutorial_file));

    if ($::config_obj->{msg_lang} eq 'jp') {
        # Select Japanese and Chasen by default
        $win_new_proj->{lang_menu}->set_value('jp');
        $win_new_proj->refresh_method;
        $win_new_proj->{method_menu}->set_value('chasen');
    } else {
        # Select English and Stanford POS tagger by default
        $win_new_proj->{lang_menu}->set_value('en');
        $win_new_proj->refresh_method;
        $win_new_proj->{method_menu}->set_value('stanford');
    }

    $win_new_proj->{ok_btn}->focus;
}

sub refresh{
    my $self = shift;
    
    #print "gui_window::suggest::refresh\n";

    # tab selsection
    my $current = $self->{nb}->raised();
    if ($::project_obj){
        $self->{nb}->raise('proj'); # Bad hack to regain tabs which were lost
        $self->{nb}->update;        # when the window was resized
        if ($::project_obj->status_morpho){
            unless ( $current eq 'codes' ) {
                $self->{nb}->raise('words');
            }
        } else {
            $self->{nb}->raise('prep');
        }
    } else {
        $self->{nb}->raise('proj');
    }
    $self->{nb}->update;

    # button state
    my @disable;
    my @normal;


    # "Open Project" button
    my $projects = kh_projects->read->list;
    if (@{$projects}){
        push @normal, 'button_open_proj';
    } else {
        push @disable, 'button_open_proj';
    }

    # "Tutorial folder" button
    my $tuto_dir = $::config_obj->cwd;
    if ($::config_obj->{msg_lang} eq 'jp') {
        $tuto_dir .= '/tutorial_jp';
    } else {
        $tuto_dir .= '/tutorial_en';
    }
    if (-d $::config_obj->os_path($tuto_dir)){
        push @normal, 'button_tutorial_fold';
    } else {
        push @disable, 'button_tutorial_fold';
    }

    # "Tutorial Project" button
    my $tutorial_file = $::config_obj->cwd;
    if ($::config_obj->{msg_lang} eq 'jp') {
        $tutorial_file .= '/tutorial_jp/kokoro.xls';
    } else {
        $tutorial_file .= '/tutorial_en/anne.xls';
    }
    $self->{tutorial_file} = $tutorial_file;
    my $flg_tutorial = 1;
    foreach my $i (@{$projects}){
        my $check = $::config_obj->uni_path($i->file_target);
        $check =~ s/ \[.+\]$//;
        #print "i->file_target: ", $check, "\n";
        #print "tutorial_file: ", $tutorial_file, "\n";
        if ( $check eq $::config_obj->uni_path($tutorial_file)) {
            $flg_tutorial = 0;
            last;
        }
    }
    $flg_tutorial = 0 unless -e $::config_obj->os_path($tutorial_file);
    if ( $flg_tutorial ) {
        push @normal, 'button_tutorial_proj';
    } else {
        push @disable, 'button_tutorial_proj';
    }

    # Prep button
    if ($::project_obj){
        push @normal, 'button_run_prep';
        push @normal, 'button_force_pickup';
        
        
        # possible phrases button
        if (
               ( $::config_obj->c_or_j eq 'chasen')
            || ( $::config_obj->c_or_j eq 'mecab' )
        ){
            push @normal, 'button_possible_phrases';
        }
		elsif (
			(
			    ( $::config_obj->c_or_j eq 'stanford' )
			 || ( $::config_obj->c_or_j eq 'freeling' )
			)
			&& $::project_obj->morpho_analyzer_lang eq 'en'
		){
            push @normal, 'button_possible_phrases';
        }
        else {
            push @disable, 'button_possible_phrases';
        }

    } else {
        push @disable, 'button_run_prep';
        push @disable, 'button_force_pickup';
        push @disable, 'button_possible_phrases';
    }

    # Analysis buttons
    if ($::project_obj && $::project_obj->status_morpho) {
        push @normal, 'button_check_morpho';
        push @normal, 'button_words_freq';
        push @normal, 'button_words_net';
        push @normal, 'button_words_corr';
        push @normal, 'button_codes_freq';
        push @normal, 'button_codes_cross';
        push @normal, 'button_codes_cls';
    } else {
        push @disable, 'button_check_morpho';
        push @disable, 'button_words_freq';
        push @disable, 'button_words_net';
        push @disable, 'button_words_corr';
        push @disable, 'button_codes_freq';
        push @disable, 'button_codes_cross';
        push @disable, 'button_codes_cls';
    }

    # Actual button state configuration
    foreach my $i (@disable) {
        $self->{$i}->configure(-state => 'disabled');
    }
    foreach my $i (@normal) {
        $self->{$i}->configure(-state => 'normal');
    }

    return 1;
}

sub win_name{
	return 'suggest';
}



1;
