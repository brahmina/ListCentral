package ListCentral::DB::Messages;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Messages 
##########################################################

=head1 NAME

   ListCentral::DB::Messages.pm

=head1 SYNOPSIS

   $Messages = new ListCentral::DB::Messages($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Messages table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Messages::init");

   my @Fields = ("UserID", "CreateDate", "Action", "DoerID", "Seen", "Status", "SubjectID");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getUsersSpace

Marks all of the Messages for the user corresponding to the UserID passed to seen

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::Messages object

=back

=cut

#####################################
sub setAsSeen {
#####################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Message->setAsSeen");

   my $sql = "UPDATE $ListCentral::SETUP::DB_NAME.Messages SET Seen = 1 where UserID = $UserID";
   my $stm = $self->{dbh}->prepare($sql);
   if ($self->{dbh}->do($sql)) {
      # Good Stuff
   }else {
      $self->{Debugger}->throwNotifyingError("ERROR: setAsSeen UPDATE::: $sql\n");
   }
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


