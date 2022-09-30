package screen_code::batch_plugin::word_cls;
use strict;
use utf8;

#my @need_pict_num = (1,'1_last');
my @need_pict_num = (1);

my %worksheet_col_hash = (
	'集計単位'  => 8,
	'サンプリング'  => 1,
	'布置される語数'  => 2,
	'無視語数'  => 3,
	'最小出現数'  => 4,
	'最大出現数'  => 5,
	'最小文章数'  => 6,
	'最大文章数'  => 7,
	'品詞'  => 15,
	'方法'  => 9,
	'距離'  => 10,
	'クラスター数'  =>  11,
	'クラスターの色分け'  => 12,
	'フォントサイズ'  => 13,
	'プロットサイズ'  => 14,
);

my %display_colname_hash = (
	'布置される語数'  => '布置される語数（上位）',
	'無視語数'  => '除く最上位の語',
	'品詞'  => '品詞による語の取捨選択',
);

my $worksheet_col = 16;

my $table_height = 320;

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
		'hash' => 'cls_obj->method_mthd',
		'value_hash_parent' => 'cls_obj',
		'value_hash_name' => 'method_mthd',
		'Ward法' => 'ward',
		'群平均法' => 'average',
		'最遠隣法' => 'complete',
		'ward' => 'Ward法',
		'average' => '群平均法',
		'complete' => '最遠隣法',
	},
	'距離'  => {
		'type' => 'hash',
		'hash' => 'cls_obj->method_dist',
		'value_hash_parent' => 'cls_obj',
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
	'クラスター数'  =>  {
		'category' => 'numeric',
		'type' => 'entry',
		'hash' => 'cls_obj->entry_cluster_number',
		'min' => 1,
		'max' => 100,
		'duration' => 1,
	},
	'クラスターの色分け'  => {
		'type' => 'hash',
		'hash' => 'cls_obj->check_color_cls',
		'value_hash_parent' => 'cls_obj',
		'value_hash_name' => 'check_color_cls',
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
	return "クラスター分析";
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
	return "gui_window::word_cls";
}

sub r_command_method_str{
	return "r_command_plot_ggplot2";
}

#引数にハッシュが含まれるかどうか
sub r_command_method_type{
	return 0;
}

sub discript_plot_ratio{
	return 1.25;
}

sub other_expand_plot_num{
	return '_1$';
}

sub match_str{
	return '
	grid\.newpage\(\)
	pushViewport\(viewport\(layout=grid\.layout\(1,2, width=c\(1,5\)\) \) \)
	print\(p,  vp= viewport\(layout\.pos\.row=1, layout\.pos\.col=2\) \)
	print\(p2, vp= viewport\(layout\.pos\.row=1, layout\.pos\.col=1\) \)
';

#	return 'grid.newpage()\n\tpushViewport(viewport(layout=grid.layout(1,2, width=c(1,5)) ) )\n\tprint(p,  vp= viewport(layout.pos.row=1, layout.pos.col=2) )\n\tprint(p2, vp= viewport(layout.pos.row=1, layout.pos.col=1) )';
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
g_arranged <- grid.arrange(p, p2, g_test, layout_matrix=layout1)

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
			$ratio_str .= 'c(2,1,1,1,1,1)';
		}
		
		for (my $i = 0; $i < $table_height / 20; $i++) {
			$ratio_str .= ', ';
			$ratio_str .= 'c(3,3,3,3,3,3)';
		}
		$ratio_str .= ')';
		
		$command_str =~ s/ratio_replace/$ratio_str/;
		$args{command_f} = $command_str;
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