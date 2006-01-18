# $Id$
#
# BioPerl module for Bio::DB::SeqVersion
#
# Cared for by Brian Osborne
#
# Copyright Brian Osborne 2006
#
# You may distribute this module under the same terms as Perl itself
#
# POD documentation - main docs before the code

=head1 NAME

Bio::DB::SeqVersion - front end to querying databases for identifier 
versions

=head1 SYNOPSIS

  use Bio::DB::SeqVersion;
 
  my $query = Bio::DB::SeqVersion->new(-type => 'gi');

  my @all_gis = $query->get_all(2);

  my $live_gi = $query->get_recent(2);

=head1 DESCRIPTION

The default type is 'gi'.

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org             - General discussion
  http://bioperl.org/MailList.shtml  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via
the web:

  http://bugzilla.bioperl.org/

=head1 AUTHOR - Brian Osborne

Email osborne1@optonline.net

=head1 CONTRIBUTORS

Additional contributors names and emails here

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a _

=cut

# Let the code begin...

package Bio::DB::SeqVersion;
use strict;
use vars qw(@ISA $MODVERSION $DEFAULTIDTYPE);
use Bio::Root::HTTPget;
use Bio::Root::Root;
use Bio::Root::Version;
# use Bio::DB::WebAgent;

$DEFAULTIDTYPE = 'gi';
$MODVERSION = $Bio::Root::Version::VERSION;

@ISA = qw(Bio::Root::HTTPget Bio::Root::Root);

=head2 new()

 Usage   : my $obj = new Bio::DB::SeqVersion();
 Function: Create a Bio::DB::SeqVersion object 
 Returns : An instance of Bio::DB::SeqVersion
 Args    : -type      Identifier namespace, default is 'gi' 
                      
=cut

sub new {
  my($class,@args) = @_;

  if( $class =~ /Bio::DB::SeqVersion::(\S+)/ ) {
    my ($self) = $class->SUPER::new(@args);
    $self->_initialize(@args);
    return $self;
  } else {
    my %param = @args;
    @param{ map { lc $_ } keys %param } = values %param; # lowercase keys
    my $type = $param{'-type'} || $DEFAULTIDTYPE;

    $type = "\L$type";	# normalize capitalization to lower case

    return undef unless( $class->_load_seqversion_module($type) );
    return "Bio::DB::SeqVersion::$type"->new(@args);
  }
}

=head2 get_recent()

 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub get_recent {
  my ($self,@args) = @_;
  $self->throw_not_implemented();
}

=head2 get_all()

 Usage   :
 Function:
 Example :
 Returns : 
 Args    :

=cut

sub get_all {
	my ($self,@args) = @_;
	$self->throw_not_implemented();
}

=head2 _load_seqversion_module

 Title   : _load_seqversion_module
 Usage   : Used internally
 Function: Loads up a module at run time on demand
 Example :
 Returns :
 Args    : Name of identifier type

=cut

sub _load_seqversion_module {
	my ($self,$db) = @_;
	my $module = "Bio::DB::SeqVersion::" . $db;
	my $ok;

	eval { $ok = $self->_load_module($module) };
	if ( $@ ) {
		print STDERR $@;
		print STDERR <<END;
$self: $module cannot be found
Exception $@
For more information about the Bio::DB::SeqVersion system please see
the Bio::DB::SeqVersion docs.
END
		;
	}
	return $ok;
}

=head2 default_id_type

 Title   : default_id_type
 Usage   : my $type = $self->default_id_type
 Function: Returns default identifier type for this module
 Returns : string
 Args    : none

=cut

sub default_id_type {
    return $DEFAULTIDTYPE;
}

1;