#!/usr/bin/env perl
use local::lib;
use strict;
use warnings;
use Data::Dumper;
use LWP::Simple;
use LWP::UserAgent;
require '_irssi.pl';

sub goog {
   my ($query) = @_; 
   $query = join "+", split " ", $query;
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
      $unlucky=1;
   }

   printf "|" . $redirectURI . "|";
   if ($unlucky) {
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI  );
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $theURI  );
   }
   else {
      public_msg($target_chan[0], "\cc12G\cc4o\cc7o\cc12g\cc9l\cc4e \cc0: \co " . $redirectURI  );
   }

   if ( checkYT(trim($redirectURI)) ) {
       scrapeYT($redirectURI);
   }

}