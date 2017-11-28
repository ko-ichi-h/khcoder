# 最小限（に近い）プラグイン構成

package p1_sample5_repeatR;

sub plugin_config{
	return {
		name     => '共起ネットワークの調整を繰り返す',
		menu_grp => 'サンプル',         # この行は（本来は）省略可
	};
}

sub exec{
	print "short sample\n";             # ここに必要な処理内容を記述

	# 共起ネットワークの「調整」を繰り返す
	my $n = 0;
	while (1){
		my $c = $::main_gui->get('w_word_netgraph_plot');

		my $cc = gui_window::r_plot_opt::word_netgraph->open(
			command_f => $c->{plots}[$c->{ax}]->command_f,
			size      => $c->original_plot_size,
		);
		
		my $en = 100 + int( rand(50) );
		$cc->{net_obj}->{entry_edges_number}->delete(0,'end');
		$cc->{net_obj}->{entry_edges_number}->insert(0,$en);
		
		$cc->calc;
		
		++$n;
		print "#### $n ####\n";
		
		my $sn = int(rand(5));
		#sleep $sn;
	}

}

1;                                      # これも忘れずに…。
