#!/usr/bin/env perl
use local::lib;

use strict;
use Irssi;
use warnings;
use vars qw($VERSION %IRSSI);
use Data::Dumper;
use WWW::Mechanize;
use URI::Find::Schemeless;

our $robodir = "/home/johnstein/.irssi/scripts/";

require $robodir . '_weather.pl';
require $robodir . '_git.pl';
#require $robodir . '_youtube.pl';
require $robodir . '_googme.pl';

$VERSION = '2.00';
%IRSSI = (
    authors     => 'Jared Tyler Miller, John Boyle',
    contact     => 'jtmiller@gmail.com, boylejm@gmail.com',
    name        => 'lmgtfy bot based on DCSS Bot Repeater',
    description => 'creates lmgtfy hyperlink based on msg',
    license     => 'Public Domain',
);

print CLIENTCRAP "loading ROBOTATO $VERSION!";

Irssi::settings_add_str("targetserver", "target_server", "");
Irssi::settings_add_str("rootchan", "root_chan", "");
Irssi::settings_add_str("rootserver", "root_server", "");
Irssi::settings_add_str("crawlwatch", "crawlwatchnicks", "");
Irssi::settings_add_str("targetchan", "target_chan", "");

#if info.txt exists in the same directory as goog.pl, get server, bot, and room info from that
#line 1 = server
#line 2 = bot name
#line 3 = room

#otherwise, you will need to hardcode these explicitly below

our $root_server;
our $bot_name;
our $root_chan;
our $target_server;
our $infofile = $robodir . "info.txt";

if (-e $infofile) {
  #read file and set variables
  #line 1 = server
  #line 2 = bot name
  #line 3 = room  
  #NEEDS error checking to ensure the info file has correct format
  #also needs error checking to verify the strings make sense
  my @thearray;
    
  open (my $fh, "<" . $infofile)
     or die "FAILED TO OPEN INFO FILE! $!\n";
  while(<$fh>) {
    chomp;
    push @thearray, $_;
  }
  close $fh;

  $root_server = $thearray[0];
  $bot_name = $thearray[1];
  $root_chan = $thearray[2];
  $target_server = $thearray[0];
}
else {
  printf "File: " . $infofile . " does NOT exist!";
  $root_server = "<server>";
  $bot_name = "<botname>";
  $root_chan = "<room>";
  $target_server = "<server>";  
}

our (@target_chan, $target_chan);
push @target_chan, $root_chan;

#stupid hack to ensure the dispatch function below knows what channel and server we are on
Irssi::settings_set_str("root_server", $root_server);
Irssi::settings_set_str("root_chan", $root_chan);
Irssi::settings_set_str("target_server", $target_server);
Irssi::settings_set_str("target_chan", $target_chan[0]);

my $ts = Irssi::server_find_tag($target_server);
my $rs = Irssi::server_find_tag($root_server);

#add new commands here
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
                        goog(lc $clean_msg, $target_chan[0]);
                    }
                    elsif ($command eq '!weather') {
                        #printf "the command is: " . $clean_msg;
                        weather(lc $clean_msg, $target_chan[0]);
                    }
                    elsif ($command eq '!fullweather') {
                        #printf "the command is: " . $clean_msg;
                        fullweather(lc $clean_msg, $target_chan[0]);
                    }
                    elsif ($command eq '!git') {
                        gitme(lc $clean_msg, $target_chan[0]);
                    }
                } 
                else {

		        private_msg($bot, $command . ' ' . $clean_msg);
                }
            }
        }
    }
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
    $rs->send_message($bot, $msg, 1)
}

sub dispatch {
    my ($server, $msg, $nick, $mask, $chan) = @_;
    $target_server = Irssi::settings_get_str("target_server");
    $root_chan = Irssi::settings_get_str("root_chan");
    $root_server = Irssi::settings_get_str("root_server");
    $target_chan = Irssi::settings_get_str("target_chan");

    printf $root_chan;
    printf $root_chan;
    printf $target_server;

    if (lc($chan) eq lc($target_chan)) {
        if ( checkYT(trim($msg), $target_chan) ) {
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


sub scrapeYT {
    my ($msg,  $target_chan) = @_;
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
        public_msg($target_chan, "YouTube: " . $title);
    }
    else {
        printf "BAD YOUTUBE LINK!";
        public_msg($target_chan, "CONFUSING YOUTUBE URL!! :C :C");
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

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message private", "priv_dispatch");
#Irssi::settings_add_str("targetchan", "target_chan", "");
#Irssi::settings_add_str("rootchan", "root_chan", "");
#Irssi::settings_add_str("targetserver", "target_server", "");
#Irssi::settings_add_str("crawlwatch", "crawlwatchnicks", "");



