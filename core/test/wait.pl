    ## Dependent on Graham Barr's Tk::ProgressBar
    use strict;
    use Tk;
    use Tk::WaitBox;
    use Tk::ProgressBar;
    my($root) = MainWindow->new;
    $root->withdraw;
    my($utxt) = "Initializing...";
    my($percent);
    my($wd);
    $wd = $root->WaitBox(
                         -bitmap =>'questhead', # Default would be 'hourglass'
                         -txt2 => 'tick-tick-tick', #default would be 'Please Wait'
                         -title => 'Takes forever to get service around here',
                         -cancelroutine => sub {
                             print "\nI'm canceling....\n";
                             $wd->unShow;
                             $utxt = undef;
                         });
    $wd->configure(-txt1 => "Hurry up and Wait, my Drill Sergeant told me");
    $wd->configure(-foreground => 'blue',-background => 'white');
    ### Do something quite boring with the user frame
    my($u) = $wd->{SubWidget}{uframe};
    $u->pack(-expand => 1, -fill => 'both');
    $u->Label(-textvariable => \$utxt)->pack(-expand => 1, -fill => 'both');
    ## It would definitely be better to do this with a canvas... this is dumb
    my($bar) = $u->ProgressBar(
                               -variable => \$percent,
                               -blocks => 0,
                               -width => 20,
                               -colors => [  0 => 'green',
                                             30 => 'yellow',
                                             50 => 'orange',
                                             80 => 'red'],
                              )
            ->pack(-expand =>1, -fill =>'both');
    $wd->configure(-canceltext => 'Halt, Cease, Desist'); # default is 'Cancel'
    $wd->Show;
    my($diff) = 240;
    for (1..$diff) {
        $percent = int($_/$diff*100);
        $utxt = sprintf("%5.2f%% Complete",$percent);
        $bar->update;
        last if !defined($utxt);
    }
    sleep(2);
    $wd->unShow;
