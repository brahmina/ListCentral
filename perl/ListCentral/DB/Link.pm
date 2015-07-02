package ListCentral::DB::Link;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Link 
##########################################################

=head1 NAME

   ListCentral::DB::Link.pm

=head1 SYNOPSIS

   $Link = new ListCentral::DB::Link($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Link table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::AdImpressions::init");

   my @Fields = ("CreateDate", "Status", "Link");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 SaveLink

Adds a new feedback entry from a user's use of the list central contact form

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub saveLink {
#############################################
   my $self = shift;
   my $link = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Link->saveLink with $link");

   # Lets see if that link is in the db already... no use duplicating
   my $Links = $self->get_with_restraints("Link = \"$link\"");

   my $LinkID;
   foreach my $ID (keys %{$Links}) {
      $LinkID = $ID;
   }
   if(! $LinkID){
      # It's not in there, lets store it
      my %Link;
      $Link{"Link.Status"} = 1;
      $Link{"Link.Link"} = $link;
      $LinkID = $self->store(\%Link);
   }

   return $LinkID;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 21/1/2008

=head1 BUGS

   Not known

=cut


