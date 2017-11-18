package kh_r_plot::network;

use base qw(kh_r_plot);

use strict;
use utf8;

# Basically for Web
sub _save_html{
	my $self = shift;
	my $path = shift;

	# open dvice
	unless ( $::config_obj->web_if ){
		my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';
		$::config_obj->R->send("
			if ( exists(\"Cairo\") ){
				Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
			} else {
				png(\"$temp_img\", width=640, height=480, unit=\"px\")
			}
		");
		$self->set_par;
		$::config_obj->R->send($self->{command_f});
		$::config_obj->R->send('dev.off()');
	}
	
	# run save command
	my $r_command = &r_command_html2;
	$r_command .= "
		zz <- file(\"$path\", \"w\", encoding=\"UTF-8\")
		cat(net, file=zz)
		close(zz)
	";
	
	unless ( $::config_obj->web_if ){
		my $cwd = $::config_obj->cwd;
		$r_command =~ s/src="\/lib/src="$cwd\/kh_lib\/web_lib/g;
	}
	
	$::config_obj->R->send($r_command);
	
	return 1;
}

sub _save_net{
	my $self = shift;
	my $path = shift;

	my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';

	# open dvice
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
		} else {
			png(\"$temp_img\", width=640, height=480, unit=\"px\")
		}
	");
	$self->set_par;
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');
	
	# run save command
	my $r_command = &r_command_n3;
	$r_command .= "write.graph(n3, \"$path\", format=\"pajek\")";
	$::config_obj->R->send($r_command);
	
	return 1;
}

sub _save_graphml{
	my $self = shift;
	my $path = shift;

	my $temp_img = $::config_obj->cwd.'/config/R-bridge/'.$::project_obj->dbname.'_'.$self->{name}.'.tmp';

	# open dvice
	$::config_obj->R->send("
		if ( exists(\"Cairo\") ){
			Cairo(width=640, height=640, unit=\"px\", file=\"$temp_img\", type=\"png\", bg=\"white\")
		} else {
			png(\"$temp_img\", width=640, height=480, unit=\"px\")
		}
	");
	$self->set_par;
	$::config_obj->R->send($self->{command_f});
	$::config_obj->R->send('dev.off()');

	# run save command
	my $r_command = &r_command_n4;
	$r_command .= "write.graph(n4, \"$path\", format=\"graphml\")";
	$::config_obj->R->send($r_command);

	# convert character coding to UTF-8
	if ($::config_obj->os eq 'win32' && 0) {
		# input code
		my %codes = (
			'jp' => 'cp932',
			'en' => 'cp1252',
			'cn' => 'cp936',
			'de' => 'cp1252',
			'es' => 'cp1252',
			'fr' => 'cp1252',
			'it' => 'cp1252',
			'nl' => 'cp1252',
			'pt' => 'cp1252',
			'kr' => 'cp949',
		);
		my $code = $::project_obj->morpho_analyzer_lang;
		$code = $codes{$code};
		
		# file names
		my $os_path = $::config_obj->os_path($path);
		my $temp_out = $::config_obj->cwd.'/config/R-bridge/temp.graphml';
		$temp_out = $::config_obj->os_path($temp_out);
		if (-e $temp_out){
			unlink $temp_out or die("Could not delete file: $temp_out");
		}
		
		open(my $fh_out, '>:encoding(UTF-8)', $temp_out) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $temp_out,
			)
		;
		open(my $fh_in, "<:encoding($code)", $os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
		while (<$fh_in>) {
			print $fh_out $_;
		}
		close $fh_in;
		close $fh_out;
		
		unlink ($os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
		rename($temp_out, $os_path) or
			gui_errormsg->open(
				type    => 'file',
				thefile => $os_path,
			)
		;
	}

	return 1;
}


# for HTML (customized)
sub r_command_html2{
	my $t = <<'EOS';

edges <- get.edgelist(n2,names=F)
names <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
ccol <- as.numeric(ccol)

if ( com_method == "cnt-b" || com_method == "cnt-d" || com_method == "cnt-e"){
	ccol <- ccol / max(ccol)
	ccol <- (1 - ccol) * 0.7 + 0.25
	col <- "d3.scaleSequential(d3.interpolateMagma)"
} else if ( com_method == "com-b" || com_method == "com-g" || com_method == "com-r"){
	ccol[is.na(ccol)] <- -1
	#maxg <- max(ccol) + 1
	#ccol[ccol==-1] <- maxg
	if (max(ccol) > 10){
		col <- "d3.scaleOrdinal().domain([1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]).range(d3.schemeCategory20).unknown('white')"
	} else {
		col <- "d3.scaleOrdinal().domain([1,2,3,4,5,6,7,8,9,10]).range(d3.schemeCategory10).unknown('white')"
	}
} else if ( com_method == "twomode_c" ){
	ccol[is.na(ccol)] <- -1
	ccol <- ccol / max(ccol)
	ccol <- (1 - ccol) * 0.7 + 0.2
	col <- "d3.scaleSequential(d3.interpolateMagma)"
} else {
	col <- "d3.scaleOrdinal().domain([1,2,3,4,5,6,7,8,9,10]).range(d3.schemeCategory10).unknown('white')"
	ccol <- rep(-1, length(names) )
}

net <- '<!DOCTYPE html>
  <html>
  <head>
  <meta charset="utf-8"/>
    <script src="/lib/htmlwidgets-0.9/htmlwidgets.js"></script>
    <script src="/lib/d3-4.5.0/d3.min.js"></script>
    <script src="/lib/forceNetwork-binding-0.4kh/forceNetwork.js"></script>

          </head>
  <body style="background-color:white;">
    <div id="htmlwidget_container">
    <div id="htmlwidget-net" style="width:960px;height:500px;" class="forceNetwork html-widget"></div>
    </div>
<script type="application/json" data-for="htmlwidget-net">{"x":{"links":{"source":['



for (i in 1:length(edges[,1])){
  if (i > 1){
    net <- paste0(net, ",")
  }
  net <- paste0(net, edges[i,1] - 1)
}

net <- paste0(net, '],"target":[')

for (i in 1:length(edges[,2])){
  if (i > 1){
    net <- paste0(net, ",")
  }
  net <- paste0(net, edges[i,2] - 1)
}

#net <- paste0(net, '],"colour":[')
#for (i in 1:length(edges[,1])){
#  if (i > 1){
#    net <- paste0(net, ",")
#  }
#  net <- paste0(net, '"#a9a9a9"')
#}

net <- paste0(net, ']},"nodes":{"name":[')

for (i in 1:length(names)){
  if (i > 1){
    net <- paste0(net, ",")
  }
  net <- paste0(net, '"', names[i], '"')
}

net <- paste0(net, '],"group":[')

for (i in 1:length(ccol)){
  if (i > 1){
    net <- paste0(net, ",")
  }
  net <- paste0(net, ccol[i])
}


if ( exists("var_select") ){
	if (
		   ( com_method == "twomode_c" || com_method == "twomode_g" )
	) {
		# for twomode
		net <- paste0(net, '],"shape":[')
		for (i in 1:length(var_select)){
			if (i > 1){
				net <- paste0(net, ",")
			}
			if (var_select[i]){
				net <- paste0(net, 3)
			} else {
				net <- paste0(net, 0)
			}
		}
	} else {
		# for selected words
		checker <- NULL
		checker[var_select] <- 1
		
		net <- paste0(net, '],"shape":[')
		for (i in 1:length(names)){
			if (i > 1){
				net <- paste0(net, ",")
			}
			if ( is.na( checker[i] ) ){
				net <- paste0(net, 0)
			} else {
				net <- paste0(net, 4)
			}
		}
	}
} else {
	# for normal
	net <- paste0(net, '],"shape":[')
	for (i in 1:length(names)){
		if (i > 1){
			net <- paste0(net, ",")
		}
		net <- paste0(net, 0)
	}
}


net2 <- ']},"options":{"NodeID":"name","Group":"group","colourScale":"'

net3 <- '","fontSize":12,"fontFamily":"sansserif","clickTextSize":30,"linkDistance":50,"linkWidth":"function(d) { return Math.sqrt(d.value); }","charge":-200,"opacity":10,"zoom":true,"legend":false,"arrows":false,"nodesize":false,"radiusCalculation":" Math.sqrt(d.nodesize)+6","bounded":true,"opacityNoHover":10,"clickAction":null}},"evals":[],"jsHooks":[]}</script>
<script type="application/htmlwidget-sizing" data-for="htmlwidget-net">{"viewer":{"width":450,"height":350,"padding":10,"fill":true},"browser":{"width":960,"height":500,"padding":10,"fill":true}}</script>
</body>
</html>'

net <- paste0(net, net2, col, net3)

EOS
	return $t;
}

# for HTML
sub r_command_html{
	return '

library(networkD3)

com <- fastgreedy.community(n2, merges=TRUE, modularity=TRUE)
d3 <- igraph_to_networkD3(n2, as.vector( membership(com) ))

d3$nodes$name <- colnames(d)[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]
d3$nodes$size <- freq[ as.numeric( igraph::get.vertex.attribute(n2,"name") ) ]

d3net <- forceNetwork(
	Links=d3$links,
	Nodes=d3$nodes,
	Source="source",
	Target="target",
	NodeID="name",
	Group="group",
	#Nodesize="size",
	zoom=T,
	opacityNoHover=10,
	opacity = 10,
	legend=F,
	fontSize=12,
	bounded=T,
	linkDistance = 50,
	charge = -130,
	#height=640,
	#width=640
	colourScale = JS("d3.scaleOrdinal(d3.schemeCategory10);")
)

';
}


# for Pajeck
sub r_command_n3{
	return '

n3 <- set.vertex.attribute(
    n2,
    "id",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    colnames(d)[ as.numeric( get.vertex.attribute(n2,"name") ) ]
)

n3 <- set.vertex.attribute(
    n3,
    "xfact",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)

n3 <- set.vertex.attribute(
    n3,
    "yfact",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)


	';
}

# for GraphML
sub r_command_n4{
	return '

print(paste("use_alpha", use_alpha))

n4 <- set.vertex.attribute(
    n2,
    "frequency",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    freq[ as.numeric( get.vertex.attribute(n2,"name") ) ]
)

n4 <- set.vertex.attribute(
    n4,
    "size",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    sqrt( freq[ as.numeric( get.vertex.attribute(n2,"name") ) ] )
)

n4 <- set.vertex.attribute(
    n4,
    "x",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    lay_f[,1] * 100
)

n4 <- set.vertex.attribute(
    n4,
    "y",
    (0+new_igraph):(length(get.vertex.attribute(n2,"name"))-1+new_igraph),
    lay_f[,2] * 100
)

	';
}

1;