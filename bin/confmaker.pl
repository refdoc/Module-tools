#!/usr/bin/perl
## confmaker.pl - provides a initial conf file for a new module by analysing  given OSIS xml file. 
## The programme searches for relevant tags and creates the GlobalOptionFilter entries and other relevant conf entries

## Licensed under the standard BSD license:

# Copyright (c) 2002-2009 CrossWire Bible Society <http://www.crosswire.org/>
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
use XML::LibXML;
use I18N::LangTags::List;
use Unicode::UCD 'charinfo';
binmode (STDOUT,":utf8");

## Obtain arguments
if (scalar(@ARGV) < 1) {
    print "\nconfmaker.pl -- - provides a initial conf file for a new module by analysing  given OSIS xml file. \n Syntax: confmaker.pl <osis XML file> [-o conf output file] \n";
    print "- Arguments in braces < > are required. Arguments in brackets [ ] are optional.\n";
    print "- If no -o option is specified <STDOUT> is used.\n";
    print "- The script can currently produce a valid conf file for OSIS bibles, but not for any other import formats.\n";
    exit (-1);
}

$file = @ARGV[0];

$nextarg = 1;

if (@ARGV[$nextarg] eq "-o") {
    $outputFilename = "@ARGV[$nextarg+1]";
    $nextarg += 2;
    open (OUTF, , ">:utf8", "$outputFilename") or die "Could not open file @ARGV[2] for writing.";
    select(OUTF)
}

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($file);



## obtain name, type and language

my @elements = $doc->getElementsByTagName('osisText');

my $doc_name = @elements[0]->getAttribute('osisIDWork');
my $doc_type = @elements[0]->getAttribute('osisRefWork');
my $doc_lang = @elements[0]->getAttribute('xml:lang');




##GlobalOptionsFilter - prepare

my @doc_features = ('title', 'note', 'reference', 'q', 'figure', 'rdg');
my @word_features = ('lemma', 'gloss', 'morph',);


my %doc_filters = ( 'title' => "OSISHeadings",
             'note'  => "OSISFootnotes",
             'reference' => "OSISScripRef",
             'gloss' => "OSISRuby",
             'lemma' => "OSISStrongs",
             'morph' => "OSISMorph",
             'q'  => "OSISRedLetterWords",
             'rdg' => 'OSISVariants',
            );
            
my %doc_feature = ( 'lemma' => 'StrongsNumbers',
                    'figure' => 'Images',
                  );
            
my %doc_has_feature;

## GlobalOptionsFilter - search for
            
foreach (@doc_features) {
   my @elements = $doc->getElementsByTagName($_);
   if (@elements>0) { $doc_has_feature{$_}=true } ;
   }

@elements = $doc->getElementsByTagName('w');

foreach my $f(@word_features) {

  foreach my $e(@elements) {
   if ($e->hasAttribute($f)) {
    $doc_has_feature{$f}=true;
    last;
   }
  }
 
}   


   
# Assemble and print out

print "[".$doc_name."]\n";
print "DataPath=./modules/texts/rawtext/".$doc_name."\n";
print "Description=This is the ".$doc_name." Bible in ".I18N::LangTags::List::name($doc_lang)." language\n";

if ($doc_type =~ m/Bible/) { print  "ModDrv=rawText\n"}
else {print  "ModDrv=rawUnknown\n"}

print  "Lang=".$doc_lang."\n";

foreach (@doc_features) {
   if ($doc_has_feature{$_}) { 
      print  "GlobalOptionFilter=".$doc_filters{$_}."\n"
      }
   }   
foreach (@word_features) {
   if ($doc_has_feature{$_}) { 
      print  "GlobalOptionFilter=".$doc_filters{$_}."\n"
      }
   }   
foreach (@doc_features) {
   if ($doc_has_feature{$_} && exists $doc_feature{$_}) { 
      print  "Feature=".$doc_feature{$_}."\n"
      }
   }   
foreach (@word_features) {
   if ($doc_has_feature{$_} && exists $doc_feature{$_}) { 
      print  "Feature=".$doc_feature{$_}."\n"
      }
   }   





print  "DistributionLicense=copyrighted. Do not distribute\n";
print  "About=This is the ".$doc_name." Bible in ".I18N::LangTags::List::name($doc_lang)." language\n";
print  "Encoding=UTF-8\n";
print  "SourceType=OSIS\n";
print  "Version=1.0\n";
print  "History=1.0 First release\n";
print  "LCSH=".$doc_type.".".I18N::LangTags::List::name($doc_lang)."\n";
