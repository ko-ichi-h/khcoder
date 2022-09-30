package screen_code::batch_plugin::word_corresp;
use strict;
use utf8;

my @need_pict_num = (1);

my %worksheet_col_hash = (
	'布置される語数'  => 1,
	'無視語数'  => 2,
	'最小出現数'  => 3,
	'最大出現数'  => 4,
	'最小文章数'  => 5,
	'最大文章数'  => 6,
	'文章と見なす単位'  => 7,
	'品詞'  => 8,
	'サンプリング'  => 9,
	'分析に使用する対象'  => 10,
	'外部変数'  => 11,
	'集計単位'  => 12,
	'同時布置'  => 13,
	'差異が顕著な語使用'  =>  14,
	'差異が顕著な語数'  =>  15,
	'原点から離れた語のみ使用'  => 16,
	'原点から離れた語数'  => 17,
	'バブルプロット'  => 18,
	'バブルの大きさ'  => 19,
	'スコア'  => 20,
	'原点表示'  => 21,
	'フォントサイズ'  => 22,
	'太字'  => 23,
	'プロットサイズ'  => 24,
);

my %display_colname_hash = (
	'布置される語数'  => '布置される語数（上位）',
	'無視語数'  => '除く最上位の語',
	'品詞'  => '品詞による語の取捨選択',
	'分析に使用する対象'  => '使用するデータ表の種類',
	'差異が顕著な語使用'  => '差異が顕著な語を分析に使用',
	'差異が顕著な語数'  => '使用する差異が顕著な語の数',
	'原点から離れた語のみ使用'  => '原点から離れた語のみラベル表示',
	'原点から離れた語数'  => 'ラベル表示する原点から離れた語の数',
	'バブルの大きさ'  => 'バブルプロットの大きさ',
	'縦横比固定'  => '縦横比を固定する',
	'ランダムスタート'  => 'ランダムスタートを繰り返す',
	'原点表示'  => '原点を表示',
);

my $worksheet_col = 25;

my $table_height = 480;

my %setting_table = (
	'サンプリング'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'sampling_obj->entry',
		'widget_hash_name' => 'sampling_obj->entry',
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
	'差異が顕著な語数'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'entry_flw',
		'widget_hash_name' => 'entry_flw',
		'min' => 10,
		'max' => 1000,
		'duration' => 1,
	},
	'差異が顕著な語使用'  =>  {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'check_filter_w',
		'value_hash_parent' => '',
		'value_hash_name' => 'check_filter_w',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'原点から離れた語数'  =>  {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'entry_flt',
		'widget_hash_name' => 'entry_flt',
		'min' => 10,
		'max' => 1000,
		'duration' => 1,
	},
	'原点から離れた語のみ使用'  =>  {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'check_filter',
		'value_hash_parent' => '',
		'value_hash_name' => 'check_filter',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'分析に使用する対象'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'radio',
		'value_hash_parent' => '',
		'value_hash_name' => 'radio',
		'抽出語×文章' => 0,
		'抽出語×外部変数' => 1,
		0 => '抽出語×文章',
		1 => '抽出語×外部変数',
	},
	'文章と見なす単位'  => {
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
	'スコア'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'xy_obj->scale_opt',
		'value_hash_parent' => 'xy_obj',
		'value_hash_name' => 'scale_opt',
		'標準化' => 'none',
		'対称' => 'sym',
		'対称biplot' => 'symbi',
		'none' => '標準化',
		'sym' => '対称',
		'symbi' => '対称biplot',
	},
	'集計単位'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'high',
		'value_hash_parent' => '',
		'value_hash_name' => 'high',
		'widget_hash_name' => 'opt_body_high->win_obj',
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
	'同時布置'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'biplot',
		'value_hash_parent' => '',
		'value_hash_name' => 'biplot',
		'widget_hash_name' => 'label_high2',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'バブルプロット'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'bubble_obj->chkw_main',
		'value_hash_parent' => 'bubble_obj',
		'value_hash_name' => 'check_bubble',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'バブルの大きさ'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'bubble_obj->ent_size',
		'widget_hash_name' => 'bubble_obj->ent_size',
	},
	'原点表示'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'xy_obj->check_origin',
		'value_hash_parent' => 'xy_obj',
		'value_hash_name' => 'check_origin',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	#'value_hash'が必要なのは'any_each_list'タイプのみ
	'外部変数'  => {
		'category' => 'string',
		'type' => 'any_each_list',
		'hash' => 'opt_body_var',
		'value_hash' => 'vars',
		'widget_hash_name' => 'opt_body_var',
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
	return "対応分析";
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
	return "gui_window::word_corresp";
}

sub r_command_method_str{
	return "r_command_bubble";
}

sub r_command_method_type{
	return 1;
}

sub discript_plot_ratio{
	return 1.5;
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
		#print "command_f = ".$args{command_f}." \n";
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
	}
	if (exists($args{command_a})) {
		#print "command_a = ".$args{command_a}." \n";
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
	}
	if ( $use_option_table) {
		#print "height = ".$args{height}." \n";
		#print "width = ".$args{width}." \n";
		
		$args{height} += $table_height;
		#print "height_changed = ".$args{height}." \n";
	}
	
	return \%args;
}


1;