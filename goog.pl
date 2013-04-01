#!/usr/bin/env perl
use local::lib;
use warnings;
use strict;
use Irssi;
use vars qw($VERSION %IRSSI);
use WWW::Mechanize;
use URI::Find::Schemeless;
use LWP::Simple;
use LWP::UserAgent;
use Weather::Underground;
use JSON qw(decode_json);

$VERSION = '2.00';
%IRSSI = (
	authors		=> 'Jared Tyler Miller, John Boyle, Evan Armour',
	contact		=> 'jtmiller@gmail.com, boylejm@gmail.com, hargrimm@gmail.com',
	name		=> 'Multifunction channel bot based on lmgtfy bot based on DCSS Bot Repeater',
	description => 'Does many things',
	license		=> 'Public Domain',
);

print CLIENTCRAP "Loading HargBot v$VERSION";

my $root_server = "lunarnet";
my $bot_name = "HargBot";
my $root_chan = "mefightclub";
#my $root_chan = "asandbox";
#my @target_chan = qw(#asandbox);
my @target_chan = qw(#mefightclub);
my $target_server = "lunarnet";
my $ts = Irssi::server_find_tag($target_server);
my $rs = Irssi::server_find_tag($root_server);

print CLIENTCRAP "Listening to channel " . $root_chan . " on " . $root_server;

my %commands = (
	$bot_name => ['!goog', '!weather', '!fullweather', '!git', '!benice', '!ftb']
	);

sub check_if_command {
	# check if $msg starts with a command
	my ($nick, $msg) = @_;	

	for my $bot ( keys %commands ) {
		foreach my $command ( @{ $commands{$bot} } ) {
			if ((index $msg, $command) eq 0) {
				my $clean_msg = add_to_command($nick, trim($msg), trim($command));
				if ($bot eq $bot_name) {
					#printf "the command is: " . $clean_msg;
					if ($command eq '!goog') {
						if (checkblank($msg, $command)) {
							goog(lc $clean_msg);
						}
						printf $nick . "/" . $msg;
					}
					elsif ($command eq '!weather') {
						if (checkblank($msg, $command)) {
							weather(lc $clean_msg);
						}
						printf $nick . "/" . $msg;
					}
					elsif ($command eq '!fullweather') {
						if (checkblank($msg, $command)) {
							fullweather(lc $clean_msg);
						}
						printf $nick . "/" . $msg;
					}
					elsif ($command eq '!git') {
						gitme(lc $clean_msg);
						printf $nick . "/" . $msg;
					}
					elsif ($command eq '!benice') {
						benice($nick);
						printf $nick . "/" . $msg;
					}
					elsif ($command eq '!ftb') {
						if (checkblank($msg, $command)) {
							ftbwikisearch(lc $clean_msg);
						}
						printf $nick . "/" . $msg;
					}
				} 
				else {
					#print CLIENTCRAP $bot . '-' . $command . ' ' . $clean_msg . "\n";
					private_msg($bot, $command . ' ' . $clean_msg);
				}
			}
		}
	}
}

sub checkblank {
	my ($msg, $command) = @_;
	my $scrubmsg = substr($msg, length($command));
	
	if ($scrubmsg eq "") {
		public_msg($target_chan[0], $command .' requires an argument, silly!');
		return 0;
	}
	else {
		return 1;
	}
}

sub goog {
   my ($query) = @_; 
   $query = join "+", split " ", $query;
   #printf "goog query=" . $query;
   #my ($theURI) = "http://www.google.com/search?btnI=I%27m+Feeling+Lucky&ie=UTF-8&sourceid=navclient&oe=UTF-8&q=" . lc($query);
   my ($theURI) = "http://www.google.com/search?q=" . lc($query) . "&btnI";

   my $ua = new LWP::UserAgent;
   $ua->agent( "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_8_2) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.52 Safari/537.17" );
   $ua->timeout( 20 );
   $ua->max_redirect( 0 );
   $ua->env_proxy;
   my($redirectURI)="";
   my($unlucky) = 0;

   my $response = $ua->get($theURI);
   $redirectURI=$response->header("Location");
  
   if ($redirectURI eq "") {
	  $redirectURI = "Looks like this url wasn't lucky... (" . $response->status_line . ")";
	  #$redirectURI= $response->status_line;
	  $unlucky=1;
   }
   #if ($response->is_success) {
   #   $unlucky=0;
   #}
   #else {
   #   $unlucky = 1;
   #   $redirectURI= $response->status_line;
   #}
   #$redirectURI = $theURI;
   printf "|" . $redirectURI . "|";
   if ($unlucky) {
	  public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI	);
	  public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $theURI  );
	  #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $response->status_line  );
   }
   else {
	  public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI	);
	  #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $theURI	);
	  #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $response->status_line  );
   }
   if ( checkYT(trim($redirectURI)) ) {
	   scrapeYT($redirectURI);
   }
}

sub gitme {
  public_msg($target_chan[0], "I live in the cupboard under the stairs...");
}

sub benice {
	my $target = shift;

	public_msg($target_chan[0], $target . ": You are a smart, funny, attractive person and everyone loves you.");
}
sub weather {
	my ($query) = shift;
	wf($query, 0);
}

sub fullweather {
	my ($query) = shift;
	wf($query, 1);
}

sub wf {
	my ($query) = @_;
	my ($full) = shift;
	$full = shift;
	printf "FULL?? " . $full;
	$query = join " ", split " ", $query;
	#printf "wf query=" . $query;
	my ($fail) = 0;

	my $weather = Weather::Underground->new(
		place   =>	   $query,
		debug		   =>	   0
		)
	|| die "Error, could not create new weather object: $@\n";

	my $arrayref = $weather->get_weather()
	|| printf "Error, calling get_weather() failed: $@\n";

	printf "err:" . $@;
	if ($@ ne "Main table closed - end of interesting data") { 
		$fail = 1;
	}
 
	#printf "The celsius temperature at $arrayref->[0]->{place} is $arrayref->[0]->{temperature_celsius}\n";
	my $loc	= $arrayref->[0]->{place};
	my $degF = $arrayref->[0]->{temperature_fahrenheit};
	my $degC = $arrayref->[0]->{temperature_celsius};
	my $dir	= $arrayref->[0]->{wind_direction};
	my $mph	= $arrayref->[0]->{wind_milesperhour} . " mph";
	my $kph	= $arrayref->[0]->{wind_kilometersperhour} . " kph";
	my $cond = $arrayref->[0]->{conditions};
	my $clds = $arrayref->[0]->{clouds};
	my $hum	= $arrayref->[0]->{humidity};
	my $psi	= $arrayref->[0]->{pressure};
	my $phs	= $arrayref->[0]->{moonphase};
	my $mnrs = $arrayref->[0]->{moonrise};
	my $snrs = $arrayref->[0]->{sunrise};
	my $mnst = $arrayref->[0]->{moonset};
	my $snst = $arrayref->[0]->{sunset};
	my $vism = $arrayref->[0]->{visibility_miles} . " mi";
	my $visk = $arrayref->[0]->{visibility_kilometers} . "km";
   
	my($colorcode,$cccond)="";

	if ($degF > 90) {
		$colorcode="\cc5 ";
		printf "1";
	}
	elsif ($degF > 75) {
		$colorcode="\cc7 ";
		printf "2";
	}
	elsif ($degF > 60) {
		$colorcode="\cc8 ";
		printf "3";
	}
	elsif ($degF > 45) {
		$colorcode="\cc3 ";
		printf "4";
	}
	else {
		$colorcode="\cc11 ";
		printf "5";
	}
   
	if ($cond eq "Rain") {
		$cccond="\cc2 ";
		printf "1";
	}

	my ($line1) = $loc . ": Current: " . $cccond . $cond . ", " . $colorcode . $degF . "°F\co (" . $colorcode . $degC . "°C\co). Winds from the " . $dir . ", " . $mph . " (" . $kph . ")";
	my ($line2) = "Bar: " . $psi . ", Clouds: " . $clds . ", Vis: " . $vism . " (" . $visk . ")";
	my ($line3) = "Sunrise/set: " . $snrs . "/" . $snst . ", Moonrise/set: " . $mnrs . "/" . $mnst . ", Moon Phase: " . $phs;

	printf $line1;
	printf $line2;
	printf $line3;

	if ($fail) { 
		public_msg($target_chan[0], "Bad Location: " . $query);
	}
	else {
		public_msg($target_chan[0], $line1);
		if ($full) {
			public_msg($target_chan[0], $line2);
			public_msg($target_chan[0], $line3);
		}
	}

	return 
}



sub process_msg {
	my $msg = shift;

}

sub add_to_command {
	# stupid hack to add your nick to $msg if nick isn't provided
	my ($nick, $msg, $command) = @_;
	my $new_msg;
	if ($msg eq $command) {
		$new_msg = $nick;
	} else {
		$new_msg = substr($msg, length($command));
	}

	return trim($new_msg);
}

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub public_msg	{
	my ($chan, $msg) = @_;
	$ts->send_message($chan, $msg, 0);
}

sub private_msg {
	my ($bot, $msg) = @_;
	#print CLIENTCRAP $bot . ' - ' . $msg . "\n";
	$rs->send_message($bot, $msg, 1)
}

sub scrapeYT {
	my $msg = shift;
	my $short = "http://youtu.be/";
	my $vid;
	my $plist;
	my $plout = "";
	if (index($msg,'/user/') != -1) {
		return;
	}
	elsif (index($msg,$short) != -1) {
		$vid = substr($msg, index($msg, '.be/') + 4,11);
	}
	else {
		$vid = substr($msg, index($msg, '=') + 1, 11);
	}
	
	if (index($msg,'&list') != -1) {
		$plist = substr($msg, index($msg, 'st=') + 3);
		my $plapi = get('https://www.googleapis.com/youtube/v3/playlists?part=snippet&id=' . $plist . '&key=AIzaSyCaXV2IVfhG1lZ38HP7Xr9HzkGycmsuSDU');
		my $pljson = decode_json($plapi);
		my $pltitle = $pljson->{'items'}[0]{'snippet'}{'title'};
		$plout = ', in playlist "' . $pltitle . '"';
	}
	
	my $ytapi = get('https://www.googleapis.com/youtube/v3/videos?id=' . $vid . '&part=snippet&key=AIzaSyCaXV2IVfhG1lZ38HP7Xr9HzkGycmsuSDU');
	my $json = decode_json($ytapi);
	my $result = $json->{'items'}[0]{'snippet'}{'title'};
	if ($result) {
		my $vidtitle = $result;
		my $viduploader = $json->{'items'}[0]{'snippet'}{'channelTitle'};
		public_msg($target_chan[0], "YouTube: " . $vidtitle . " [by " . $viduploader . $plout . "]");
	}
	else {
		public_msg($target_chan[0],'Invalid video id: ' . $vid);
	}
}


sub ftbwikisearch {
	my $search = shift;
	
	my $searchresult = get('https://www.googleapis.com/customsearch/v1?q=' . $search . '&cx=016962746194547451353%3Apkf0xfjej3i&num=1&safe=off&key=AIzaSyCaXV2IVfhG1lZ38HP7Xr9HzkGycmsuSDU');
	my $json = decode_json($searchresult);
	
	if ($json->{'searchInformation'}->{'totalResults'} == 0) {
		public_msg($target_chan[0], 'No results found for query ' . $search);
	}
	else {
		#my $parsed = $json->{'items'}[0]->{'pagemap'}->{'metatags'}[0]->{'og:title'};
		my $parsed = $json->{'items'}[0]->{'title'};
		my $title = substr($parsed, 0, index($parsed, ' -'));
		my $foundurl = $json->{'items'}[0]->{'link'};
		
		public_msg($target_chan[0], 'Found "' . $title . '" at ' . $foundurl);
	}
}


sub checkYT {
	my $url = shift;
	my $yt1 = "www.youtube.com";
	my $yt2 = "http://youtu.be/";

	if (index($url,$yt1) != -1) {
		return 1;
	}
	elsif (index($url,$yt2) != -1) {
		return 1;
	}
	else {
		return 0;
	}
}


sub dispatch {
	my ($server, $msg, $nick, $mask, $chan) = @_;
	#printf "DISPATCH: " . $nick . "/" . $msg;
	if (lc($chan) eq lc($target_chan[0])) {
		if ( checkYT(trim($msg)) ) {
		#testscrape();
			scrapeYT($msg);
		}
		else {
			check_if_command($nick, trim($msg));
		}
	}

	if (lc($chan) eq lc($root_chan)) {
		# return unless the nick is in the keys
		return unless (grep {lc($_) eq lc($nick)} keys %commands);
		# return unless the $player is found in the $text
		return unless (grep {lc($msg) =~ lc($_)} split(/ +/, Irssi::settings_get_str("crawlwatchnicks")));
		# send command if $text contains any @player names
		# public_msg($target_chan, $msg)
		foreach (@target_chan) {
			public_msg($_, $msg)
		}
	}
}

sub priv_dispatch {
	my ($server, $msg, $nick, $mask) = @_;
	# return unless the nick is in the keys
	return unless (grep {lc($_) eq lc($nick)} keys %commands);
	$ts->send_message($target_chan[0], $msg, 0);
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message private", "priv_dispatch");
Irssi::settings_add_str("crawlwatch", "crawlwatchnicks", "");

#print CLIENTCRAP "/set crawlwatchnicks ed edd eddy ...";
print CLIENTCRAP "Watched nicks: " . Irssi::settings_get_str("crawlwatchnicks");
