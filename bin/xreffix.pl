#!/usr/bin/perl

## Creates proper OSIS references where usfm2osis has failed.

## Licensed under the standard BSD license:

# Copyright (c) 2009 CrossWire Bible Society <http://www.crosswire.org/>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
# 
#     * Redistributions of source code must retain the above copyright
#        notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * Neither the name of the CrossWire Bible Society nor the names of
#       its contributors may be used to endorse or promote products
#       derived from this software without specific prior written
#       permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
# IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
# TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## For general inquiries, comments, suggestions, bug reports, etc. email:
## sword-support@crosswire.org

#########################################################################
use Sword;
use feature "state";

$version = "1.1";
$osisVersion = "2.1.1";

$date = '$Date: 2010-08-04 05:46:26 +0000 (Tue, 04 Aug 2009) $';
$rev = '$Rev: 231 $';

$mgr = new Sword::SWMgr();
$module = $mgr->getModule('GERSCH2000');

if (scalar(@ARGV) < 1) {
    print "xreffix.pl -- fixes crossreferences in OSIS files where usfm2osis.pl has failed. version $version\nRevision $rev ($date)\nSyntax: xreffix.pl <input filename> [-o <output-file>] [-l <xreflocale>].\n";
    exit (-1);
}

if ($ARGV[1] eq "-o") {
    $outputFilename = "$ARGV[2]";
}
else {
    $outputFilename = "$ARGV[0].fixed.xml";
}
if ($ARGV[1] eq "-l") {
    $locale = "$ARGV[2];"
}
elsif ($ARGV[3] eq "-l") {
    $locale = "$ARGV[4];"
}
else {
    $locale = "en";
}

Sword::LocaleMgr::getSystemLocaleMgr()->setDefaultLocaleName($locale);

open (OUTF, ">", "$outputFilename") or die "Could not open file $outputFilename for writing.";

open (INF, "<", $ARGV[0]);
@data = <INF>;
close (INF);

$c_book = "Gen";
$c_chapter="1";
$c_verse="1";

addRefs();
readLocale();

foreach (@data) {
    
    # the actual document locale takes preference. Not sure if this is a good decision
    
    if (/xml:lang\=\"(.+?)\"/) { 
        if ($locale ne $1) {
            print "This document is in the locale of ".$1."\n";
            Sword::LocaleMgr::getSystemLocaleMgr()->setDefaultLocaleName($1);
        }    
            
    }
    
    # The conversion to OSIS requires a context scope for single verse references. 
    # This needs to be always maintained and passed on.
    
    if (/<div\ type\=\"book\"\ osisID=\"(.+?)\">/) { 
        $c_book=$1;
        print "\n"."Now working on ".$c_book."\n";
    }
    if (/<chapter\ sID\=\".*?\.([0-9]+)\"/) { 
        $c_chapter=$1;
        print "\n"."Now working on ".$c_book.$c_chapter."\n";

    }
    if (/<verse\ sID\=\".*?\.([0-9]+)\"/) { 
        $c_verse=$1;
    }
    
    # Finally the isolated references are passed to the actual conversion routine
    
    s/<reference>(.*?)<\/reference>/createReference($1,$c_book,$c_chapter,$c_verse)/eg;

    s/<note\ type=\"crossReference\">(.*?)<\/note>/"<note n=\"".note_index()."\" osisID=\"$c_book.$c_chapter.$c_verse!crossReference.".note_index()."\" osisRef=\"$c_book.$c_chapter.$c_verse\" type=\"crossReference\">".$1."<\/note>"/eg;   
    
    }
    
print (OUTF @data);    
close OUTF;

####################################################################################

# In the conversion routine the references need to get cleaned up and prepared for conversion

sub createReference() {

    my $ref	=	@_[0];
    print "I got this here: ".$ref."\n";
    print "this is the current scope: ".@_[1].".".@_[2].".".@_[3]."\n";
    my $scope= new Sword::VerseKey;
    $scope->setText(@_[1].".".@_[2].".".@_[3]);    
    
    
    # This is about changing the various separators etc for non-English vocales into English ones
    # You need to be careful if you change any of the indicators. The order of changes currently done is for German. 
    # Look at the list given in sub readLocale. 
    # If your text is in English or marked up along English lines you will need to comment out a few sections.
     
    $ref	=~ s/$sep_cv/:/g;
    $ref	=~ s/;$ind_v\ /;\ /g;
    $ref	=~ s/^$ind_v//;
    $ref	=~ s/$sep_l/,/g;
    
    
    # Sometimes xrefs have prose content apart from the actual references. 
    
    my @refs = split(/$fill_start/,$ref);
    
    my $return='';
    foreach (@refs) {
        
        # I am sure this can be done more elegantly, but I have currently no clue 
        # Basically repetitive prose content in xrefs like "compare" needs to get "neutralised prior to conversion to OSIS, 
        # but it should not get lost, so I attach it here to the return string

        if (/^$fill_end/) {
            $return = $return." ".$fill;
            $_ =~ s/^$fill_end//;
            }
            
        print "I put this here in:".$_."\n";    
        $return = $return.Sword::VerseKey::convertToOSIS($_, $scope) ;
        }
    print "and I created that: ".$return."\n";
    
    # After the cleansing and conversion in to English standard we want to recreate in the reference prose the original separators
    
    $return =~ s/(>.*?),(?=.*?<)/$1.$sep_l.$2/eg;
    $return =~ s/(>.*?):(?=.*?<)/$1$sep_cv$2/g;
    
    
    $return;
    }
    
sub note_index {

    my @note = qw(a a b b c c d d e e f f g g h h i i j j k k l l m m n n o o p p q q r r s s t t u u v v w w x x y y z z );
    state $i=0;
    my $return = $note[$i % 52];
    ++$i;
    $return;
    }
                            
    
#####################################################################################
# Edit the following subroutines for your particular project

# Many locale have different indicators for book/chapter/verse separation etc. The conversion routine requires English standard separators

sub readLocale () {

    $sep_bc = ' ';		# separator between books and chapters
    $sep_cv = ',';		# separator between chapters and verses
    $ind_v	= 'V\.';		# indicator for single verse - unfortunatly this will get lost in the conversion.
    $sep_l	= '\.';		# separator for list of chapters or verses

    $fill_start 	=";vg"; 	# indicators for "compare"
    $fill_end		="l";	# /	-> reads as "vgl." 
    $fill		= 'vgl.'#/

}

# Your text might have references which are not yet marked up. Here is your chance to do so.
    
sub addRefs () {

    foreach (@data) {
        
        
        # references included inline    
        s/\(z\.B\.\ (.*?)\)/\(z\.B\.\ <reference>$1<\/reference>\)/g;
        
        # parallel reference subtitles
        s/<title\ type=\"parallel\">(.*?)<\/title>/<title\ type=\"parallel\"><reference>$1<\/reference><\/title>/g;
        }

}          