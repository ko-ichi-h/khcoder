package screen_code::batch_plugin::word_mds;
use strict;
use utf8;

my @need_pict_num = (1);

my %worksheet_col_hash = (
	'集計単位'  => 1,
	'サンプリング'  => 2,
	'布置される語数'  => 3,
	'無視語数'  => 4,
	'最小出現数'  => 5,
	'最大出現数'  => 6,
	'最小文章数'  => 7,
	'最大文章数'  => 8,
	'品詞'  => 9,
	'方法'  => 10,
	'距離'  => 11,
	'次元'  => 12,
	'バブルプロット'  => 13,
	'バブルの大きさ'  => 14,
	'クラスター化と色分け'  => 15,
	'クラスター数'  => 16,
	'隣接クラスター'  => 17,
	'半透明の色'  => 18,
	'縦横比固定'  => 19,
	'ランダムスタート'  => 20,
	'プロットサイズ'  => 21,
	'フォントサイズ'  => 22,
	'太字'  => 23,
);

my %display_colname_hash = (
	'布置される語数'  => '布置される語数（上位）',
	'無視語数'  => '除く最上位の語',
	'品詞'  => '品詞による語の取捨選択',
	'バブルの大きさ'  => 'バブルプロットの大きさ',
	'縦横比固定'  => '縦横比を固定する',
	'ランダムスタート'  => 'ランダムスタートを繰り返す',
);

my $worksheet_col = 23;

my $table_height = 560;

my %setting_table = (
	'サンプリング'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->sampling_obj->entry',
		'widget_hash_name' => 'words_obj->sampling_obj->entry',
	},
	'布置される語数'  => {
		'category' => 'numeric',
		'type' => 'calculation',
		'hash' => '',
	},
	'無視語数'  => {
		'category' => 'numeric',
		'type' => 'calculation',
		'hash' => '',
	},
	'最小出現数'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->ent_min',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'最大出現数'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->ent_max',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'最小文章数'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->ent_min_df',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'最大文章数'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->ent_max_df',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'集計単位'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'words_obj->tani_obj',
		'value_hash_parent' => 'words_obj->tani_obj',
		'value_hash_name' => 'raw_opt',
		'段落' => 'dan',
		'文' => 'bun',
		'H1' => 'h1',
		'H2' => 'h2',
		'H3' => 'h3',
		'H4' => 'h4',
		'H5' => 'h5',
		'dan' => '段落',
		'bun' => '文',
		'h1' => 'H1',
		'h2' => 'H2',
		'h3' => 'H3',
		'h4' => 'H4',
		'h5' => 'H5',
	},
	'方法'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->method_opt',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'method_opt',
		'Classical' => 'C',
		'Kruskal' => 'K',
		'Sammon' => 'S' ,
		'SMACOF' => 'SM',
		'C' => 'Classical',
		'K' => 'Kruskal',
		'S' => 'Sammon' ,
		'SM' => 'SMACOF',
	},
	'距離'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->method_dist',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'method_dist',
		'Jaccard' => 'binary',
		'Cosine' => 'pearson',
		'Euclid' => 'euclid',
		'binary' => 'Jaccard',
		'pearson' => 'Cosine',
		'euclid' => 'Euclid',
		'more_words_setting' => 'Cosine',
		'less_words_setting' => 'Jaccard',
	},
	'次元'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->dim_number',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'dim_number',
		'1' => 1,
		'2' => 2,
		'3' => 3,
		1 => '1',
		2 => '2',
		3 => '3',
	},
	'バブルプロット'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->check_bubble',
		'value_hash_parent' => 'mds_obj->bubble_obj',
		'value_hash_name' => 'check_bubble',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'バブルの大きさ'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'mds_obj->bubble_obj->ent_size',
		'widget_hash_name' => 'mds_obj->bubble_obj->ent_size',
	},
	'クラスター化と色分け'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->cls_if',
		'value_hash_parent' => 'mds_obj->cls_obj',
		'value_hash_name' => 'check_cls',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'クラスター数'  =>  {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'mds_obj->cls_obj->entry_cls_num',
		'min' => 1,
		'max' => 100,
		'duration' => 1,
	},
	'隣接クラスター'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->cls_nei',
		'value_hash_parent' => 'mds_obj->cls_obj',
		'value_hash_name' => 'check_nei',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'半透明の色'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->use_alpha',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'use_alpha',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'縦横比固定'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->fix_asp',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'fix_asp',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'ランダムスタート'  => {
		'type' => 'hash',
		'hash' => 'mds_obj->check_random_start',
		'value_hash_parent' => 'mds_obj',
		'value_hash_name' => 'check_random_start',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'プロットサイズ'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'font_obj->entry_plot_size',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'太字'  => {
		'category' => 'numeric',
		'type' => 'hash',
		'hash' => 'font_obj->check_bold_text',
		'value_hash_parent' => 'font_obj',
		'value_hash_name' => 'check_bold_text',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'フォントサイズ'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'font_obj->entry_font_size',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'品詞'  => {
		'category' => 'string',
		'type' => 'hinshi',
		'hash' => '',
	},
);


sub get_analysis_name{
	return "多次元尺度法";
}

sub need_pict_num{
	return \@need_pict_num;
}

sub setting_table{
	return \%setting_table;
}

sub worksheet_col_hash{
	return \%worksheet_col_hash;
}

sub display_colname_hash{
	return \%display_colname_hash;
}

sub worksheet_col{
	return $worksheet_col;
}

sub r_command_package{
	return "gui_window::word_mds";
}

sub r_command_method_str{
	return "r_command_plot";
}

sub r_command_method_type{
	return 1;
}

sub discript_plot_ratio{
	return 1.85;
}

sub other_expand_plot_num{
	return '_1';
}

sub match_str{
	return 'grid.draw\(g\)';
}

sub replace_str{
	#return 'g <- g + ggtitle("replace_target") + theme(plot.title=element_text(size=8,colour="black",hjust = 0))
# aspect ratio
#'

return '
library(gridExtra)

replace_target
settings <- matrix(settings, nrow=2)
df_test <- data.frame(settings)
df_test <- as.data.frame(t(df_test))

setting_theme <- ttheme_default(base_colour = "blue")
mytheme <- gridExtra::ttheme_default(
    core = list(fg_params = list(fontsize = 8, fontfamily = font_family))
)
g_test<-tableGrob(df_test, theme=mytheme, rows=NULL, cols=NULL)


layout1<- ratio_replace
g_arranged <- grid.arrange(g, g_test, layout_matrix=layout1)

grid.draw(g_arranged)
'
}

sub ratio_set_method{
	my $use_option_table = shift;
	my %args = @_;
	#print "call ratio_set_method use_option_table=$use_option_table\n";
	
	if (exists($args{command_f})) {
		#print "\ncommand_f = ".$args{command_f}." \n\n";
		my $command_str = $args{command_f};
		my $ratio_str = 'rbind(';
		
		for (my $i = 0; $i < $args{height}/ 20; $i++) {
			$ratio_str .= ', ' if $i;
			$ratio_str .= 'c(1,1)';
		}
		
		for (my $i = 0; $i < $table_height / 20; $i++) {
			$ratio_str .= ', ';
			$ratio_str .= 'c(2,2)';
		}
		$ratio_str .= ')';
		
		$command_str =~ s/ratio_replace/$ratio_str/;
		$args{command_f} = $command_str;
		#print "\ncommand_f = ".$args{command_f}." \n\n";
	}
	if (exists($args{command_s})) {
		#print "\ncommand_s = ".$args{command_s}." \n\n";
		my $command_str = $args{command_s};
		my $ratio_str = 'rbind(';
		
		for (my $i = 0; $i < $args{height}/ 20; $i++) {
			$ratio_str .= ', ' if $i;
			$ratio_str .= 'c(1,1)';
		}
		
		for (my $i = 0; $i < $table_height / 20; $i++) {
			$ratio_str .= ', ';
			$ratio_str .= 'c(2,2)';
		}
		$ratio_str .= ')';
		
		$command_str =~ s/ratio_replace/$ratio_str/;
		$args{command_s} = $command_str;
		#print "\ncommand_s = ".$args{command_s}." \n\n";
	}
	if (exists($args{command_a})) {
		#print "\ncommand_a = ".$args{command_a}." \n\n";
		my $command_str = $args{command_a};
		my $ratio_str = 'rbind(';
		
		for (my $i = 0; $i < $args{height}/ 20; $i++) {
			$ratio_str .= ', ' if $i;
			$ratio_str .= 'c(1,1)';
		}
		
		for (my $i = 0; $i < $table_height / 20; $i++) {
			$ratio_str .= ', ';
			$ratio_str .= 'c(2,2)';
		}
		$ratio_str .= ')';
		
		$command_str =~ s/ratio_replace/$ratio_str/;
		$args{command_a} = $command_str;
		#print "\ncommand_a = ".$args{command_a}." \n\n";
	}
	
	if ($use_option_table) {
		#print "height = ".$args{height}." \n";
		#print "width = ".$args{width}." \n";
		
		$args{height} += $table_height;
		#print "height_changed = ".$args{height}." \n";
	}
	
	return \%args;
}


1;