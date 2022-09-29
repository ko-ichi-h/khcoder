package screen_code::batch_plugin::word_netgraph;
use strict;
use utf8;

#my @need_pict_num = (1,6,7);
my @need_pict_num = (6,1);

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
	'描画対象上位語数'  => 10,
	'描画対象係数'  =>  11,
	'共起関係の種類'  => 12,
	'外部変数見出し'  => 13,
	'描画する共起関係'  => 14,
	'描画対象'  => 15,
	'上位基準'  => 16,
	'係数基準'  => 17,
	'係数標準化'  => 18,
	'濃い線'  => 19,
	'係数表示'  => 20,
	'バブルプロット'  => 21,
	'バブルの大きさ'  => 22,
	'円で語を描画'  => 23,
	'最小スパニングツリーのみ'  => 24,
	'共起パターン探索'  => 25,
	'探索対象変数'  => 26,
	'グレースケール'  => 27,
	'プロットサイズ'  => 28,
	'フォントサイズ'  => 29,
	'太字'  => 30,
);

my %display_colname_hash = (
	'布置される語数'  => '布置される語数（上位）',
	'無視語数'  => '除く最上位の語',
	'品詞'  => '品詞による語の取捨選択',
	'共起関係の種類'  => '共起関係（edge）の種類',
	'外部変数見出し'  => '外部変数・見出し',
	'描画する共起関係'  => '描画する共起関係（edge）の選択',
	'上位基準'  => '上位',
	'係数基準'  => '係数',
	'係数標準化'  => '係数を標準化する',
	'濃い線'  => '強い共起関係ほど濃い線に',
	'係数表示'  => '係数を表示',
	'バブルの大きさ'  => 'バブルプロットの大きさ',
	'円で語を描画'  => '小さめの円ですべての語を描画',
	'最小スパニングツリーのみ'  => '最小スパニング・ツリーだけを描画',
	'共起パターン探索'  => '共起パターンの変化を探る（相関）',
	'探索対象変数'  => '対象とする数値変数',
	'グレースケール'  => 'グレースケールで表現',
);

my $worksheet_col = 31;

my $table_height = 740;

my %setting_table = (
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
	'描画対象上位語数'  =>  {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'net_obj->entry_edges_number',
		'min' => 1,
		'max' => 1000,
		'duration' => 1,
	},
	'描画対象係数'  =>  {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'net_obj->entry_edges_jac',
		'min' => 0.01,
		'max' => 1,
		'duration' => 0.01,
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
	'共起関係の種類'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'radio_type',
		'value_hash_parent' => '',
		'value_hash_name' => 'radio_type',
		'語―語' => 'words',
		'語―外部変数・見出し' => 'twomode',
		'words' => '語―語',
		'twomode' => '語―外部変数・見出し',
	},
	#選択する変数は一つなのでクレンジングと同じではない
	'外部変数見出し'  => {
		'type' => 'pulldown',
		'hash' => 'var_obj->var_id',
		'value_hash_parent' => 'var_obj',
		'value_hash_name' => 'var_id',
		'widget_hash_name' => 'var_obj->opt_body->win_obj',
		'colname_array_hash_name' => 'options',
	},
	'描画する共起関係'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->method_coef',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'method_coef',
		'Jaccard' => 'binary',
		'Cosine' => 'pearson',
		'Euclid' => 'euclid',
		'binary' => 'Jaccard',
		'pearson' => 'Cosine',
		'euclid' => 'Euclid',
		'more_words_setting' => 'Cosine',
		'less_words_setting' => 'Jaccard',
	},
	'描画対象'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->radio',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'radio',
		'上位' => 'n',
		'係数' => 'j',
		'n' => '上位',
		'j' => '係数',
	},
	'係数標準化'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->standardize_coef',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'standardize_coef',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'濃い線'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->check_use_weight_as_width',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'check_use_weight_as_width',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'係数表示'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->view_coef',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'view_coef',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'上位基準'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'net_obj->entry_edges_number',
		'widget_hash_name' => 'net_obj->entry_edges_number',
	},
	'係数基準'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'net_obj->entry_edges_jac',
		'widget_hash_name' => 'net_obj->entry_edges_jac',
	},
	'バブルプロット'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->bubble_obj->chkw_main',
		'value_hash_parent' => 'net_obj->bubble_obj',
		'value_hash_name' => 'check_bubble',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'バブルの大きさ'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'net_obj->bubble_obj->ent_size',
		'widget_hash_name' => 'net_obj->bubble_obj->ent_size',
	},
	'円で語を描画'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->check_smaller_nodes',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'check_smaller_nodes',
		'widget_hash_name' => 'net_obj->wc_smaller_nodes',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'最小スパニングツリーのみ'  => {
		'category' => 'string',
		'type' => 'hash',
		'hash' => 'net_obj->check_min_sp_tree_only',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'check_min_sp_tree_only',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'共起パターン探索'  => {
		'type' => 'hash',
		'hash' => 'net_obj->check_cor_var',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'check_cor_var',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	#ラベル「対象とする数値変数」の右にある 外部変数・見出し と類似した処理が必要
	'探索対象変数'  => {
		'type' => 'pulldown',
		'hash' => 'net_obj->var_obj2->var_id',
		'value_hash_parent' => 'net_obj->var_obj2',
		'value_hash_name' => 'var_id',
		'colname_array_hash_name' => 'options',
	},
	'グレースケール'  => {
		'type' => 'hash',
		'hash' => 'net_obj->check_gray_scale',
		'value_hash_parent' => 'net_obj',
		'value_hash_name' => 'check_gray_scale',
		'ON' => 1,
		'OFF' => 0,
		1 => 'ON',
		0 => 'OFF',
	},
	'品詞'  => {
		'category' => 'string',
		'type' => 'hinshi',
		'hash' => '',
	},
	'サンプリング'  => {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'words_obj->sampling_obj->entry',
		'widget_hash_name' => 'words_obj->sampling_obj->entry',
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
);

sub get_analysis_name{
	return "共起ネットワーク";
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
	return "plotR::network";
}

sub r_command_method_str{
	return "r_plot_cmd_p4";
}

sub r_command_method_type{
	return 0;
}

sub discript_plot_ratio{
	return 2;
}

sub other_expand_plot_num{
	return '_6|_1';
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
    core = list(fg_params = list(fontsize = 8, fontfamily = font_fam))
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