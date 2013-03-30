#!/usr/bin/env perl
use local::lib;

use strict;
use Irssi;
use warnings;
use Data::Dumper;
require 'robotato.pl';

sub gitme {
  my $target_chan = @_;
  public_msg($target_chan, "I live at -> https://github.com/jmbjr/robotato.git");
}
