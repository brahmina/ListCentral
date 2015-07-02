package ListCentral::DB::Hitlog;
use ListCentral::DB::TableObject;
use base ("ListCentral::DB::TableObject");
use strict;


use ListCentral::SETUP;

##########################################################
# ListCentral::DB::Hitlog 
##########################################################

=head1 NAME

   ListCentral::DB::Hitlog.pm

=head1 SYNOPSIS

   $Hitlog = new ListCentral::DB::Hitlog($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the Hitlog table in the 
Lists database.

=head2 init

Sets the internal field flags

=back

=cut

#############################################
sub init {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Hitlog::init");

   my @Fields = ("IP", "Date", "URI", "Referer", "UserID", "UserAgent");
   $self->{Fields} = \@Fields;

   my @HTMLFields = ();
   $self->{HTMLFields} = \@HTMLFields;

   my @DateFields = ("Date");
   $self->{DateFields} = \@DateFields;
}

=head2 storeHitlogEntry

Stores and entry in the HitLog table

=over 4

=item B<Parameters :>

   1. $self - Reference to a Hitlog object
   2. $ip - the IP address of the hitter
   3. $page - the page hit

=item B<Prints :>

   1. $success - The 1 if successful, 0 otherwise

=back

=cut

#############################################
sub storeHitlogEntry {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::DB::Hitlog::store_hitlog_entry");

   my $success = 0;

   my $ip = $ENV{REMOTE_ADDR};
   my $uri = $ENV{REQUEST_URI};
   my $referrer = $ENV{HTTP_REFERER};
   my $UserAgent = $ENV{HTTP_USER_AGENT};

   if($ENV{REMOTE_ADDR} eq $ListCentral::SETUP::CONSTANTS{'MONITORING'}){
      # Don't record the monitoring service
      return;
   }

   if($ip ne $BrahminaBurgess::ListCentral::SETUP::MY_IP){
      my $time = time();
      my $sql_hitlog = "INSERT INTO $ListCentral::SETUP::DB_NAME.Hitlog (IP, Date, URI, Referer, UserID, UserAgent) 
                                   VALUES (?,?,?,?,?,?)";
   
      my $stm = $self->{dbh}->prepare($sql_hitlog);
      if ($stm->execute(
                        $ip,
                        $time,
                        $uri,
                        $referrer,
                        $UserID,
                        $UserAgent
                        )){
   
         $success = $stm->{mysql_insertid};
      }else{
         $self->{Debugger}->throwNotifyingError("ERROR: with Hitlog DB insert::: $sql_hitlog $!");
         $success = 0;
      }
      $stm->finish();
   }

   return $success;
}



1;

=head1 AUTHOR INFORMATION

   Author:  with help from the ApplicationFramework
   Created: 12/3/2008

=head1 BUGS

   Not known

=cut


