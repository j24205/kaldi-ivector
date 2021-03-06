#!/usr/bin/perl
#
# Copyright 2014  David Snyder
# Apache 2.0.


if (! -f "data/local/sre05-key-v7b.txt") {
  `mkdir -p data/local/`;
  `wget -P data/local/ http://www.openslr.org/resources/10/sre05-key-v7b.txt.gz`;
  `gunzip data/local/sre05-key-v7b.txt.gz`;
}

if (@ARGV != 2) {
  print STDERR "Usage: $0 <path-to-LDC2011S04> <path-to-output>\n";
  print STDERR "e.g. $0 /export/corpora5/LDC/LDC2011S04 data\n";
  exit(1);
}

($db_base, $out_dir) = @ARGV;
$out_dir = "$out_dir/sre05_test/";

if (system("mkdir -p $out_dir")) {
  die "Error making directory $out_dir";
}

open(TRIALS, "<data/local/sre05-key-v7b.txt")
  or die "Could not open data/local/sre05-key-v7b.txt";
open(GNDR,">", "$out_dir/spk2gender")
  or die "Could not open the output file $out_dir/spk2gender";
open(SPKR,">", "$out_dir/utt2spk")
  or die "Could not open the output file $out_dir/utt2spk";
open(WAV,">", "$out_dir/wav.scp")
  or die "Could not open the output file $out_dir/wav.scp";

$data_src_suffix = "sre05_test";
chomp($data_src_suffix);

while($line=<TRIALS>) {
  @attrs = split(" ", $line);
  $basename = $attrs[3];
  $side = uc $attrs[4];
  
  if (not $side eq "A" and not $side eq "B") {
    print "Skipping unknown or summed channel $side in $basename\n";
    next;
  }

  $spkr = $attrs[2] . "_$data_src_suffix";
  $gender = lc $attrs[6];
  if (not $gender eq "m" and not $gender eq "f") {
    print "Skipping speaker $attrs[2] with unknown gender $gender.\n";
    next;
  }
  print GNDR "$spkr $gender\n";
  $wav = $db_base."/data/$basename.sph";
  $basename =~ s/.sph//;
  $uttId = $spkr . "-" . $basename . "_" . $side;
  if ( $side eq "A" ) {
    $channel = 1;
  } elsif ( $side eq "B" ) {
    $channel = 2;
  } else {
    die "unknown channel $side\n";
  }
  if ($wav && -e $wav) {
    print WAV "$uttId"," sph2pipe -f wav -p -c $channel $wav |\n";
    print SPKR "$uttId"," $spkr","\n";
  } else {
    print STDERR "Missing $wav\n";
  }
}
close(GNDR) || die;
close(SPKR) || die;
close(WAV) || die;
close(TRIALS) || die;


if (system(
  "utils/utt2spk_to_spk2utt.pl $out_dir/utt2spk >$out_dir/spk2utt") != 0) {
  die "Error creating spk2utt file in directory $out_dir";
}
  system("utils/fix_data_dir.sh $out_dir");
if (system(
  "utils/validate_data_dir.sh --no-text --no-feats $out_dir") != 0) {
  die "Error validating directory $out_dir";
}
