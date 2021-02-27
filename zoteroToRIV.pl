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

my $in_file = 'biblio-export-csl.json';

# Publikace z CSL JSON souboru ze Zotera
my $json = JSON->new->allow_nonref;
my $all_of_it = path( $in_file )->slurp;
my $zotero = $json->decode( $all_of_it );
#my $zotero = $json->decode( $string );
say "počet importovaných publikací: ", $#{$zotero};

# výstup do RIV XML
my $encoding = 'UTF-8';
my $el_name = "kniha";
my $text = "Švejk";
my $doc = XML::LibXML::Document->new('1.0',$encoding);
my $root = $doc->createElementNS( "", "results" );
$doc->setDocumentElement( $root );
my $element = $doc->createElement($el_name);
$element->setAttribute( 'author', 'Jaroslav Hašek' );
$element->appendText($text);
$element = $root->appendChild( $element );


#$state = $doc->toFile($filename, $format);

#if ($use_stdout) {
#    $doc->toFH( \*STDOUT );
#}
#else {
    #$doc->setCompression('6');
    #$doc->toFile( $out_filename, 0 );
    $doc->toFile( 'publikace.xml', 2 );
    #}
