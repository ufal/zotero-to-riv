#!/usr/bin/env perl 

use v5.20;
use utf8;
use open qw(:std :utf8);
use strict;
use warnings;
use XML::LibXML;
use URI;
use URI::file;
use List::Util qw(first);
use JSON;
use Path::Tiny;

#use Getopt::Long;
#GetOptions( "stdout|s" => \our $use_stdout, "out|o" => \our $out_filename )
#  or die "Usage: $0 [--stdout|-s] [--out|-o] <filename>\n";

my $in_filename = 'biblio-export-csl.json';
my $out_filename = 'publikace.xml';

# Publications from a CSL JSON file
my $json = JSON->new->allow_nonref;
my $all_of_it = path( $in_filename )->slurp; #efficient with Path::Tiny
my $zotero = $json->decode( $all_of_it );
say "Imported $#{$zotero} results."; #debug

# RIV XML template
my $encoding = 'UTF-8';
my $doc = XML::LibXML::Document->new('1.0',$encoding);
my $root = $doc->createElementNS( "", "results" );
$doc->setDocumentElement( $root );
my $el_name = "result";

# loop over the imported results and output them
for my $res_idx ( 0..$#{$zotero} ) {
    my $title = $zotero->[$res_idx]->{"title"};

    # TODO: loop over all authors
    my $author_last = $zotero->[$res_idx]->{"author"}->[0]->{"family"};
    my $author_given = $zotero->[$res_idx]->{"author"}->[0]->{"given"};
    my $author = "$author_given "."$author_last";

    my ($attr_name, $attr_value) = ('author', $author);
    my $element = $doc->createElement($el_name);
    $element->setAttribute( $attr_name, $attr_value );
    $element->appendText( $title );
    $element = $root->appendChild( $element );
}

#$state = $doc->toFile($filename, $format);

#if ($use_stdout) {
#    $doc->toFH( \*STDOUT );
#}
#else {
    #$doc->setCompression('6');
    #$doc->toFile( $out_filename, 0 );
    $doc->toFile( $out_filename, 2 );
    #}
