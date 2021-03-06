# -*-Perl-*- Test Harness script for Bioperl
# $Id$

use strict;

BEGIN {
    use lib '.';
#    use List::MoreUtils qw(uniq);
    use Bio::Root::Test;
    
    test_begin(-tests => 125);

    use_ok('Bio::PrimarySeq');
    use_ok('Bio::SeqUtils');
    use_ok('Bio::LiveSeq::Mutation');
    use_ok('Bio::SeqFeature::Generic');
    use_ok('Bio::Annotation::SimpleValue');
    use_ok('Bio::Annotation::Collection');
    use_ok('Bio::Annotation::Comment');
}

my ($seq, $util, $ascii, $ascii_aa, $ascii3);

# Entire alphabet now IUPAC-endorsed and used in GenBank (Oct 2006)          
$ascii =    'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
$ascii_aa = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

$ascii3 = 
    'AlaAsxCysAspGluPheGlyHisIleXleLysLeuMetAsnPylProGlnArgSerThrSecValTrpXaaTyrGlx';

$seq = Bio::PrimarySeq->new('-seq'=> $ascii,
                            '-alphabet'=>'protein', 
                            '-id'=>'test');

# one letter amino acid code to three letter code
ok $util = Bio::SeqUtils->new();
is $util->seq3($seq), $ascii3;

#using anonymous hash
is (Bio::SeqUtils->seq3($seq), $ascii3); 
is (Bio::SeqUtils->seq3($seq, undef, ','), 
    'Ala,Asx,Cys,Asp,Glu,Phe,Gly,His,Ile,Xle,Lys,'.
    'Leu,Met,Asn,Pyl,Pro,Gln,Arg,Ser,Thr,Sec,Val,Trp,Xaa,Tyr,Glx');

$seq->seq('asd-KJJK-');
is (Bio::SeqUtils->seq3($seq, '-', ':'), 
    'Ala:Ser:Asp:Ter:Lys:Xle:Xle:Lys:Ter');

# three letter amino acid code to one letter code
ok (Bio::SeqUtils->seq3in($seq, 'AlaPYHCysAspGlu')); 
is $seq->seq, 'AXCDE';
is (Bio::SeqUtils->seq3in($seq, $ascii3)->seq, $ascii_aa);

#
# Tests for multiframe translations
#

$seq = Bio::PrimarySeq->new('-seq'=> 'agctgctgatcggattgtgatggctggatggcttgggatgctgg',
                            '-alphabet'=>'dna', 
                            '-id'=>'test2');

my @a = $util->translate_3frames($seq);
is scalar @a, 3;
#foreach $a (@a) {
#    print 'ID: ', $a->id, ' ', $a->seq, "\n";
#}

@a = $util->translate_6frames($seq);
is scalar @a, 6;
#foreach $a (@a) {
#    print 'ID: ', $a->id, ' ', $a->seq, "\n";
#}

#
# test for valid AA return
#

my @valid_aa = sort Bio::SeqUtils->valid_aa;
is(@valid_aa, 27);
is($valid_aa[1], 'A');

@valid_aa = sort Bio::SeqUtils->valid_aa(1);
is(@valid_aa, 27);
is ($valid_aa[1], 'Arg');

my %valid_aa = Bio::SeqUtils->valid_aa(2);
is keys %valid_aa, 54;
is($valid_aa{'C'}, 'Cys');
is( $valid_aa{'Cys'}, 'C');


#
# Mutate
#

my $string1 = 'aggt';
$seq = Bio::PrimarySeq->new('-seq'=> 'aggt',
                            '-alphabet'=>'dna',
                            '-id'=>'test3');

# point
Bio::SeqUtils->mutate($seq,
                      Bio::LiveSeq::Mutation->new(-seq => 'c',
                                                  -pos => 3
                                                 )
                     );
is $seq->seq, 'agct';

# insertion and deletion
my @mutations = (
                 Bio::LiveSeq::Mutation->new(-seq => 'tt',
                                             -pos => 2,
                                             -len => 0
                                            ),
                 Bio::LiveSeq::Mutation->new(-pos => 2,
                                             -len => 2
                                            )
);

Bio::SeqUtils->mutate($seq, @mutations);
is $seq->seq, 'agct';

# insertion to the end of the sequence
Bio::SeqUtils->mutate($seq,
                      Bio::LiveSeq::Mutation->new(-seq => 'aa',
                                                  -pos => 5,
                                                  -len => 0
                                                 )
                     );
is $seq->seq, 'agctaa';



#
# testing Bio::SeqUtils->cat
#

# PrimarySeqs

my $primseq1 = Bio::PrimarySeq->new(-id => 1, -seq => 'acgt', -description => 'master');
my $primseq2 = Bio::PrimarySeq->new(-id => 2, -seq => 'tgca');

Bio::SeqUtils->cat($primseq1, $primseq2);
is $primseq1->seq, 'acgttgca';
is $primseq1->description, 'master';

#should work for Bio::LocatableSeq
#should work for Bio::Seq::MetaI Seqs?


# Bio::SeqI

my $seq1 = Bio::Seq->new(-id => 1, -seq => 'aaaa', -description => 'first');
my $seq2 = Bio::Seq->new(-id => 2, -seq => 'tttt', -description => 'second');
my $seq3 = Bio::Seq->new(-id => 3, -seq => 'cccc', -description => 'third');


#  annotations
my $ac2 = Bio::Annotation::Collection->new();
my $simple1 = Bio::Annotation::SimpleValue->new(
                                                -tagname => 'colour',
                                                -value   => 'blue'
                                               ), ;
my $simple2 = Bio::Annotation::SimpleValue->new(
                                                -tagname => 'colour',
                                                -value   => 'black'
                                               ), ;
$ac2->add_Annotation('simple',$simple1);
$ac2->add_Annotation('simple',$simple2);
$seq2->annotation($ac2);

my $ac3 = Bio::Annotation::Collection->new();
my $simple3 = Bio::Annotation::SimpleValue->new(
                                                -tagname => 'colour',
                                                -value   => 'red'
                                               );
$ac3->add_Annotation('simple',$simple3);
$seq3->annotation($ac3);


ok (Bio::SeqUtils->cat($seq1, $seq2, $seq3));
is $seq1->seq, 'aaaattttcccc';
is scalar $seq1->annotation->get_Annotations, 3;


# seq features
my $ft2 = Bio::SeqFeature::Generic->new( -start => 1,
                                         -end => 4,
                                         -strand => 1,
                                         -primary => 'source',
                                         -tag     => {note => 'note2'},
                                       );


my $ft3 = Bio::SeqFeature::Generic->new( -start => 3,
                                         -end => 3,
                                         -strand => 1,
                                         -primary => 'hotspot',
                                         -tag     => {note => ['note3a','note3b'],
                                                      comment => 'c1'},
                                       );

$seq2->add_SeqFeature($ft2);
$seq2->add_SeqFeature($ft3);


ok (Bio::SeqUtils->cat($seq1, $seq2));
is $seq1->seq, 'aaaattttcccctttt';
is scalar $seq1->annotation->get_Annotations, 5;
is_deeply([uniq_sort(map{$_->get_all_tags}$seq1->get_SeqFeatures)], [sort qw(note comment)], 'cat - has expected tags');
is_deeply([sort map{$_->get_tagset_values('note')}$seq1->get_SeqFeatures], [sort qw(note2 note3a note3b)], 'cat - has expected tag values');
my @tags;
lives_ok {
  @tags = map{$_->get_tag_values(q(note))}$seq1->get_SeqFeatures ;
} 'cat - note tag transfered (no throw)';
cmp_ok(scalar(@tags),'==',3, 'cat - note tag values transfered (correct count)') ;


my $protseq = Bio::PrimarySeq->new(-id => 2, -seq => 'MVTF'); # protein seq

throws_ok {
    Bio::SeqUtils->cat($seq1, $protseq);
} qr/different alphabets:/, 'different alphabets' ;


#
# evolve()
#

$seq = Bio::PrimarySeq->new('-seq'=> 'aaaaaaaaaa',
                            '-id'=>'test');



$util = Bio::SeqUtils->new(-verbose => 0);
ok my $newseq = $util->evolve($seq, 60, 4);

#  annotations

$seq2 = Bio::Seq->new(-id => 2, -seq => 'ggttaaaa', -description => 'second');
$ac3 = Bio::Annotation::Collection->new();
$simple3 = Bio::Annotation::SimpleValue->new(
                                                -tagname => 'colour',
                                                -value   => 'red'
                                            );
$ac3->add_Annotation('simple',$simple3);
$seq2->annotation($ac3);
$ft2 = Bio::SeqFeature::Generic->new( -start => 1,
                                      -end => 4,
                                      -strand => 1,
                                      -primary => 'source',
                                      -tag     => {note => 'note2'},
                                    );


$ft3 = Bio::SeqFeature::Generic->new( -start => 5,
                                      -end => 8,
                                      -strand => -1,
                                      -primary => 'hotspot',
                                      -tag     => {note => ['note3a','note3b'], 
                                                   comment => 'c1'},
                                    );
$seq2->add_SeqFeature($ft2);
$seq2->add_SeqFeature($ft3);

my $trunc=Bio::SeqUtils->trunc_with_features($seq2, 2, 7);
is $trunc->seq, 'gttaaa';
my @feat=$trunc->get_SeqFeatures;
is $feat[0]->location->to_FTstring, '<1..3';
is $feat[1]->location->to_FTstring, 'complement(4..>6)';
is_deeply([uniq_sort(map{$_->get_all_tags}$trunc->get_SeqFeatures)], [sort qw(note comment)], 'trunc_with_features - has expected tags');
is_deeply([sort map{$_->get_tagset_values('note')}$trunc->get_SeqFeatures], [sort qw(note2 note3a note3b)], 'trunc_with_features - has expected tag values');

my $revcom=Bio::SeqUtils->revcom_with_features($seq2);
is $revcom->seq, 'ttttaacc';
my ($rf1) = $revcom->get_SeqFeatures('hotspot');
is $rf1->primary_tag, $ft3->primary_tag, 'primary_tag matches original feature...';
is $rf1->location->to_FTstring, '1..4', 'but tagged sf is now revcom';

my ($rf2) = $revcom->get_SeqFeatures('source');
is $rf2->primary_tag, $ft2->primary_tag, 'primary_tag matches original feature...';
is $rf2->location->to_FTstring, 'complement(5..8)', 'but tagged sf is now revcom';

is_deeply([uniq_sort(map{$_->get_all_tags}$revcom->get_SeqFeatures)], [sort qw(note comment)], 'revcom_with_features - has expected tags');
is_deeply([sort map{$_->get_tagset_values('note')}$revcom->get_SeqFeatures], [sort qw(note2 note3a note3b)], 'revcom_with_features - has expected tag values');
# check circularity
isnt($revcom->is_circular, 1, 'still not circular');
$seq3 = Bio::Seq->new(-id => 3, -seq => 'ggttaaaa', -description => 'third', -is_circular => 1);
is(Bio::SeqUtils->revcom_with_features($seq3)->is_circular, 1, 'still circular');


# delete, insert and ligate
# prepare some sequence objects
my $seq_obj = Bio::Seq->new( 
  -seq =>'aaaaaaaaaaccccccccccggggggggggtttttttttt',
  -display_id => 'seq1',
  -desc       => 'some sequence for testing'
); 
my $subfeat1 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'sf1',
  -seq_id      => 'seq1',
  -start       => 2,
  -end         => 12
);

my $subfeat2 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'sf2',
  -seq_id      => 'seq1',
  -start       => 14,
  -end         => 16
);
my $subfeat3 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'sf3',
  -seq_id      => 'seq1',
  -start       => 21,
  -end         => 25
);

my $composite_feat1 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'comp_feat1',
  -seq_id      => 'seq1',
  -start       => 2,
  -end         => 30
);
my $coll_sf = Bio::Annotation::Collection->new;
$coll_sf->add_Annotation(
  'comment', Bio::Annotation::Comment->new( '-text' => 'a comment on sf1')
);
$subfeat1->annotation($coll_sf);

$composite_feat1->add_SeqFeature( $subfeat1);
$composite_feat1->add_SeqFeature( $subfeat2);
$composite_feat1->add_SeqFeature( $subfeat3);
my $feature1 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'feat1',
  -seq_id      => 'seq1',
  -start       => 2,
  -end         => 25
);
my $feature2 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'feat2',
  -seq_id      => 'seq1',
  -start       => 15,
  -end         => 25,
  -strand      => -1,
);
my $feature3 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'feat3',
  -seq_id      => 'seq1',
  -start       => 30,
  -end         => 40
);
my $feature4 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'feat4',
  -seq_id      => 'seq1',
  -start       => 1,
  -end         => 10
);
my $feature5 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'feat5',
  -seq_id      => 'seq1',
  -start       => 11,
  -end         => 20
);

for ($composite_feat1, $feature1, $feature2, $feature3, $feature4, $feature5) {
   $seq_obj->add_SeqFeature( $_ );
}

my $coll = Bio::Annotation::Collection->new;
$coll->add_Annotation(
  'comment', Bio::Annotation::Comment->new( '-text' => 'a comment on the whole sequence')
);
$seq_obj->annotation($coll);


my $fragment_obj = Bio::Seq->new( 
  -seq =>'atatatatat',
  -display_id => 'fragment1',
  -desc       => 'some fragment to insert'
); 
my $frag_feature1 = Bio::SeqFeature::Generic->new(
  -primary_tag => 'frag_feat1',
  -seq_id      => 'fragment1',
  -start       => 2,
  -end         => 4,
  -strand      => -1,
);
$fragment_obj->add_SeqFeature( $frag_feature1 );
my $frag_coll = Bio::Annotation::Collection->new;
$frag_coll->add_Annotation(
  'comment', Bio::Annotation::Comment->new( '-text' => 'a comment on the fragment')
);
$fragment_obj->annotation($frag_coll);

# delete
my $product;
lives_ok(
  sub {
    $product = Bio::SeqUtils->delete( $seq_obj, 11, 20 );
  },
  "No error thrown when deleting a segment of the sequence"
);

my ($seq_obj_comment) = $seq_obj->annotation->get_Annotations('comment');
my ($product_comment) = $product->annotation->get_Annotations('comment');
is( $seq_obj_comment, $product_comment, 'annotation of whole sequence has been moved to new molecule');

ok( 
  grep ($_ eq 'deletion of 10bp', 
    map ($_->get_tag_values('note'), 
      grep ($_->primary_tag eq 'misc_feature', $product->get_SeqFeatures)
    )
  ),
  "the product has an additional 'misc_feature' and the note specifies the lengths of the deletion'"
);

my ($composite_feat1_del) = grep ($_->primary_tag eq 'comp_feat1', $product->get_SeqFeatures);
ok ($composite_feat1_del, "The composite feature is still present");
isa_ok( $composite_feat1_del, 'Bio::SeqFeature::Generic');
isa_ok( $composite_feat1_del->location, 'Bio::Location::Split', "a composite feature that spanned the deletion site has been split up, Location");

is( $composite_feat1_del->get_SeqFeatures, 2, 'one of the sub-eatures of the composite feature has been deleted completely');
my ($subfeat1_del) = grep ($_->primary_tag eq 'sf1', $composite_feat1_del->get_SeqFeatures);
ok ($subfeat1_del, "sub-feature 1 of the composite feature is still present");
is ($subfeat1->end, 12, "the original end of sf1 is 12");
is ($subfeat1_del->end, 10, "after deletion, the end of sf1 is 1nt before the deletion site");
is ($subfeat1->location->end_pos_type, 'EXACT', 'the original end location of sf1 EXACT');

my ($subfeat1_comment) = $subfeat1->annotation->get_Annotations('comment');
my ($subfeat1_del_comment) = $subfeat1_del->annotation->get_Annotations('comment');
is( $subfeat1_comment, $subfeat1_del_comment, 'annotation of subeature 1 has been moved to new molecule');

my ($feature1_del) = grep ($_->primary_tag eq 'feat1', $product->get_SeqFeatures);
ok ($feature1_del, "feature1 is till present");
isa_ok( $feature1_del->location, 'Bio::Location::Split', 'feature1 location has now been split by the deletion and location object');
is( my @feature1_del_sublocs = $feature1_del->location->each_Location, 2, 'feature1 has two locations after the deletion');
is( $feature1_del_sublocs[0]->start, 2, 'feature1 start is unaffected by the deletion');
is( $feature1_del_sublocs[0]->end, 10, 'feature1 end of first split is 1nt before deletion site');
is( $feature1_del_sublocs[1]->start, 11, 'feature1 start of second split is 1nt after deletion site');
is( $feature1_del_sublocs[1]->end, 15, 'feature1 end of second split has been adjusted correctly');
my @fd1_notes = $feature1_del->get_tag_values('note');
is( @fd1_notes,1, 'split feature now has a note');
is (shift @fd1_notes, '10bp internal deletion between pos 10 and 11', 'got the expected note about length and position of deletion');

my ($feature3_del) = grep ($_->primary_tag eq 'feat3', $product->get_SeqFeatures);
ok ($feature3_del, "feature3 is till present");
is_deeply ( [$feature3_del->start, $feature3_del->end], [$feature3->start - 10, $feature3->end - 10], 'a feature downstream of the deletion site is shifted entirely by 10nt to the left');

my ($feature4_del) = grep ($_->primary_tag eq 'feat4', $product->get_SeqFeatures);
ok ($feature4_del, "feature4 is till present");
is_deeply ( [$feature4_del->start, $feature4_del->end], [$feature4->start, $feature4->end], 'a feature upstream of the deletion site is not repositioned by the deletion');

my ($feature2_del) = grep ($_->primary_tag eq 'feat2', $product->get_SeqFeatures);
ok ($feature2_del, "feature2 is till present");
is ( $feature2_del->start, 11, 'start pos of a feature that started in the deletion site has been altered accordingly');
my @fd2_notes = $feature2_del->get_tag_values('note');
is( @fd2_notes,1, 'feature 2 now has a note');
is (shift @fd2_notes, "6bp deleted from feature 3' end", "note added to feature2 about deletion at 3' end");

ok (!grep ($_->primary_tag eq 'feat5', $product->get_SeqFeatures), 'a feature that was completely positioned inside the deletion site is not present on the new molecule');

# insert
lives_ok(
  sub {
    $product = Bio::SeqUtils->insert( $seq_obj, $fragment_obj, 10 );
  },
  "No error thrown when inserting a fragment into recipient sequence"
);
($seq_obj_comment) = $seq_obj->annotation->get_Annotations('comment');
($product_comment) = $product->annotation->get_Annotations('comment');
is( $seq_obj_comment, $product_comment, 'annotation of whole sequence has been moved to new molecule');

my ($composite_feat1_ins) = grep ($_->primary_tag eq 'comp_feat1', $product->get_SeqFeatures);
ok ($composite_feat1_ins, "The composite feature is still present");
isa_ok( $composite_feat1_ins, 'Bio::SeqFeature::Generic');
isa_ok( $composite_feat1_ins->location, 'Bio::Location::Split', "a composite feature that spanned the insertion site has been split up, Location");
is( $composite_feat1_ins->get_SeqFeatures, 3, 'all of the parts of the composite feature are still present');

my ($subfeat1_ins) = grep ($_->primary_tag eq 'sf1', $composite_feat1_ins->get_SeqFeatures);
ok ($subfeat1_ins, "sub-feature 1 of the composite feature is still present");
is ($subfeat1->end, 12, "the original end of sf1 is 12");
is ($subfeat1_ins->end, $subfeat1->end + $fragment_obj->length, "after insertion, the end of sf1 has been shifted by the length of the insertion");
isa_ok( $subfeat1_ins->location, 'Bio::Location::Split', 'sub-feature 1 (spans insertion site) is now split up and');
is_deeply (
  [$subfeat1->location->end_pos_type, $subfeat1->location->start_pos_type],
  [$subfeat1_ins->location->end_pos_type, $subfeat1_ins->location->start_pos_type],
  'the start and end position types of sub-feature1 have not changed'
);
($subfeat1_comment) = $subfeat1->annotation->get_Annotations('comment');
my ($subfeat1_ins_comment) = $subfeat1_ins->annotation->get_Annotations('comment');
is( $subfeat1_comment, $subfeat1_ins_comment, 'annotation of subeature 1 has been moved to new molecule');
my @sf1ins_notes = $subfeat1_ins->get_tag_values('note');
is( @sf1ins_notes,1, 'split feature now has a note');
is (shift @sf1ins_notes, '10bp internal insertion between pos 10 and 21', 'got the expected note about length and position of insertion');

my ($feature3_ins) = grep ($_->primary_tag eq 'feat3', $product->get_SeqFeatures);
ok ($feature3_ins, "feature3 is till present");
is_deeply ( 
  [$feature3_ins->start, $feature3_ins->end],
  [$feature3->start + $fragment_obj->length, $feature3->end + $fragment_obj->length],
  'a feature downstream of the insertion site is shifted entirely to the left by the length of the insertion');

my ($feature4_ins) = grep ($_->primary_tag eq 'feat4', $product->get_SeqFeatures);
ok ($feature4_ins, "feature4 is till present");
is_deeply ( [$feature4_ins->start, $feature4_ins->end], [$feature4->start, $feature4->end], 'a feature upstream of the insertion site is not repositioned');

my ($frag_feature1_ins) = grep ($_->primary_tag eq 'frag_feat1', $product->get_SeqFeatures);
ok( $frag_feature1_ins, 'a feature on the inserted fragment is present on the product molecule');
is_deeply (
  [$frag_feature1_ins->start, $frag_feature1_ins->end],
  [12, 14],
  'position of the feature on the insert has been adjusted to product coordinates'
);
is( $frag_feature1_ins->strand, $frag_feature1->strand, 'strand of the feature on insert has not changed');
like( $product->desc, qr/some fragment to insert/, 'desctription of the product contains description of the fragment');
like( $product->desc, qr/some sequence for testing/, 'desctription of the product contains description of the recipient');

ok( 
  grep ($_ eq 'inserted fragment', 
    map ($_->get_tag_values('note'), 
      grep ($_->primary_tag eq 'misc_feature', $product->get_SeqFeatures)
    )
  ),
  "the product has an additional 'misc_feature' with note='inserted fragment'"
);

# ligate
lives_ok(
  sub {
    $product = Bio::SeqUtils->ligate( 
      -recipient => $seq_obj, 
      -fragment  => $fragment_obj, 
      -left      => 10, 
      -right     => 31,
      -flip      => 1
    ); 
  },
  "No error thrown using 'ligate' of fragment into recipient"
);

is ($product->length, 30, 'product has the expected length');
is ($product->subseq(11,20), 'atatatatat', 'the sequence of the fragment is inserted into the product');

my ($inserted_fragment_feature) = grep( 
  grep($_ eq 'inserted fragment', $_->get_tag_values('note')),
  grep( $_->has_tag('note'), $product->get_SeqFeatures)
);

ok($inserted_fragment_feature, 'we have a feature annotating the ligated fragment');
is_deeply ( 
  [$inserted_fragment_feature->start, $inserted_fragment_feature->end],
  [11, 20],
  'coordinates of the feature annotating the ligated feature are correct'
);

my ($fragment_feat_lig) = grep ($_->primary_tag eq 'frag_feat1', $product->get_SeqFeatures);
ok( $fragment_feat_lig, 'the fragment feature1 is now a feature of the product');
is_deeply( [$fragment_feat_lig->start, $fragment_feat_lig->end], [17,19], 'start and end of a feature on the fragment are correct after insertion with "flip" option');

# test clone_obj option (create new objects via clone not 'new')
my $foo_seq_obj = Bio::Seq::Foo->new( 
  -seq =>'aaaaaaaaaaccccccccccggggggggggtttttttttt',
  -display_id => 'seq1',
  -desc       => 'some sequence for testing'
);
for ($composite_feat1, $feature1, $feature2, $feature3, $feature4, $feature5) {
    $foo_seq_obj->add_SeqFeature( $_ );
}
$foo_seq_obj->annotation($coll);

dies_ok(
  sub {
    $product = Bio::SeqUtils->delete( $foo_seq_obj, 11, 20, { clone_obj => 0} );
  },
  "Trying to delete from an object of a custom Bio::Seq subclass that doesn't allow calling 'new' throws an error"
);

lives_ok(
  sub {
    $product = Bio::SeqUtils->delete( $foo_seq_obj, 11, 20, { clone_obj => 1} );
  },
  "Deleting from Bio::Seq::Foo does not throw an error when using the 'clone_obj' option to clone instead of calling 'new'"
);

isa_ok( $product, 'Bio::Seq::Foo');

# just repeat some of the tests for the cloned feature
ok( 
  grep ($_ eq 'deletion of 10bp', 
    map ($_->get_tag_values('note'), 
      grep ($_->primary_tag eq 'misc_feature', $product->get_SeqFeatures)
    )
  ),
  "the product has an additional 'misc_feature' and the note specifies the lengths of the deletion'"
);
($composite_feat1_del) = grep ($_->primary_tag eq 'comp_feat1', $product->get_SeqFeatures);
ok ($composite_feat1_del, "The composite feature is still present");
isa_ok( $composite_feat1_del, 'Bio::SeqFeature::Generic');
isa_ok( $composite_feat1_del->location, 'Bio::Location::Split', "a composite feature that spanned the deletion site has been split up, Location");

# ligate with clone_obj
dies_ok(
  sub {
    $product = Bio::SeqUtils->ligate( 
      -recipient => $foo_seq_obj, 
      -fragment  => $fragment_obj, 
      -left      => 10, 
      -right     => 31,
      -flip      => 1
    ); 
  },
  "'ligate' without clone_obj option dies with a Bio::Seq::Foo object that can't call new"
);

lives_ok(
  sub {
    $product = Bio::SeqUtils->ligate( 
      -recipient => $foo_seq_obj, 
      -fragment  => $fragment_obj, 
      -left      => 10, 
      -right     => 31,
      -flip      => 1,
      -clone_obj => 1,
    ); 
  },
  "'ligate' with clone_obj option works with a Bio::Seq::Foo object that can't call new"
);

sub uniq_sort {
    my @args = @_;
    my %uniq;
    @args = sort @args;
    @uniq{@args} = (0..$#args);
    return sort {$uniq{$a} <=> $uniq{$b}} keys %uniq;
}

package Bio::Seq::Foo;
use base 'Bio::Seq';
sub can_call_new { 0 }


