# BioPerl module for Bio::Tools::AmpliconSearch
#
# Copyright Florent Angly
#
# You may distribute this module under the same terms as perl itself


package Bio::Tools::AmpliconSearch;

use strict;
use warnings;
use Bio::Tools::IUPAC;
use Bio::SeqFeature::Amplicon;
use Bio::Tools::SeqPattern;
# we require Bio::SeqIO
# and Bio::SeqFeature::Primer

use base qw(Bio::Root::Root);

my $template_str;


=head1 NAME

Bio::Tools::AmpliconSearch - Find amplicons in a template using degenerate PCR primers

=head1 SYNOPSIS

   use Bio::PrimarySeq;
   use Bio::Tools::AmpliconSearch;

   my $template = Bio::PrimarySeq->new(
      -seq => 'aaaaaCCCCaaaaaaaaaaTTTTTTaaaaaCCACaaaaaTTTTTTaaaaaaaaaa',
   );
   my $fwd_primer = Bio::PrimarySeq->new(
      -seq => 'CCNC',
   );
   my $rev_primer = Bio::PrimarySeq->new(
      -seq => 'AAAAA',
   );

   my $search = Bio::Tools::AmpliconSearch->new(
      -template   => $template,
      -fwd_primer => $fwd_primer,
      -rev_primer => $rev_primer,
   );
   
   while (my $amplicon = $search->next_amplicon) {
      print "Found amplicon at position ".$amplicon->start.'..'.$amplicon->end.":\n";
      print $amplicon->seq->seq."\n\n";
   }

=head1 DESCRIPTION

Perform an in silico PCR reaction, i.e. search for amplicons in a given template
sequence using the specified degenerate primer.

The template sequence is a sequence object, e.g. L<Bio::Seq>, and the primers
can be a sequence or a L<Bio::SeqFeature::Primer> object and contain ambiguous
residues as defined in the IUPAC conventions. The primer sequences are converted
into regular expressions using L<Bio::Tools::IUPAC> and the matching regions of
the template sequence, i.e. the amplicons, are returned as L<Bio::Seq::PrimedSeq>
objects.

AmpliconSearch will look for amplicons on both strands (forward and reverse-
complement) of the specified template sequence. If the reverse primer is not
provided, an amplicon will be returned and span a match of the forward primer to
the end of the template. Similarly, when no forward primer is given, match from
the beginning of the template sequence. When several amplicons overlap, only the
shortest one to more accurately represent the biases of PCR. Future improvements
may include modelling the effects of the number of PCR cycles or temperature on
the PCR products.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Support

Please direct usage questions or support issues to the mailing list:

I<bioperl-l@bioperl.org>

rather than to the module maintainer directly. Many experienced and
reponsive experts will be able look at the problem and quickly
address it. Please include a thorough description of the problem
with code and data examples if at all possible.

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  https://redmine.open-bio.org/projects/bioperl/

=head1 AUTHOR

Florent Angly <florent.angly@gmail.com>

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=head2 new

 Title    : new
 Usage    : my $search = Bio::Tools::AmpliconSearch->new( );
 Function : Initialize an amplicon search
 Args     : -template       Sequence object for the template sequence. This object
                            will be converted to Bio::Seq if needed in since features
                            (amplicons and primers) will be added to this object.
            -fwd_primer     A sequence object representing the forward primer
            -rev_primer     A sequence object representing the reverse primer
            -primer_file    Read primers from a sequence file. It replaces
                            -fwd_primer and -rev_primer (optional)
            -attach_primers Whether or not to attach primers to Amplicon objects. Default: 0 (off)
 Returns  : A Bio::Tools::AmpliconSearch object

=cut

sub new {
   my ($class, @args) = @_;
   my $self = $class->SUPER::new(@args);
   my ($template, $primer_file, $fwd_primer, $rev_primer, $attach_primers) =
      $self->_rearrange([qw(TEMPLATE PRIMER_FILE FWD_PRIMER REV_PRIMER ATTACH_PRIMERS)],
      @args);

   # Get primers
   if (defined $primer_file) {
      ($fwd_primer, $rev_primer) = $self->_get_primers_from_file($primer_file);
   }
   $self->_set_fwd_primer($fwd_primer);
   $self->_set_rev_primer($rev_primer);

   # Get template sequence
   $self->_set_template($template) if defined $template;
   if ( $template && not($fwd_primer) && not($rev_primer) ) {
      $self->throw('Need to provide at least a primer');
   }

   $self->_set_attach_primers($attach_primers) if defined $attach_primers;

   return $self;
}


=head2 template

 Title    : template
 Usage    : my $template = $search->template;
 Function : Get the template sequence
 Args     : None
 Returns  : A Bio::Seq object

=cut

sub template {
   my ($self) = @_;
   return $self->{template};
}

sub _set_template {
   my ($self, $template) = @_;
   if ( not(ref $template) || not $template->isa('Bio::PrimarySeqI')) {
      # Not a Bio::Seq or Bio::PrimarySeq
      $self->throw("Expected a sequence object as input but got a '".ref($template)."'\n");
   }
   if (not $template->isa('Bio::SeqI')) {
      # Convert sequence object to Bio::Seq Seq so that features can be added
      my $primary_seq = $template;
      $template = Bio::Seq->new();
      $template->primary_seq($primary_seq);
   }
   $self->{template} = $template;
   $template_str = $self->template->seq;
   return $self->template;
}


=head2 fwd_primer

 Title    : fwd_primer
 Usage    : my $primer = $search->fwd_primer;
 Function : Get the forward primer.
 Args     : None
 Returns  : A sequence object or primer object or undef

=cut

sub fwd_primer {
   my ($self) = @_;
   return $self->{fwd_primer};
}

sub _set_fwd_primer {
   my ($self, $primer) = @_;
   return $self->_set_primer('fwd', $primer);
}


=head2 rev_primer

 Title    : rev_primer
 Usage    : my $primer = $search->rev_primer;
 Function : Get the reverse primer.
 Args     : None
 Returns  : A sequence object or primer object or undef

=cut

sub rev_primer {
   my ($self) = @_;
   return $self->{rev_primer};
}

sub _set_rev_primer {
   my ($self, $primer) = @_;
   return $self->_set_primer('rev', $primer);
}

sub _set_primer {
   # Save a primer (sequence object) and convert it to regexp. Type is 'fwd' or 'rev'.
   my ($self, $type, $primer) = @_;
   my $re;
   if (defined $primer) {
      if ( not(ref $primer) || (
           not($primer->isa('Bio::PrimarySeqI')) &&
           not($primer->isa('Bio::SeqFeature::Primer')) ) ) {
         $self->throw('Expected a sequence or primer object as input but got a '.ref($primer)."\n");
      }
      $self->{$type.'_primer'} = $primer;
      my $seq = $primer->isa('Bio::SeqFeature::Primer') ? $primer->seq : $primer;
      $re = Bio::Tools::IUPAC->new(
         -seq => $type eq 'fwd' ? $seq : $seq->revcom,
      )->regexp;
   } else {
      $re = $type eq 'fwd' ? '^' : '$';
   }
   $self->{$type.'_regexp'} = $re;
   return $self->{$type.'_primer'};
}

sub _get_primers_from_file {
   my ($self, $primer_file) = @_;
   # Read primer file and convert primers into regular expressions to catch
   # amplicons present in the database

   if (not defined $primer_file) {
      $self->throw("Need to provide an input file\n");
   }

   # Mandatory first primer
   require Bio::SeqIO;
   my $in = Bio::SeqIO->newFh( -file => $primer_file );
   my $fwd_primer = <$in>;
   if (not defined $fwd_primer) {
      $self->throw("The file '$primer_file' contains no primers\n");
   }
   $fwd_primer->alphabet('dna'); # Force the alphabet since degenerate primers can look like protein sequences

   # Optional reverse primers
   my $rev_primer = <$in>;
   if (defined $rev_primer) {
      $rev_primer->alphabet('dna');
   }
   
   #### $in->close;
   #### close $in;
   undef $in;

   return ($fwd_primer, $rev_primer);
}


=head2 attach_primers

 Title    : attach_primers
 Usage    : my $attached = $search->attach_primers;
 Function : Get whether or not primer objects will be attached to the amplicon
            objects.
 Args     : None
 Returns  : Integer (1 for yes, 0 for no)

=cut

sub attach_primers {
   my ($self) = @_;
   return $self->{attach_primers} || 0;
}

sub _set_attach_primers {
   my ($self, $val) = @_;
   $self->{attach_primers} = $val;
   require Bio::SeqFeature::Primer;
   return $self->attach_primers;
}


=head2 next_amplicon

 Title    : next_amplicon
 Usage    : my $amplicon = $search->next_amplicon;
 Function : Get the next amplicon
 Args     : None
 Returns  : A Bio::SeqFeature::Amplicon object

=cut

sub next_amplicon {
   my ($self) = @_;
   my $amplicon;

   my $re = $self->_regexp;

   if ($template_str  =~ m/$re/g) {
      my ($match, $rev_match) = ($1, $2);
      my $strand = $rev_match ? -1 : 1;
      $match = $match || $rev_match;
      my $end   = pos($template_str);
      my $start = $end - length($match) + 1;
      $amplicon = $self->_attach_amplicon($start, $end, $strand);
   }

   # If no more matches. Make sure calls to next_amplicon() will return undef.
   if (not $amplicon) {
      $template_str = '';
   }

   return $amplicon;
}


sub _regexp {
   my ($self) = @_;
   if (not defined $self->{regexp}) {
      # Build regexp that matches amplicons on both strands and reports shortest
      # amplicon when there are several overlapping amplicons

      my $fwd_regexp = $self->_fwd_regexp;
      my $rev_regexp = $self->_rev_regexp;

      my ($fwd_regexp_rc, $basic_fwd_match, $rev_regexp_rc, $basic_rev_match);
      if ($fwd_regexp eq '^') {
         $fwd_regexp_rc = '';
         $basic_fwd_match = "(?:.*?$rev_regexp)";
      } else {
         $fwd_regexp_rc = Bio::Tools::SeqPattern->new( -seq => $fwd_regexp, -type => 'dna' )->revcom->str;
         $basic_fwd_match = "(?:$fwd_regexp.*?$rev_regexp)";
      }

      if ($rev_regexp eq '$') {
         $rev_regexp_rc = '';
         $basic_rev_match = "(?:.*?$fwd_regexp_rc)";
      } else {
         $rev_regexp_rc = Bio::Tools::SeqPattern->new( -seq => $rev_regexp, -type => 'dna' )->revcom->str;
         $basic_rev_match = "(?:$rev_regexp_rc.*?$fwd_regexp_rc)";
      }

      my $fwd_exclude     = "(?!$basic_rev_match".
                            ($fwd_regexp eq '^' ? '' : "|$fwd_regexp").
                            ")";

      my $rev_exclude     = "(?!$basic_fwd_match".
                            ($rev_regexp eq '$' ? '' : "|$rev_regexp_rc").
                            ')';

      $self->{regexp} = qr/($fwd_regexp(?:$fwd_exclude.)*?$rev_regexp)|($rev_regexp_rc(?:$rev_exclude.)*?$fwd_regexp_rc)/i;

   }
   return $self->{regexp};
}


=head2 annotate_template

 Title    : annotate_template
 Usage    : my $template = $search->annotate_template;
 Function : Search for all amplicons and attach them to the template.
            This is equivalent to running:
               while (my $amplicon = $self->next_amplicon) {
                  # do something
               }
               my $annotated = $self->template;
 Args     : None
 Returns  : A Bio::Seq object with attached Bio::SeqFeature::Amplicons (and
            Bio::SeqFeature::Primers if you set -attach_primers to 1).

=cut

sub annotate_template {
   my ($self) = @_;
   # Search all amplicons and attach them to template
   1 while $self->next_amplicon;
   # Return annotated template
   return $self->template;
}


sub _fwd_regexp {
   my ($self) = @_;
   return $self->{fwd_regexp};
}


sub _rev_regexp {
   my ($self) = @_;
   return $self->{rev_regexp};
}


sub _attach_amplicon {
   # Create an amplicon object and attach it to template
   my ($self, $start, $end, $strand) = @_;

   # Create Bio::SeqFeature::Amplicon feature and attach it to the template
   my $amplicon = Bio::SeqFeature::Amplicon->new(
      -start    => $start,
      -end      => $end,
      -strand   => $strand,
      -template => $self->template,
   );

   # Create Bio::SeqFeature::Primer feature and attach them to the amplicon
   if ($self->attach_primers) {
      for my $type ('fwd', 'rev') {
         my ($pstart, $pend, $pstrand, $primer_seq);

         # Coordinates relative to amplicon
         if ($type eq 'fwd') {
            # Forward primer
            $primer_seq = $self->fwd_primer;
            next if not defined $primer_seq;
            $pstart  = 1;
            $pend    = $primer_seq->length;
            $pstrand = $amplicon->strand;
         } else {
            # Optional reverse primer
            $primer_seq = $self->rev_primer;
            next if not defined $primer_seq;
            $pstart  = $end - $primer_seq->length + 1;
            $pend    = $end;
            $pstrand = -1 * $amplicon->strand;
         }

         # Absolute coordinates needed
         $pstart += $start - 1;
         $pend   += $start - 1;

         my $primer = Bio::SeqFeature::Primer->new(
            -start    => $pstart,
            -end      => $pend,
            -strand   => $pstrand,
            -template => $amplicon,
         );

         # Attach primer to amplicon
         if ($type eq 'fwd') {
            $amplicon->fwd_primer($primer);
         } else {
            $amplicon->rev_primer($primer);
         }

      }
   }

   return $amplicon;
}


1;
