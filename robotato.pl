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
use _goog;
use _weather;
use _youtube;
use _irssi;

$VERSION = '2.00';
%IRSSI = (
    authors     => 'Jared Tyler Miller, John Boyle',
    contact     => 'jtmiller@gmail.com, boylejm@gmail.com',
    name        => 'lmgtfy bot based on DCSS Bot Repeater',
    description => 'creates lmgtfy hyperlink based on msg',
    license     => 'Public Domain',
);

print CLIENTCRAP "loading goog.pl $VERSION!";

#if info.txt exists in the same directory as goog.pl, get server, bot, and room info from that
#line 1 = server
#line 2 = bot name
#line 3 = room

#otherwise, you will need to hardcode these explicitly below

my $root_server;
my $bot_name;
my $root_chan;
my $target_server;
my $infofile = "/home/johnstein/.irssi/scripts/info.txt";

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

my @target_chan;
push @target_chan, $root_chan;

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
                        gitme(lc $clean_msg);
                    }
                } 
                else {

		                private_msg($bot, $command . ' ' . $clean_msg);
                }
            }
        }
    }
}

Irssi::signal_add("message public", "dispatch");
Irssi::signal_add("message private", "priv_dispatch");
