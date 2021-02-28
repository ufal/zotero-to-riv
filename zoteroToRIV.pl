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
my $result_elem_name = "result";

# loop over the imported results and output them
for my $res_idx ( 0..$#{$zotero} ) {
    my $result = $doc->createElement($result_elem_name);
    $result = $root->appendChild( $result );

    # simple text nodes unique per result
    for my $name ( qw(type language title abstract source) ) {
        $result->appendTextChild(
            $name , 
            $zotero->[$res_idx]->{"$name"} 
        ) if $zotero->[$res_idx]->{"$name"};
    }
    # complex nodes
    # authors
    my $authors_node = $doc->createElement('authors');
    $authors_node = $result->addChild( $authors_node );

    # loop over all authors
    for my $auth_idx ( 0..$#{$zotero->[$res_idx]->{"author"}} ){

        # get the author
        my $author_last = 
             $zotero->[$res_idx]->{"author"}->[$auth_idx]->{"family"};
        my $author_given = 
             $zotero->[$res_idx]->{"author"}->[$auth_idx]->{"given"};

        # set the author
        my $authornode = $doc->createElement('author');
        $authornode = $authors_node->addChild( $authornode );
        $authornode->setAttribute('last', $author_last);
        $authornode->setAttribute('given', $author_given);
    }
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
