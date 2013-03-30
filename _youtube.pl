#!/usr/bin/env perl
use local::lib;
use strict;
use warnings;
use Data::Dumper;
use WWW::Mechanize;
use URI::Find::Schemeless;

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
1;
