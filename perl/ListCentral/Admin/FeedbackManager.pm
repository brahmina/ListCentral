package ListCentral::Admin::FeedbackManager;
use strict;

use ListCentral::SETUP;

use ListCentral::Utilities::Date;
use ListCentral::Utilities::Search;

##########################################################
# ListCentral::Admin::FeedbackManager 
##########################################################

=head1 NAME

   ListCentral::Admin::FeedbackManager.pm

=head1 SYNOPSIS

   $ListManager = new ListCentral::Admin::FeedbackManager($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 ListCentral::List Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   3. $debug

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager constructor");

   if(!$self->{DBManager}){
      die $self->{Debugger}->log("Where is ListManager's DBManager??");
   }
   if(!$self->{cgi}){
      die $self->{Debugger}->log("Where is ListManager's cgi??");
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }

   $self->{AdminUserObj} = $self->{DBManager}->getTableObj("AdminUser"); 

   return ($self); 
}


=head2 getFeedbackElement

The main function for utilizing the ThemeManager

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object

=item B<Prints :>

   1. $content - The content requested

=back

=cut

#############################################
sub getFeedbackElement {
#############################################
   my $self = shift;
   my $element = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackElement with $element");

   my $content = "";
   if($element =~ m/UserFeedbackRequests/){
      $content = $self->getFeedbackRequestsByUserHTML($self->{cgi}->{UserID});
   }elsif($element =~ m/FeedbackRequests_(\d+)/){
      my $FeedbackStatusID = $1;
      $content = $self->getFeedbackRequestsHTML($FeedbackStatusID);
   }elsif($element =~ m/FeedbackRequest/){
      $content = $self->getFeedbackRequestsHTML(0,0,$self->{cgi}->{FeedbackID});
   }elsif($element =~ m/FeedbackReplies/){
      $content = $self->getFeedbackReplies($self->{cgi}->{FeedbackID});
   }

   return $content;
}

=head2 getFeedbackRequestsHTML

Gets all of the Feedback Requests by the given user and returns HTML

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object
   2. $UserID - The user to get the Feedback for
   3. $FeedbackStatusID - Corresponds to 

=item B<Prints :>

   1. $FeedbackRequests - The content requested

=back

=cut

#############################################
sub getFeedbackRequestsHTML {
#############################################
   my $self = shift;
   my $FeedbackStatusID = shift;
   my $UserID = shift;
   my $FeedbackID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackRequestsHTML");

   my $html = $self->getFeedbackRequestsRows($FeedbackStatusID, $UserID, $FeedbackID);

   my $template = "$ListCentral::SETUP::ADMIN_DIR_PATH/reports/FeedbackReport.html";
   open(PAGE, $template) || $self->{Debugger}->log("cannot open file: $template - $!");
   my @lines = <PAGE>;
   close PAGE;

   my $content = "";
   foreach my $line (@lines) {
      if($line =~ m/<!--FeedbackReportRows-->/){
         $line =~ s/<!--FeedbackReportRows-->/$html/;
      }
      $content .= $line;
   }

   return $content;
}

=head2 getFeedbackRequestsByUserHTML

Gets all of the Feedback Requests by the given user and returns HTML

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object
   2. $UserID - The user to get the Feedback for
   3. $FeedbackStatusID - Corresponds to 

=item B<Prints :>

   1. $FeedbackRequests - The content requested

=back

=cut

#############################################
sub getFeedbackRequestsByUserHTML {
#############################################
   my $self = shift;
   my $UserID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackRequestsHTML");

   my $FeedbackStatusObj = $self->{DBManager}->getTableObj("FeedbackStatus");
   my $FeedbackStatuses = $FeedbackStatusObj->get_all();

   my $html = "";
   foreach my $FeedbackStatusID (sort keys %{$FeedbackStatuses}) {
      if($FeedbackStatuses->{$FeedbackStatusID}->{Name} ne "Deleted"){
         my $rows = $self->getFeedbackRequestsRows($FeedbackStatusID, $UserID); 
         $html .= "<tr><td colspan='9' class='StatsTableHeader'>$FeedbackStatuses->{$FeedbackStatusID}->{Name}</td><tr>" . $rows;
      }
   }

   my $template = "$ListCentral::SETUP::ADMIN_DIR_PATH/reports/FeedbackReport.html";
   open(PAGE, $template) || $self->{Debugger}->log("cannot open file: $template - $!");
   my @lines = <PAGE>;
   close PAGE;

   my $content = "";
   foreach my $line (@lines) {
      if($line =~ m/<!--FeedbackReportRows-->/){
         $line =~ s/<!--FeedbackReportRows-->/$html/;
      }
      $content .= $line;
   }

   return $content;
}

=head2 getFeedbackRequestsRows

Gets all of the Feedback Requests rows for the given feedback status id, userid or feedback id

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object
   2. $UserID - The user to get the Feedback for
   3. $FeedbackStatusID - 1, 2, 3, (New, Pending, Complete)
   4. $FeedbackID - If present, trumps above parameters, and function returns one row

=item B<Prints :>

   1. $FeedbackRequests - The content requested

=back

=cut

#############################################
sub getFeedbackRequestsRows {
#############################################
   my $self = shift;
   my $FeedbackStatusID = shift;
   my $UserID = shift;
   my $FeedbackID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackRequestsRows");

   my $FeedbackRequests = $self->getFeedbackRequests($FeedbackStatusID, $UserID, $FeedbackID);

   my $FeedbackStatusObj = $self->{DBManager}->getTableObj("FeedbackStatus");
   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $FeedbackReplyObj = $self->{DBManager}->getTableObj("FeedbackReply");

   my $html = "";
   foreach my $ID (sort{$FeedbackRequests->{$a}->{CreateDate} <=> $FeedbackRequests->{$b}->{CreateDate}} keys %{$FeedbackRequests}) {
      my $ProblematicUser = "";
      if($FeedbackRequests->{$ID}->{ProblematicUserID}){
         $ProblematicUser = $UserObj->get_field_by_ID("Username", $FeedbackRequests->{$ID}->{ProblematicUserID});
         $ProblematicUser = qq~<a href="/user.html?UserID=$FeedbackRequests->{$ID}->{ProblematicUserID}">$ProblematicUser</a>~;
      }
      $self->{Debugger}->debug("ProblematicListID: $FeedbackRequests->{$ID}->{ProblematicListID}");

      my $ProblematicList = "";
      if($FeedbackRequests->{$ID}->{ProblematicListID}){

         my $ProblematicListHash = $ListObj->get_by_ID($FeedbackRequests->{$ID}->{ProblematicListID});
         my $ListURL = $ListObj->getListURL($ProblematicListHash);
         $ProblematicList = qq~<a href="$ListCentral::SETUP::URL/$ListURL">$ProblematicListHash->{Name}</a>~;
      }   
      my $FeedbackStatus = $FeedbackStatusObj->get_field_by_ID("Name", $FeedbackRequests->{$ID}->{FeedbackStatusID});
      my $FeedbackReplies = $FeedbackReplyObj->get_count_with_restraints("FeedbackID = $ID");

      if($FeedbackRequests->{$ID}->{User} ne "guest"){
         $FeedbackRequests->{$ID}->{User} = qq~<a href="/user.html?UserID=$FeedbackRequests->{$ID}->{ReportingUserID}">$FeedbackRequests->{$ID}->{User}</a>~;
      }

      # Feedback Status instead
      $html .= qq~<tr><td class="StatsTableData"><a href="/feedback.html?FeedbackID=$ID">$ID - Reply</a></td>
                   <td class="StatsTableData">$FeedbackRequests->{$ID}->{User}</td>
                   <td class="StatsTableData">$FeedbackRequests->{$ID}->{FeedbackType}</td>
                   <td class="StatsTableData">$FeedbackRequests->{$ID}->{CreateDateFormatted}</td>
                   <td class="StatsTableData">$FeedbackRequests->{$ID}->{Message}</td>
                   <td class="StatsTableData">$FeedbackReplies</td>
                   <td class="StatsTableData">$FeedbackRequests->{$ID}->{Email}</td>
                   <td class="StatsTableData">User: $ProblematicUser<br /> 
                                              List: $ProblematicList</td>
                   <td class="StatsTableData">$FeedbackStatus</td></tr>
               ~;

   }

   return $html;
}

=head2 getFeedbackRequests

Gets all of the Feedback Requests by the given user

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object
   2. $UserID - The user to get the Feedback for
   3. $FeedbackStatusID - Corresponds to 
   4. $feedbackID - A Feedback ID - if present the other two don't matter

=item B<Prints :>

   1. $FeedbackRequests - The content requested

=back

=cut

#############################################
sub getFeedbackRequests {
#############################################
   my $self = shift;
   my $FeedbackStatusID = shift;
   my $UserID = shift;
   my $FeedbackID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackRequests with FeedbackStatusID: $FeedbackStatusID, UserID: $UserID, FeedbackID: $FeedbackID");

   my $UserClause = "";
   if($UserID){
      $UserClause = "AND ReportingUserID = $UserID";
   }

   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");

   my $FeedbackRequests;
   if($FeedbackID){
      $FeedbackRequests->{$FeedbackID} = $FeedbackObj->get_by_ID($FeedbackID);
   }else{
      $FeedbackRequests = $FeedbackObj->get_with_restraints("FeedbackStatusID = $FeedbackStatusID $UserClause");
   }   

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $FeedbackTypeObj = $self->{DBManager}->getTableObj("FeedbackType");
   my $FeedbackTypes = $FeedbackTypeObj->get_all_for_admin();

   foreach my $ID(keys %{$FeedbackRequests}) {
      $FeedbackRequests->{$ID}->{FeedbackType} = $FeedbackTypes->{$FeedbackRequests->{$ID}->{FeedbackTypeID}}->{Name};
      if($FeedbackRequests->{$ID}->{ReportingUserID}){
	 $FeedbackRequests->{$ID}->{User} = $UserObj->get_field_by_ID("Username", $FeedbackRequests->{$ID}->{ReportingUserID});
      }else{
	 $FeedbackRequests->{$ID}->{User} = "guest";
      }
      $FeedbackRequests->{$ID}->{CreateDateFormatted} = ListCentral::Utilities::Date::getHumanFriendlyDate($FeedbackRequests->{$ID}->{CreateDate});
   }

   return $FeedbackRequests;
}

=head2 getFeedbackReplies

Given a FeedbackID, returns the HTML for the Feedback replies

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object
   2. $UFeedbackID - The feedbackIT

=item B<Prints :>

   1. $FeedbackReplies - The html for the feedback replies

=back

=cut

#############################################
sub getFeedbackReplies {
#############################################
   my $self = shift;
   my $FeedbackID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::getFeedbackReplies with : $FeedbackID");

   my $FeedbackReplyObj = $self->{DBManager}->getTableObj("FeedbackReply");
   my $FeedbackReplies = $FeedbackReplyObj->get_with_restraints("FeedbackID = $FeedbackID");

   my $html = "";
   foreach my $ID (sort keys %{$FeedbackReplies}) {
         my $AdminUser = $self->{AdminUserObj}->get_field_by_ID("Username", $FeedbackReplies->{$ID}->{AdminUser});
         my $Date = ListCentral::Utilities::Date::getHumanFriendlyDate($FeedbackReplies->{$ID}->{ReplyDate});;
         $html .= qq~<tr><td class="StatsTableData">$ID</td>
                      <td class="StatsTableData">$AdminUser</td>
                      <td class="StatsTableData">$Date</td>
                      <td class="StatsTableData">$FeedbackReplies->{$ID}->{Reply}</td>
                      <td class="StatsTableData">$FeedbackReplies->{$ID}->{Note}</td></tr>
                  ~;
   }

   if($html eq ""){
      $html = qq~<tr><td colspan="5"><center><br />No Feedback Replies found<br /><br /></center></td></tr>~;               
   }

   return $html;
}

=head2 addFeedbackReply

Adds a feedback reply from the admin interface

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object

=item B<Prints :>

   1. $html - The html for the feedback replies

=back

=cut

#############################################
sub addFeedbackReply {
#############################################
   my $self = shift;
   my $AdminUserID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::addFeedbackReply");

   my $ErrorMessages = "";
   if($self->{cgi}->{"FeedbackReply.Note"} eq "" && $self->{cgi}->{"FeedbackReply.Message"} eq "" && $self->{cgi}->{"Feedback.FeedbackStatusID" != 1}){
      $ErrorMessages = "You have to reply something here... Jeez!";
   }else{
      # Store the info
      $self->{cgi}->{"FeedbackReply.AdminUser"} = $AdminUserID;
      $self->{cgi}->{"FeedbackReply.Status"} = 1;
      my $FeedbackReplyObj = $self->{DBManager}->getTableObj("FeedbackReply");
      my $FeedbackReplyID = $FeedbackReplyObj->store($self->{cgi});

      # If FeedbackReply.Message not null, send email to Feedback.ReportingUser
      if($self->{cgi}->{"FeedbackReply.Reply"} ne ""){
         $self->sendFeedbackReply($AdminUserID, $FeedbackReplyID);
      }

      # Update the FeedbackStatus
      my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
      if($self->{cgi}->{"FeedbackStatusID"} != 1){         
         $FeedbackObj->update("FeedbackStatusID", $self->{cgi}->{"FeedbackStatusID"}, $self->{cgi}->{"FeedbackReply.FeedbackID"});
      }
      # Did the admin user indicate this was a valid complaint?
      if($self->{cgi}->{"ValidComplaint"}){         
         $FeedbackObj->update("ValidComplaint", $self->{cgi}->{"ValidComplaint"}, $self->{cgi}->{"FeedbackReply.FeedbackID"});

         # Add an entry in ComplaintsAgainstUser
         my $UserID;
         my $Feedback = $FeedbackObj->get_by_ID($self->{cgi}->{"FeedbackReply.FeedbackID"});
         if($Feedback->{ProblematicUserID}){
            $UserID = $Feedback->{ProblematicUserID};
         }elsif($Feedback->{ProblematicListID}){
            my $ListObj = $self->{DBManager}->getTableObj("List");
            my $List = $ListObj->get_by_ID($Feedback->{ProblematicListID});
            $UserID = $List->{UserID};
         }

         # Is there an entry in ComplaintsAgainstUser for this one yet?
         my $ComplaintsAgainstUserObj = $self->{DBManager}->getTableObj("ComplaintsAgainstUser");
         my $FeedbackID = $self->{cgi}->{"FeedbackReply.FeedbackID"};
         my $Complinat = $ComplaintsAgainstUserObj->get_with_restraints("UserID = $UserID AND FeedbackID = $FeedbackID");
         my $exists = 0;
         foreach my $ID(keys %{$Complinat}) {
            $exists++;
         }

         if($exists == 0){
            my %ComplaintAgainstUser;
            $ComplaintAgainstUser{"ComplaintsAgainstUser.UserID"} = $UserID;
            $ComplaintAgainstUser{"ComplaintsAgainstUser.ReportingUserID"} = $Feedback->{ReportingUserID};
            $ComplaintAgainstUser{"ComplaintsAgainstUser.AdminUser"} = $AdminUserID;
            $ComplaintAgainstUser{"ComplaintsAgainstUser.InfractionID"} = $self->{cgi}->{"InfractionID"};
            $ComplaintAgainstUser{"ComplaintsAgainstUser.FeedbackID"} = $self->{cgi}->{"FeedbackReply.FeedbackID"};
            $ComplaintAgainstUser{"ComplaintsAgainstUser.Status"} = 1;
   
            my $ID = $ComplaintsAgainstUserObj->store(\%ComplaintAgainstUser);
         }
      }
   }
   return $ErrorMessages;
}

=head2 sendFeedbackReply

Sends the feedback reply email

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListCentral::Admin::FeedbackManager object

=item B<Prints :>

   1. $html - The html for the feedback replies

=back

=cut

#############################################
sub sendFeedbackReply {
#############################################
   my $self = shift;
   my $AdminUserID = shift;
   my $FeedbackReplyID = shift;

   $self->{Debugger}->debug("in ListCentral::Admin::FeedbackManager::sendFeedbackReply");

   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $FeedbackReplyObj = $self->{DBManager}->getTableObj("FeedbackReply");
   my $FeedbackTypeObj = $self->{DBManager}->getTableObj("FeedbackType");
   my $AdminUserObj = $self->{DBManager}->getTableObj("AdminUser");
   
   my $Feedback = $FeedbackObj->get_by_ID($self->{cgi}->{"FeedbackReply.FeedbackID"});
   my $FeedbackReply = $FeedbackReplyObj->get_by_ID($FeedbackReplyID);
   $Feedback->{"ReplyDate"} = ListCentral::Utilities::Date::getHumanFriendlyDate($Feedback->{CreateDate});
   my $FeedbackType = $FeedbackTypeObj->get_field_by_ID("Name", $Feedback->{FeedbackTypeID});
   my $AdminUser = $AdminUserObj->get_by_ID($AdminUserID);

   my $UserReporting;
   if($Feedback->{ReportingUserID}){
      my $UserObj = $self->{DBManager}->getTableObj("User");
      $UserReporting = $UserObj->get_by_ID($Feedback->{ReportingUserID});
   }

   my %Data;
   $Data{"User"} = $UserReporting;
   $Data{"AdminUser"} = $AdminUser;
   $Data{"Feedback"} = $Feedback;
   $Data{"FeedbackReply"} = $FeedbackReply;

   my $subject = "Reply from List Central";
   use ListCentral::Admin::PageGetter;
   my $PageGetter = new ListCentral::Admin::PageGetter(Debugger => $self->{Debugger});
   my $EmailBodyHTML = $PageGetter->getBasicPage("$ListCentral::SETUP::DIR_PATH/emails/feedback_reply.html", \%Data);
   my $EmailBodyTXT = $PageGetter->getBasicPage("$ListCentral::SETUP::DIR_PATH/emails/feedback_reply.txt", \%Data);

   $Data{"BodyHTML"} = $EmailBodyHTML;
   $Data{"BodyTXT"} = $EmailBodyTXT;

   my $EmailHTML = $PageGetter->getBasicPage("$ListCentral::SETUP::DIR_PATH/emails/email_template.html", \%Data);
   my $EmailTXT = $PageGetter->getBasicPage("$ListCentral::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   my $Mailer = new ListCentral::Utilities::Mailer(Debugger=>$self->{Debugger});
   $Mailer->sendEmail($UserReporting->{Email}, 
                    $ListCentral::SETUP::MAIL_FROM_FEEDBACK, 
                    $subject, 
                    $EmailHTML, $EmailTXT, $boundary);
}

1;

=head1 AUTHOR INFORMATION

   Author: Brahmina Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut

