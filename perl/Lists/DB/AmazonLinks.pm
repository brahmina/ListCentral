package Lists::DB::AmazonLinks;
use Lists::DB::TableObject;
use base ("Lists::DB::TableObject");
use strict;


use Lists::SETUP;

##########################################################
# Lists::DB::AmazonLinks 
##########################################################

=head1 NAME

   Lists::DB::AmazonLinks.pm

=head1 SYNOPSIS

   $AmazonLinks = new Lists::DB::AmazonLinks($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the AmazonLinks table in the 
Lists database.


=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::DB::AmazonLinks::init");

   my @Fields = ("ListItemID", "ASIN", "US", "CA", "UK", "CAImage", "UKImage", "USImage", "UpdateDate", "Status", 
                  "CreateDate", "ChecksRun");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("CreateDate", "UpdateDate");
   $self->{DateFields} = \@DateFields;
}

=head2 getByASIN

Saves a new AmazonLink

=over 4

=item B<Parameters :>

   1. $self - Reference to a AmazonLinks
   2. $ASIN - The ASIN

=item B<Returns :>

   1. $AmazonLinks - Reference to a hash with the requested AmazonLink

=back

=cut

#############################################
sub getByASIN {
#############################################
   my $self = shift;
   my $ASIN = shift;

   my $AmazonLink;
   my $sql = "SELECT * FROM $Lists::SETUP::DB_NAME.AmazonLinks WHERE ASIN = \"$ASIN\"";
   my $stm = $self->{dbh}->prepare($sql);
   if ($stm->execute()) {
      while (my $hash = $stm->fetchrow_hashref()) {
         $AmazonLink = $hash;
      }
   }else{
      $self->{Debugger}->throwNotifyingError("ERROR: with $self->{Table}  SELECT: $sql - $DBI::errstr");
   }
   $stm->finish;

   return $AmazonLink;
}

1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


