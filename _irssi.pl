#!/usr/bin/env perl
use local::lib;

use strict;
use Irssi;
use warnings;
use vars qw($VERSION %IRSSI);
use _youtube;


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

    if (lc($chan) eq lc($target_chan[0])) {
        if ( checkYT(trim($msg)) ) {
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