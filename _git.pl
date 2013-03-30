#!/usr/bin/env perl
use local::lib;

use strict;
use Irssi;
use warnings;
use Data::Dumper;
require '_irssi.pl';

sub gitme {
  public_msg($target_chan[0], "I live at -> https://github.com/jmbjr/robotato.git");
}
