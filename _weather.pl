#!/usr/bin/env perl
use local::lib;
use strict;
use warnings;
use Data::Dumper;
use Weather::Underground;
use _irssi;

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
}