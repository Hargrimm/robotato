#!/usr/bin/env perl
use local::lib;

use strict;
use Irssi;
use warnings;
use vars qw($VERSION %IRSSI);
use Data::Dumper;
use WWW::Mechanize;
use URI::Find::Schemeless;
use LWP::Simple;
use LWP::UserAgent;
use Weather::Underground;


$VERSION = '1.00';
%IRSSI = (
    authors     => 'Jared Tyler Miller, John Boyle',
    contact     => 'jtmiller@gmail.com, boylejm@gmail.com',
    name        => 'lmgtfy bot based on DCSS Bot Repeater',
    description => 'creates lmgtfy hyperlink based on msg',
    license     => 'Public Domain',
);

print CLIENTCRAP "loading goog.pl $VERSION!";

my $root_server = "<server>";
my $bot_name = "robotato";
my $root_chan = "<room>";
my $target_server = "<server>";
my @target_chan = qw(<room>);
my $ts = Irssi::server_find_tag($target_server);
my $rs = Irssi::server_find_tag($root_server);

#print Dumper($ts);
#print Dumper($rs);

my %commands = (
    $bot_name => ['!goog', '!weather', '!fullweather', '!git']
    );

sub check_if_command {
    # check if $msg starts with a command
    my ($nick, $msg) = @_;
    my $count = 0;
    printf $nick . "/" . $msg;    

    for my $bot ( keys %commands ) {
        foreach my $command ( @{ $commands{$bot} } ) {
            if ((index $msg, $command) eq 0) {
                my $clean_msg = add_to_command($nick, trim($msg), trim($command));
                if ($bot eq $bot_name) {
                    #printf "the command is: " . $clean_msg;
                    if ($command eq '!goog') {
                        goog(lc $clean_msg);
                    }
                    elsif ($command eq '!weather') {
                        #printf "the command is: " . $clean_msg;
                        weather(lc $clean_msg);
                    }
                    elsif ($command eq '!fullweather') {
                        #printf "the command is: " . $clean_msg;
                        fullweather(lc $clean_msg);
                    }
                    elsif ($command eq '!git') {
                        gitme(lc $clean_msg)
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
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI  );
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $theURI  );
      #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $response->status_line  );
   }
   else {
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI  );
      #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $theURI  );
      #public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $response->status_line  );
   }

   if ( checkYT(trim($redirectURI)) ) {
       scrapeYT($redirectURI);
   }


}

sub gitme {
  public_msg('I live at -> https://github.com/jmbjr/robotato.git') 
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
       place   =>      $query,
       debug           =>      0
       )
       || die "Error, could not create new weather object: $@\n";

   my $arrayref = $weather->get_weather()
       || printf "Error, calling get_weather() failed: $@\n";

   printf "err:" . $@;
   if ($@ ne "Main table closed - end of interesting data") { 
       $fail = 1;
   }
 
   #printf "The celsius temperature at $arrayref->[0]->{place} is $arrayref->[0]->{temperature_celsius}\n";
   my $loc  = $arrayref->[0]->{place};
   my $degF = $arrayref->[0]->{temperature_fahrenheit} . "°F";
   my $degC = $arrayref->[0]->{temperature_celsius} . "°C";
   my $dir  = $arrayref->[0]->{wind_direction};
   my $mph  = $arrayref->[0]->{wind_milesperhour} . " mph";
   my $kph  = $arrayref->[0]->{wind_kilometersperhour} . " kph";
   my $cond = $arrayref->[0]->{conditions};
   my $clds = $arrayref->[0]->{clouds};
   my $hum  = $arrayref->[0]->{humidity};
   my $psi  = $arrayref->[0]->{pressure};
   my $phs  = $arrayref->[0]->{moonphase};
   my $mnrs = $arrayref->[0]->{moonrise};
   my $snrs = $arrayref->[0]->{sunrise};
   my $mnst = $arrayref->[0]->{moonset};
   my $snst = $arrayref->[0]->{sunset};
   my $vism = $arrayref->[0]->{visibility_miles} . " mi";
   my $visk = $arrayref->[0]->{visibility_kilometers} . "km";
   
   my($colorcode)="";

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
   
   printf $degF;


   my ($line1) = $loc . ": Current: " . $cond . ", " . $colorcode . $degF . "\co (" . $colorcode . $degC . "\co). Winds from the " . $dir . ", " . $mph . " (" . $kph . ")";
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
   #printf "wf working!";
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

sub public_msg  {
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
    my @uris;
    my $finder = URI::Find::Schemeless->new(sub {
        my $uri = shift;
        push @uris, $uri;
    });
    my $numurl = $finder->find(\$msg);
    my $uri = $uris[0];

    $uri->scheme("http");
    
    if (head $uri ) {
        my $mech = WWW::Mechanize->new();
        $mech->get( $uri ) or die();
        my $title = $mech->title();
        $title =~ s/- YouTube$//;
        printf "%s\n", $title;
        #public_msg($target_chan[0], "LET ME SCRAPE THAT FOR YOU!!!");
        #public_msg($target_chan[0], "\cc1,0You\cc0\,5Tube\co: " . $title);
        public_msg($target_chan[0], "YouTube: " . $title);
    }
    else {
        printf "BAD YOUTUBE LINK!";
        public_msg($target_chan[0], "CONFUSING YOUTUBE URL!! :C :C");
    }
}


sub testscrape {
    printf "test\n";
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
