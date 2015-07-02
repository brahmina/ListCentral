package ListCentral::Utilities::Amazon;
use strict;

use ListCentral::SETUP;
use ListCentral::Utilities::StringFormatter;

use Net::OpenID::Consumer;

##########################################################
# ListCentral::Amazon 
##########################################################

=head1 NAME

   ListCentral::Utilities::Amazon.pm

=head1 SYNOPSIS

   $Amazon = new ListCentral::Utilities::Amazon(Debugger, OpenIDUserID);

=head1 DESCRIPTION

Used to communicate with Amazon and build affiliate links

=head2 ListCentral::Utilities::Amazon Constructor

=over 4

=item B<Parameters :>

   1. $Debugger

=back

=cut

########################################################
sub new {
########################################################
   my $classname=shift; 
   my $self; 
   %$self=@_; 
   bless $self,ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID constructor");

   $self->{OpenIDUserD} = $self->{DBManager}->getTableObj("OpenIDUserID");
   
   return ($self); 
}

=head2 getUserID

Gets the UserID associated with the OpenID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $OpenID - Reference to a hash with complete OpenID data

=item B<Prints :>

   1. $UserID - the UserID corresponding to the OpenID passed

=back

=cut

#############################################
sub getUserID {
#############################################
   my $self = shift;
   my $OpenID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::getUserID with $OpenID");

   my $OpenID = ListCentral::Utilities::StringFormatter::canonicalizeURL($OpenID);
   my $OpenIDHash = $self->{OpenIDUseID}->get_by_field("OpenID = \"$OpenID\"");

   return $OpenID->{UserID};
}

=head2 getOpenIDsByUser

Gets the UserID associated with the OpenID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $OpenID - Reference to a hash with complete OpenID data

=item B<Prints :>

   1. $UserID - the UserID corresponding to the OpenID passed

=back

=cut

#############################################
sub getOpenIDsByUser {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::getOpenIDsByUser with: $UserID");

   my $OpenIDUserID = $self->{OpenIDUserID}->get_by_field("OpenID = \"$OpenID\"");

   return $OpenIDUserID->{OpenID};
}

=head2 attachOpenID

Given and OpenID and a UserID, creates the association

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $OpenID - Reference to a hash with complete OpenID data

=back

=cut

#############################################
sub attachOpenID {
#############################################
   my $self = shift;
   my $OpenID = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::attachOpenID with $OpenID, $UserID");

   my $OpenID = ListCentral::Utilities::StringFormatter::canonicalizeURL($OpenID);

   if($OpenID && $UserID){
      my %OpenIDUserID = ("OpenIDUserID.OpenID" => $OpenID,
                          "OpenIDUserID.UserID" => $UserID
                          );
      my $success = $self->{OpenIDUserID}->store(\%OpenIDUserID);
   }else{
      $self->{Debugger}->throwNotifyingError("Error Storing OpenID Pairing", "One is null: OpenID: $OpenID, UserID: $UserID");
   }

}

=head2 detachOpenID

Deletes (sets status to 0) the UserID association for the OpenID passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $OpenID - Reference to a hash with complete OpenID data

=back

=cut

#############################################
sub detachOpenID {
#############################################
   my $self = shift;
   my $OpenID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::detachOpenID with $OpenID");

   my $OpenID = ListCentral::Utilities::StringFormatter::canonicalizeURL($OpenID);

   my $OpenIDUserID = $self->{OpenIDUserID}->get_by_field("OpenID", $OpenID);

   my $UserID = $self->{OpenIDUserID}->update("Status", 0, $OpenIDUserID->{ID});

}

=head2 detachOpenIDsByUser

Deletes (sets status to 0) the OpenIDs associated with the UserID Passed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $UserID - Reference to a hash with complete OpenID data

=back

=cut

#############################################
sub detachOpenIDsByUser {
#############################################
   my $self = shift;
   my $UserID = shift;
 
   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::detachOpenIDByUser with $UserID");
   $self->{OpenIDUserID}->deleteUsersOpenIDs($UserID);

}

=head2 authenticateOpenID

Handles the authentication process of OpenID

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::DB::OpenID object
   2. $OpenID - The Open ID to be authenticated

=back

=cut

#############################################
sub authenticateOpenID {
#############################################
   my $self = shift;
   my $penID = shift;

   $self->{Debugger}->debug("in ListCentral::Utilities::OpenID::authenticateOpenID");

   my $csr = Net::OpenID::Consumer->new(
                                          ua    => LWPx::ParanoidAgent->new,
                                          cache => Some::Cache->new,
                                          args  => $cgi,
                                          consumer_secret => ...,
                                          required_root => "http://site.example.com/",
   );
   
   # a user entered, say, "bradfitz.com" as their identity.  The first
   # step is to fetch that page, parse it, and get a
   # Net::OpenID::ClaimedIdentity object:
   my $claimed_identity = $csr->claimed_identity("bradfitz.com");
   
   # now your app has to send them at their identity server's endpoint
   # to get redirected to either a positive assertion that they own
   # that identity, or where they need to go to login/setup trust/etc.
   my $check_url = $claimed_identity->check_url(
                                                return_to  => "$ListCentral::SETUP::URL/openIDAuth.html?arg=",
                                                trust_root => "$ListCentral::SETUP::URL/",
   );
   
   # so you send the user off there, and then they come back to
   # openid-check.app, then you see what the identity server said;
   if (my $setup_url = $csr->user_setup_url) {
      # redirect/link/popup user to $setup_url
   }elsif ($csr->user_cancel) {
      # restore web app state to prior to check_url
   }elsif (my $vident = $csr->verified_identity) {
      my $verified_url = $vident->url;
      print "You are $verified_url !";
   }else {
      die "Error validating identity: " . $csr->err;
   }

}

1;

=head1 AUTHOR INFORMATION

   Author:  With help from the ApplicationFramework
   Last Updated: 22/10/2007

=head1 BUGS

   Not known

=cut
