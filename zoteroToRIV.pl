#!/usr/bin/env perl 

use v5.20;
use utf8;
use open qw(:std :utf8);
use strict;
use warnings;
use local::lib;
use XML::LibXML;
use JSON;
use Path::Tiny;

use Getopt::Long;
GetOptions(
    "stdout"   => \our $use_stdout,
    "output=s" => \our $out_filename,
    "input=s"  => \our $in_filename,
    "debug"    => \our $debug,
  )
  or die
  "Usage: $0 [--stdout|-s] --debug [--in|-i] <file> [--out|-o] <filename>\n";

#  $in_filename   = 'Zotero/test-ufal.json';
#  $out_filename  = 'RIV21-MSM-11320___,R01.vav';
my $obdobi           = 2021;
my $ico              = '00216208';                   # IČO of Univerzita Karlova
my $org_unit_id      = 11320;                        # RIV ID of MFF (faculty)
my $autor_dodavky    = "Pavel Straňák";
my $autor_tel        = "221 914 247";
my $autor_email      = 'stranak@ufal.mff.cuni.cz';
my $verze            = "01";
my $cislo_jednaci    = 1;
my $id_vvi           = 90101; # ID VVI LINDAT/CLARIAH-CZ 01.01.2019 - 31.12.2022
my $fallback_obor    = "Matematická lingvistika";    # CUNI
my $debug_obor       = "10201";  # OECD; valid RIV value, use for RVVI validator
my $fallback_keyword = "Digital Humanities";

# Publications from a CSL JSON file
my $json      = JSON->new->allow_nonref;
my $all_of_it = path("$in_filename")->slurp;    #efficient with Path::Tiny
my $zotero    = $json->decode($all_of_it);
say STDERR "Imported $#{$zotero} results.";     #info

# RIV XML template – START
my $encoding = 'utf8';
my $doc      = XML::LibXML::Document->new( '1.0', $encoding );
my $root =
  $doc->createElementNS( "urn:CZ-RVV-IS-VaV-XML-NS:data-1.2.9", "dodavka" );
$doc->setDocumentElement($root);
$root->setAttribute( 'struktura', 'RIV21A' );

#zahlavi = rozsah + dodavatel
my $header = $doc->createElement('zahlavi');
$header = $root->appendChild($header);

# rozsah
my $rozsah = $doc->createElement('rozsah');
$rozsah = $header->appendChild($rozsah);
$rozsah->appendTextChild( 'informacni-oblast', 'RIV' );
$rozsah->appendTextChild( 'obdobi-sberu',      $obdobi );
my $predkladatel = $doc->createElement('predkladatel');
$predkladatel = $rozsah->appendChild($predkladatel);
my $subjekt = $doc->createElement('subjekt');
$subjekt = $predkladatel->appendChild($subjekt);
$subjekt->appendTextChild( 'druh', 'verejna-vysoka-skola' );
$subjekt->appendTextChild( 'ICO',  $ico );
my $uk = $doc->createElement('nazev');
$uk = $subjekt->appendChild($uk);
$uk->appendTextNode('Univerzita Karlova');
$uk->setAttribute( 'jazyk', '#ORIG' );
my $cu = $doc->createElement('nazev');
$cu = $subjekt->appendChild($cu);
$cu->appendTextNode('Charles University');
$cu->setAttribute( 'jazyk', 'eng' );
$subjekt->appendTextChild( 'nadrizena-organizacni-slozka-statu', 'MSM' );

my $org_unit = $doc->createElement('organizacni-jednotka');
$org_unit = $predkladatel->appendChild($org_unit);
$org_unit->appendTextChild( 'kod', $org_unit_id );
my $mff = $doc->createElement('nazev');
$mff = $org_unit->appendChild($mff);
$mff->appendTextNode('Matematicko-fyzikální fakulta');
$mff->setAttribute( 'jazyk', '#ORIG' );
my $mff_en = $doc->createElement('nazev');
$mff_en = $org_unit->appendChild($mff_en);
$mff_en->appendTextNode('Faculty of Mathematics and Physics');
$mff_en->setAttribute( 'jazyk', 'eng' );

# dodavatel
my $dodavatel = $header->addNewChild( "", 'dodavatel' );
$dodavatel->addNewChild( '', 'subjekt' )->appendTextChild( 'kod', 'MSM' );
my $osoba =
  $dodavatel->addNewChild( '', 'pracovnik-povereny-pripravou-dodavky' )
  ->addNewChild( '', 'osoba' );
$osoba->appendTextChild( 'cele-jmeno', $autor_dodavky );
my $kontakt = $osoba->addNewChild( '', 'kontakt' );
my $tel     = $kontakt->addNewChild( '', 'telefonni-cislo' );
$tel->setAttribute( 'druh', 'telefon' );
$tel->appendText($autor_tel);
$kontakt->appendTextChild( 'emailova-adresa', "$autor_email" );

$header->appendTextChild( 'verze', "$verze" );
$header->addNewChild( '', 'pruvodka' )
  ->setAttribute( 'cislo-jednaci', "$cislo_jednaci" );

#obsah
my $content = $doc->createElement('obsah');
$content = $root->appendChild($content);
my $result_elem_name = "vysledek";

# RIV XML Template – END

#JSON attributes to RIV XML elements – mapping
my %name_mapped = (
    "language" => "jazyk",
    "type"     => "druh",
    "abstract" => "anotace",
    "title"    => "nazev",
    "author"   => "autor",
    "last"     => "prijmeni",
    "given"    => "jmeno",
    "URL"      => "odkaz",
    "DOI"      => "doi",
);

# loop over the imported results and output them
for my $res_idx ( 0 .. $#{$zotero} ) {

    # set and normalise some attributes
    my $lang = $zotero->[$res_idx]->{"language"} // 'eng';
    $zotero->[$res_idx]->{"language"} = $lang; # everything MUST have a language

    # RIV ID like: identifikacni-kod="RIV/00216208:11320/17:10336140"
    my $zotero_item_id = $zotero->[$res_idx]->{"id"};
    $zotero_item_id =~ s{^http://zotero\.org/groups/2792663/items/}{};
    my $shortyear =
      $obdobi - 2000;    #TODO uplatneni nebo sberu? Toto je spravne pro sber!
    my $id = "RIV/$ico:$org_unit_id/$shortyear:$zotero_item_id";

    # generate and fill-in the node
    my $result = $content->addNewChild( '', $result_elem_name );

    # fixed result attributes - template
    $result->setAttribute( 'identifikacni-kod', $id );
    $result->setAttribute( 'duvernost-udaju',   'verejne-pristupne' );

    #    $result->setAttribute( 'rok-uplatneni',     $obdobi );
    $result->setAttribute( 'druh', 'ostatni' );  #TODO implementovat dalsi druhy

    # klasifikace – at least the main area (obor) and one keyword required
    my $klasifikace = $result->addNewChild( '', 'klasifikace' );
    my $obor_node   = $klasifikace->addNewChild( '', 'obor' );
    $obor_node->setAttribute( 'postaveni', 'hlavni' );
    $obor_node->setAttribute( 'ciselnik',  'oblastiOECD' )
      ;    # obor dle klasifikace UK
           # get "obor" (area) from CSL and set it
           # CSL JSON doesn't have an attribute for this. We store it in
           # 'note' (Zotero displays as 'Extra') line 'obor:value'
    my ( $obor, @keywords );

    # date issued = rok-uplatneni || obdobi sberu
    if ( defined $zotero->[$res_idx]->{'issued'} ) {
        my $rok = $zotero->[$res_idx]->{'issued'}->{'date-parts'}->[0]->[0];
        $result->setAttribute( 'rok-uplatneni', $rok );
    }
    else {
        warn "Item $id has no year issued. Inserting $obdobi.\n";
        $result->setAttribute( 'rok-uplatneni', $obdobi );
    }

    # Attributes not covered by the Zotero scheme.
    # We store them as "key: value" pairs in the "note" field
    if ( defined $zotero->[$res_idx]->{'note'} ) {
        my $note = $zotero->[$res_idx]->{'note'};
        $note =~ m/^\s*field\s*:\s*(\N+)\s*$/sm;
        $obor = $1;
        $note =~ m/^\s*kw\s*:\s*(\N+)\s*$/sm;
        my $kw_string = $1;
        @keywords = split( /,\s*/, $kw_string ) if defined $kw_string;
    }
    if (@keywords) {
        for my $kw (@keywords) {
            my $keyword_node = $klasifikace->addNewChild( '', 'klicove-slovo' );
            $keyword_node->setAttribute( 'jazyk', 'eng' );  # must be in English
            $keyword_node->appendText($kw);
        }
    }
    else {    # a fallback keyword to make data valid RIV
        my $keyword_node = $klasifikace->addNewChild( '', 'klicove-slovo' );
        $keyword_node->setAttribute( 'jazyk', 'eng' );    # must be in English
        $keyword_node->appendText($fallback_keyword);
    }

    # a fallback area (obor) to make data valid RIV
    $obor = $fallback_obor if not defined $obor;
    $obor = $debug_obor
      if $debug;    # override - use the OECD value for the validator
    $obor_node->appendText($obor);

    # navaznosti - support of the LRI (why we are doing all of this)
    my $navaznosti = $result->addNewChild( '', 'navaznosti' );
    my $navaznost  = $navaznosti->addNewChild( '', 'navaznost' );
    $navaznost->setAttribute( 'druh-vztahu', 'byl-dosazen-pri-reseni' )
      ;             # p. 28 XML docs
    my $vvi = $navaznost->addNewChild( '', 'vvi' );
    $vvi->setAttribute( 'identifikacni-kod', $id_vvi );

  LANGUAGE: {
        if ( $lang =~ /^en(g|glish)?$/i ) {
            $lang = 'eng';    # normalise English to ISO-639-3
        }
        else {    # non-English, so look for English Title and Abstract
            my ( $eng_title, $eng_abstract );

            #English Title (cut it and leave the original)
            my $note = $zotero->[$res_idx]->{'note'};
            $note =~ m/^\s*title_EN\s*:\s*(\N+)\s*$/sm
              || die "ID: ",
              $zotero->[$res_idx]->{"id"},
              " missing English title.\n",
              "Zotero title: $1\n",
              "\$1: $1";
            $eng_title = $1;
            my $et_node = $result->addNewChild( '', $name_mapped{"title"} );
            $et_node->appendText($eng_title);
            $et_node->setAttribute( 'jazyk', 'eng' );

            # English Abstract (cut it and leave the original)
            $note =~ m/^\s*abstract_EN\s*:\s*(\N+)\s*$/sm
              || die "ID: ", $zotero->[$res_idx]->{"id"},
              " missing English abstract.";
            $eng_abstract = $1;
            my $ea_node = $result->addNewChild( '', $name_mapped{"abstract"} );
            $ea_node->appendText($eng_abstract);
            $ea_node->setAttribute( 'jazyk', 'eng' );
        }
    }

    # simple text nodes one per result
    # (except for English abstract and titles of foreign language results above)
    for my $name (qw(language title abstract URL DOI)) {
        if ( defined $zotero->[$res_idx]->{$name} ) {

     #            $lang = $zotero->[$res_idx]->{"$name"} if $name eq 'language';
            if ( $name eq 'DOI' ) {    # remove the URL part to make a valid DOI
                $zotero->[$res_idx]->{$name} =~ s/^.*10\./10\./;
            }
            my $node = $result->addNewChild( '', $name_mapped{"$name"} );
            $node->appendText( $zotero->[$res_idx]->{$name} );
            $node->setAttribute( 'jazyk', $lang )
              if $name eq 'title' or $name eq 'abstract';
        }
    }

    # complex nodes

    # authors
    #    my $authors_node = $doc->createElement('autori');
    my $authors_node = $result->addNewChild( '', 'autori' );
    my $pocet_autoru;

    # loop over all authors
    for my $auth_idx ( 0 .. $#{ $zotero->[$res_idx]->{"author"} } ) {

        # get the author
        $pocet_autoru += 1;
        my $author_last =
          $zotero->[$res_idx]->{"author"}->[$auth_idx]->{"family"};
        my $author_given =
          $zotero->[$res_idx]->{"author"}->[$auth_idx]->{"given"};

        # set the author
        my $authornode =
          $authors_node->addNewChild( '', $name_mapped{'author'} );
        $authornode->setAttribute( 'je-domaci', 'false' );
        $authornode->appendTextChild( $name_mapped{'given'}, $author_given );
        $authornode->appendTextChild( $name_mapped{'last'},  $author_last );
    }
    $authors_node->setAttribute( 'pocet-celkem',   $pocet_autoru );
    $authors_node->setAttribute( 'pocet-domacich', '0' );
}

#TODO klasifikace, navaznosti, spravna ID zaznamu

#$state = $doc->toFile($filename, $format);

#if ($use_stdout) {
#    $doc->toFH( \*STDOUT );
#}
#else {
#$doc->setCompression('6');
#$doc->toFile( $out_filename, 0 );
$doc->toFile( $out_filename, 2 );

#}
