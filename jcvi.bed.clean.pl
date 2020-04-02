#!/usr/bin/env perl
use strict;
use warnings;
use constant USAGE =><<EOH;

usage: \$0 source.bed chr.list filter.bed

Version: 20200402

Descriptions
    Extract specified chromosomes from source bed to filter.bed

###chr.list: wanted IDs in col1 of source.bed
### one ID per line
chr1
chr2
contig1
...

EOH
die USAGE if (scalar(@ARGV) != 3);



my $linenum=0;
my %idhash=();

open (IDLIST, "<", $ARGV[1]) || die "Error: can not open chr.list: $ARGV[1]\n";
while (my $line=<IDLIST>) {
	chomp $line;
	$linenum++;
	if (exists $idhash{$line}) {
		print STDERR "Warnings: duplicated IDs: $line\n";
		next;
	}
	$idhash{$line}++;
}
close IDLIST;
print "### SUM1 ###\n";
print "chr.list total lines: $linenum\n";
print "Total valid IDs: ", scalar(keys %idhash), "\n";

open (BED1FILE, "<", $ARGV[0]) || die "Error: can not open source.bed: $ARGV[0]\n";
open (BED2FILE, ">", $ARGV[2]) || die "Error: can not write filter.bed: $ARGV[2]\n";

$linenum=0;
my $lineout=0;
my $lineInc=0;
my $lineExc=0;
while (my $line=<BED1FILE>) {
	chomp $line;
	$linenum++;
	if ($line=~/^#/) {
		print BED2FILE $line, "\n";
		$lineout++;
		next;
	}
	my @arr=split(/\t/, $line);
	if (exists $idhash{$arr[0]}) {
		print BED2FILE $line, "\n";
		$lineout++;$lineInc++;
		next;
	}
	else {
		$lineExc++;next;
	}
}

close BED1FILE;
close BED2FILE;
print "### SUM2 total lines ###\n";
print "source.bed :       $linenum\n";
print "filter.bed :       $lineout\n";
print "  valid lines :    $lineInc\n";
print "  invalid lines: : $lineExc\n";
