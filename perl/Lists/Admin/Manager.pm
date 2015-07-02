package Lists::Admin::Manager;
use strict;

use Lists::SETUP;
use Lists::DB::DBManager;

use Lists::Admin::Reports;
use Lists::Admin::FeedbackManager;
use Lists::Admin::ThemeManager;

use Lists::Utilities::AdServer;
use Lists::Utilities::Date;
use Lists::Utilities::Search;
use Lists::Utilities::Mailer;
use Lists::Utilities::EmailManager;
use Lists::Utilities::HelpManager;

##########################################################
# Lists::Admin::Manager 
##########################################################

=head1 NAME

   Lists::Admin::Manager.pm

=head1 SYNOPSIS

   $ListManager = new Lists::Admin::Manager($dbh, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 Lists::List Constructor

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

   $self->{Debugger}->debug("in Lists::Admin::Manager constructor");

   if(!$self->{dbh}){
      die $self->{Debugger}->log("Where is ListManager's dbh??");
   }
   if(!$self->{cgi}){
      die $self->{Debugger}->log("Where is ListManager's cgi??");
   }
   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
   }

   $self->{AdminUserObj} = $self->{DBManager}->getTableObj("AdminUser"); 

   $self->{Reports} = new Lists::Admin::Reports(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                                DBManager=>$self->{DBManager}, UserManager=>$self->{UserManager});

   $self->{ErrorMessages} = "";

   return ($self); 
}

=head2 handleRequest

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $field - The field name
   3. $input_type - text, select, radio, checkbox, textarea, hidden

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub handleRequest {
#############################################
   my $self = shift;
   my $file_requested = shift;

   #$self->{Debugger}->debug("in Lists::Admin::Manager handleRequest with $file_requested");

   $self->{ThisAdminUserID} = $self->checkLogin();
   if(!$self->{ThisAdminUserID}){
      $file_requested =~ s/\/\w+.html$/\/login.html/;
      $self->{Debugger}->debug("No one Logged in, changed file: $file_requested");
   }  


   my $content = "";
   if($self->{cgi}->{todo}){
      my $todo;
      if($self->{cgi}->{todo} =~ s/ThemeManager\.(\w+)//){
         $todo = $1;
         $self->{ThemeManager} = new Lists::Admin::ThemeManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
         my $file = $self->{ThemeManager}->$todo();
         $content = $self->printPage($file);
      }elsif($self->{cgi}->{todo} =~ s/FeedbackManager\.(\w+)//){
         $todo = $1;
         $self->{FeedbackManager} = new Lists::Admin::FeedbackManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
         $self->{FeedbackManager}->{ThisAdminUser} = $self->{ThisAdminUser};
         my $file = $self->{FeedbackManager}->$todo();
         $content = $self->printPage($file);
      }elsif($self->{cgi}->{todo} =~ s/AdServer\.(\w+)//){
         $todo = $1;
         $self->{AdServer} = new Lists::Utilities::AdServer(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
         my $file = $self->{AdServer}->$todo();
         $content = $self->printPage($file);
      }elsif($self->{cgi}->{todo} =~ s/HelpManager\.(\w+)//){
         $todo = $1;
         $self->{HelpManager} = new Lists::Utilities::HelpManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                 DBManager=>$self->{DBManager});
         my $file = $self->{HelpManager}->$todo();
         $content = $self->printPage($file);
      }elsif($self->{cgi}->{todo} =~ s/EmailManager\.(\w+)//){
         $todo = $1;
         $self->{EmailManager} = new Lists::Utilities::EmailManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                 DBManager=>$self->{DBManager});
         my $file = $self->{EmailManager}->$todo();
         $content = $self->printPage($file);
      }else{
         $todo = $self->{cgi}->{todo};
         $content = $self->$todo();
      }      
   }else{
      $content = $self->printPage($file_requested);
   }
   $self->{Debugger}->debug("leaving Lists::Admin::Manager handleRequest");
  
   return $content;
}

=head2 printPage

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object
   2. $page - the page to print

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub printPage {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager->printPage with page $page");

   my $content = "";
   my $template = $page;
   open(PAGE, $template) || $self->{Debugger}->debug("cannot open file: $template - $!");
   my @lines = <PAGE>;
   close PAGE;

   my $UserInfo;
   if($self->{cgi}->{UserID}){
      my $UserObj = $self->{DBManager}->getTableObj("User");
      $UserInfo = $UserObj->get_by_ID($self->{cgi}->{UserID});
   }
   
   if($page =~ m/user\.html$/){
      $self->{Debugger}->debug("if 1");
      $self->{UserManager}->getUserInfo($UserInfo);
      $self->{FeedbackManager} = new Lists::Admin::FeedbackManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   }elsif($page =~ m/feedback/ && ! $self->{FeedbackManager}){
      $self->{FeedbackManager} = new Lists::Admin::FeedbackManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
      $self->{FeedbackManager}->{ThisAdminUser} = $self->{ThisAdminUser};
   }elsif($page =~ m/theme_management\.html$/ && !$self->{ThemeManager}){

      $self->{ThemeManager} = new Lists::Admin::ThemeManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   }elsif($page =~ m/advert_management\.html$/ && !$self->{AdServer}){
      $self->{AdServer} = new Lists::Utilities::AdServer(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   }elsif($page =~ m/help_management\.html$/ && !$self->{HelpManager}){
      $self->{HelpManager} = new Lists::Utilities::HelpManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   }elsif($page =~ m/email_management\.html$/ && !$self->{EmailManager}){
      $self->{EmailManager} = new Lists::Utilities::EmailManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   }else{
      $self->{Debugger}->debug("else -> $self->{FeedbackManager}");
      foreach (keys %{$self->{FeedbackManager}}) {
         $self->{Debugger}->debug("what the fuck is this: $_");
      }
   }
   
   # BETTER WAY???
   # How do I make it know whether or not this call is as a result of a recursive call?
   # Is access to the perl call stack available?

   foreach my $line (@lines) {
      if($line =~ m/<!--(.+)-->/){
         #$self->{Debugger}->debug("printPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--RootPath-->/){
            my $RootPath = $Lists::SETUP::ROOT_PATH . "Lists/";
            $line =~ s/<!--RootPath-->/$RootPath/;
         }elsif($line =~ m/<!--Display\.Page\.(.+)-->/){
            # Display.Page.PathttoPageNameFromDocRoot
            my $page = $1;
            my $file = "$Lists::SETUP::ADMIN_DIR_PATH/$page";
            my $content = $self->printPage($file);
            $line =~ s/<!--Display\.Page\.$page-->/$content/;
         }elsif($line =~ m/<!--Input\.(.+)-->/){
            my $input = $self->getInputHTMLTag($line);
            $line =~ s/<!--Input\.$1-->/$input/;
         }elsif($line =~ m/<!--DB\.(\w+)\.(\w+)\.(.+)-->/){
            my $table = $1;
            my $field = $2;
            my $last = $3;
            my $ID = $last;
            if($ID eq "LoggedInUser"){
               $ID = $self->{ThisAdminUser}->{ID};
            }elsif($self->{cgi}->{UserID}){
               $ID = $self->{cgi}->{UserID};
            }
            my $TableObj = $self->{DBManager}->getTableObj($table);
            my $value = $TableObj->get_field_by_ID($field, $ID);
            if($field =~ m/Date/){
               my $dateFormatted = Lists::Utilities::Date::getHumanFriendlyDate($value);
               $line =~ s/<!--DB\.$table\.$field\.$last-->/$dateFormatted/;
            }else{
               $line =~ s/<!--DB\.$table\.$field\.$last-->/$value/;
            } 
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--Self\.([\w\.]+)-->/){
            my $variable = $1;
            $line =~ s/<!--Self\.$variable-->/$self->{$variable}/;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--Debug-->/){
            $line =~ s/<!--Debug-->/$self->{Debugger}->{DebugMessages}/;
         }elsif($line =~ m/<!--PageTitle-->/){
            if(!$self->{PageTitle}){
               $self->{PageTitle} = $Lists::SETUP::DEFAULT_ADMIN_PAGE_TITLE;
            }
            $line =~ s/<!--PageTitle-->/$self->{PageTitle}/;
         }elsif($line =~ m/<!--ErrorMessages-->/){
            if($self->{ErrorMessages}){
               $self->{ErrorMessages} = "<span class=\"error\">$self->{ErrorMessages}</span><br />";
            }
            $line =~ s/<!--ErrorMessages-->/$self->{ErrorMessages}/;
         }elsif($line =~ m/<!--ThemeID-->/){
            my $ThemeID = 1;
            if($self->{cgi}->{UserID}){
               my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings"); 
               my $UserSettings = $UserSettingsObj->get_with_restraints("UserID = $self->{cgi}->{UserID}");
               $ThemeID = $UserSettings->{$self->{cgi}->{UserID}}->{ThemeID};
            }
            $line =~ s/<!--ThemeID-->/$ThemeID/;
         }elsif($line =~ m/<!--AdminUser-->/){
            my $AdminUser = $self->{ThisAdminUser}->{Username};
            $line =~ s/<!--AdminUser-->/$AdminUser/;
         }elsif($line =~ m/<!--Report\.(\w+)-->/){
            my $reportName = $1;
            my $report = $self->{Reports}->getReport($reportName);
            $line =~ s/<!--Report\.$reportName-->/$report/;
         }elsif($line =~ m/<!--ThemeManager\.(\w+)-->/){
            my $themeItem = $1;
            my $content = $self->{ThemeManager}->getThemeElement($themeItem);
            $line =~ s/<!--ThemeManager\.$themeItem-->/$content/;
         }elsif($line =~ m/<!--FeedbackManager\.(.+)-->/){
            my $feedbackItem = $1;
            my $content = $self->{FeedbackManager}->getFeedbackElement($feedbackItem);
            $line =~ s/<!--FeedbackManager\.$feedbackItem-->/$content/;
         }elsif($line =~ m/<!--AdServer\.(.+)-->/){
            my $function = $1;
            my $content = $self->{AdServer}->$function();
            $line =~ s/<!--AdServer\.$function-->/$content/;
         }elsif($line =~ m/<!--HelpManager\.(.+)-->/){
            my $function = $1;
            my $content = $self->{HelpManager}->$function();
            $line =~ s/<!--HelpManager\.$function-->/$content/;
         }elsif($line =~ m/<!--EmailManager\.(.+)-->/){
            my $function = $1;
            my $content = $self->{EmailManager}->$function();
            $line =~ s/<!--EmailManager\.$function-->/$content/;
         }elsif($line =~ m/<!--UserInfo\.(\w+)-->/){
            my $field = $1;
            my $value = $UserInfo->{$field};
            $line =~ s/<!--UserInfo\.$field-->/$value/;
         }elsif($line =~ m/<!--Feedback.Problematic(\w+)-->/){
            my $table = $1;
            my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
            my $Feedback = $FeedbackObj->get_by_ID($self->{cgi}->{FeedbackID});
            my $value = "&nbsp";
            if($table eq "User"){
               if($Feedback->{ProblematicUserID}){
                  my $UserObj = $self->{DBManager}->getTableObj("User");
                  my $User = $UserObj->get_by_ID($Feedback->{ProblematicUserID});
                  $value = qq~<a href="/user.html?UserID=$Feedback->{ProblematicUserID}">$User->{Username}</a>~;
               }              
            }elsif($table eq "List"){
               if($Feedback->{ProblematicListID}){
                  my $ListObj = $self->{DBManager}->getTableObj("List");
                  my $List = $ListObj->get_by_ID($Feedback->{ProblematicListID});
                  my $ListURL = $ListObj->getListURL($List);
                  $value = qq~<a href="$Lists::SETUP::URL/$ListURL">$List->{Name}</a>~;
               }              
            }            
            $line =~ s/<!--Feedback.Problematic$table-->/$value/;
         }elsif($line =~ m/<!--SearchResultsRows-->/){
            $line =~ s/<!--SearchResultsRows-->/$self->{SearchResultsRows}/;
         }elsif($line =~ m/<!--NavOnAdServerTab\.(\w+)-->/){
            my $tab = $1;
            my $classAddition = "";
            if($self->{AdServer}->{Tab}->{$tab}){
               $classAddition = "On";
            }            
            $line =~ s/<!--NavOnAdServerTab.$tab-->/$classAddition/;
         }elsif($line =~ m/<!--DisplayAdServerTab\.(\w+)-->/){
            my $tab = $1;
            my $style = "display:none";
            if($self->{AdServer}->{Tab}->{$tab}){
               $style = "display:block";
            }            
            $line =~ s/<!--DisplayAdServerTab.$tab-->/$style/;
         }else{
            if($line =~ m/<!--(.+)-->/){
               my $tag = $1;
               #$self->{Debugger}->log("ERROR: Unknown Tag: $tag");
            }else{
               #$self->{Debugger}->log("ERROR: Unknown Tag, Line: <textarea>$line</textarea>");
            }            
         }
      }

      $content .= $line;
   }
   return $content;
}

=head2 doLogin

Handles the process of logging in and admin person

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub doLogin {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager::doLogin");

   my $Username = $self->{cgi}->{"AdminUser.Username"};
   my $UserPassword = $self->{cgi}->{"AdminUser.Password"};

   my $AdminUser = $self->{AdminUserObj}->get_by_field("Username", $Username);
   if($AdminUser->{ID}){
      if($AdminUser->{Status} >= 1){
         if($AdminUser->{Password} eq $UserPassword){
            $self->{Debugger}->debug("should be writing that cookie");
            # All good, set cookie
            my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "ListCentralAdmin", -value => $AdminUser->{ID} );
            $cookie_out->path("/"); 
            $cookie_out->bake($self->{Request});
            $self->{ThisAdminUser} = $AdminUser;
            return ($AdminUser->{ID}, "Welcome $AdminUser->{Username}");
         }else{
            # Incorrect password
            return 0, "Incorrect password";
         }
      }else{
         # Bad user status
         return 0, "Bad User Status";
      }
   }else{
      # No sure user name
      return 0, "Incorrect Username";
   }
}

=head2 userHasAdminPermission

Checks if the user represented by the UID passes has the right UserLevel to 
be able to make changes

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object
   2. $UID - The User ID

=item B<Prints :>

   1. $userHasPermisionToEdit - 1 if the user does have permision to edit, 0 otherwise

=back

=cut

#############################################
sub userHasAdminPermission {
#############################################
   my $self = shift;
   my $UID = shift;

   my $userHasPermisionToEdit = 0;

   my $UserLevel = 0;
   if($UID){
      my $sql_userlevel = "SELECT Level FROM AdminUser WHERE ID = $UID";
      my $stm = $self->{dbh}->prepare($sql_userlevel);
      if ($stm->execute()) {
         while (my $hash = $stm->fetchrow_hashref()) {
            $UserLevel = $hash->{UserLevel};
         }
      }else{
         print "Error with User SELECT: $sql_userlevel<br />";
      }
      $stm->finish;
   }

   if($UserLevel == 2){
      $userHasPermisionToEdit = 1;
   }

   return $userHasPermisionToEdit;
}

=head2 checkLogin

Checks the cookies for login info

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub checkLogin {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager::checkLogin ");

   my $ACookie = Apache2::Cookie::Jar->new($self->{Request});
   my $cookie_in = $ACookie->cookies("ListCentralAdmin");

   $self->{Debugger}->debug("cookie_in: $cookie_in");

   my $UID = 0;
   if($cookie_in =~ m/ListCentralAdmin=(\d+)/){
      $UID = $1;
      my $AdminUser = $self->{AdminUserObj}->get_by_ID($UID);
      $self->{ThisAdminUser} = $AdminUser;
   }else{
      $self->{Debugger}->debug("None of our cookies are here, not logged in - Cookie: $cookie_in");
   }
   return $UID;
}

=head2 doLogout

Clears the cookies on logout

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::Admin::Manager object

=item B<Prints :>

   1. $UID - The User ID if logged in, 0 otherwise

=back

=cut

#############################################
sub doLogout {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager::doLogout ");

   my $cookie_out = Apache2::Cookie->new($self->{Request}, -name  => "Lists", -value => "" );
   $cookie_out->path("/"); 
   $cookie_out->bake($self->{Request});
   $self->{ThisAdminUser}->{ID} = "";
   $self->{ThisAdminUser}->{Name} = "";
}


=head2 Login

Handles the login process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub Login {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListManager::Login");

   my $ID;
   ($ID, $self->{ErrorMessages}) = $self->doLogin();
   $self->{Debugger}->debug("self->{ThisAdminUser}->{ID}: $self->{ThisAdminUser}->{ID}, self->{ErrorMessages}: $self->{ErrorMessages} back from doLogin");

   if(!$self->{ThisAdminUser}->{ID}){
      $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/login.html");
   }else{
      $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/index.html");
   }

}

=head2 Logout

Handles the login process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub Logout {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListManager::Logout");

   $self->doLogout();
   $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/index.html");
}

=head2 SearchUsers

Handles the Search Users process

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub SearchUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager::SearchUsers"); 

   my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                   'UserManager'=>$self->{UserManager});
   my $UsersHash; my $Qid;
   if($self->{cgi}->{Query} =~ m/^(\d+)$/){
      my $ID = $1;
      $Qid = $ID;
      my $UserObj = $self->{DBManager}->getTableObj("User");
      $UsersHash->{$ID} = $UserObj->get_by_ID($ID);
   }else{
      $UsersHash = $SearchModule->doAdminUserSearch($self->{cgi}->{Query});
   }


   my $ResultsRows;
   if($Qid && !$UsersHash->{$Qid}->{ID}){
      $ResultsRows = "<tr><td colspan='7'><center><br />Your query did not match any results :( <br /<br /></center></td></tr>";
   }else{
      $ResultsRows = $SearchModule->processSearchResults("$Lists::SETUP::ADMIN_DIR_PATH/Utilities/Search/user_search_results_rows.html", $UsersHash);
   }

   $self->{SearchResultsRows} = $ResultsRows;
   $self->{Pagenation} = "Pages";

   $self->{PageTitle}= "List Central Admin : User Search: $self->{cgi}->{Query}";
   my $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/Utilities/Search/user_search_results.html");

   return $content;
}

=head2 SearchLists

Handles the Search List process

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub SearchLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::Admin::Manager::SearchLists"); 

   my $content = "";
   if($self->{cgi}->{Query} ne ""){
      my $Page = $self->{cgi}->{Page}  ? $self->{cgi}->{Page}: 1;
      my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                      'UserManager'=>$self->{UserManager});

      my $ListsHash; 
      if($self->{cgi}->{Query} =~ m/^(\d+)$/){
         my $ID = $1;
         my $ListObj = $self->{DBManager}->getTableObj("List");
         $ListsHash->{$ID} = $ListObj->get_by_ID($ID);
      }else{
         $ListsHash = $SearchModule->doBasicListSearch($self->{cgi}->{Query}, $Page);
      }

      my $Calculator = new Lists::Admin::Calculator("Debugger" => $self->{Debugger}, "DBManager" => $self->{DBManager},
						      "UserManager" => $self->{UserManager});
      my $ListObj = $self->{DBManager}->getTableObj("List");
      my $count = 0;
      foreach my $ID(keys %{$ListsHash}) {
         if($ListsHash->{$ID}->{ID}){
            $ListObj->getListInfo($ListsHash->{$ID}, $self->{DBManager}, $self->{UserManager});
	    $Calculator->getListInfo($ListsHash->{$ID});
            $count++;
         }
      }
   
      my $ResultsRows;
      if($count == 0){
         $ResultsRows = "<tr><td colspan='12'><center><br />Your query did not match any results :(<br /><br /></center></td></tr>";
      }else{
         $ResultsRows = $SearchModule->processSearchResults("$Lists::SETUP::ADMIN_DIR_PATH/Utilities/Search/list_search_results_rows.html", $ListsHash);
      }

      $self->{SearchResultsRows} = $ResultsRows;
      $self->{Pagenation} = "Pages";
      $self->{PageTitle}= "List Central Admin : List Search: $self->{cgi}->{Query}";
   
      $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/Utilities/Search/list_search_results.html");
   }else{
      $self->{ErrorMessages} .= "Empty Search Query";
      $content = $self->printPage("$Lists::SETUP::DIR_PATH/index.html");
   }

   return $content;
}

=head2 EmailUser

Emails a a user 

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub EmailUser {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Manager::EmailUser");

   # Test Email Address given
   use Lists::Utilities::Mailer;
   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->get_by_ID($self->{cgi}->{UserID});
   my $toEmail = $User->{Email};

   my $ErrorMessage = "";
   if($Mailer->testEmail($toEmail)){
      my $EmailBody = "$self->{cgi}->{Message}";
      $Mailer->send_email($toEmail, $Lists::SETUP::FROM_EMAIL, "Message from List Central", $EmailBody);
   }else{
      # Don't send
      $ErrorMessage = "The email address you entered is invalid";
   }

   my $content;
   if($ErrorMessage eq ""){
      $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/email_user_success.html");
   }else{
      $self->{ErrorMessages} .= $ErrorMessage;
      $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/email_user.html");
   }

   print STDERR "$content";
   return $content;

}

=head2 MinifyJS

Minifies the Javascript

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub MinifyJS {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in List::Admin::Manager::MinifyJS");

   use Lists::Admin::Minify;
   my $Minifier = new Lists::Admin::Minify(Debugger => $self->{Debugger});
   $Minifier->minifyJS();
   my $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/theme_management.html");
   return $content;

}

=head2 getInputHTMLTag

Gets the html of a form input element

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $tag - the tag

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub getInputHTMLTag {
#############################################
   my $self = shift;
   my $tag = shift;

   if(!$tag =~ m/<!--(.+)-->/){
      $self->{Debugger}->debug("in ListManger::getInputHTMLTag: What the hell are we in getInputHTMLTag for: $1?");
      return "?getInputHTMLTag?";
   }else{
      $self->{Debugger}->debug("in ListManger::getInputHTMLTag with line: <br /><textarea>$tag</textarea><br /> tag: $1");
   }

   my $input = "";
   if($tag =~ m/Select/){
      if($tag =~ m/<!--Input\.(\w+)\.(\w+)\.(\w+)\.(\w+)\.(\w+)-->/){
         #<!--Input.Select.ListGroup.ID.Name.List_ListGroupID-->  
         # Input.Select.Table.Value.Display.name
         my $input_type = $1;
         my $table = $2;
         my $value = $3;
         my $display = $4;
         my $name = $5;

         $name =~ s/_/./;
         my $id = $name;
         my @temparray = split(/\./, $id);
         $id = $temparray[1];
         
         if($input_type eq "Select"){
            my $options = "";
            my $TableObj = $self->{DBManager}->getTableObj($table);
            my $Hash = $TableObj->get_all();
            foreach my $ID (sort keys %{$Hash}) {
               $options .= qq~<option value="$Hash->{$ID}->{$value}">$Hash->{$ID}->{$display}</option>
                              ~;
            }
            $input = qq~<select name="$name" id="$id">
                           <option value="">Select</option>
                           $options
                        </select>
                     ~;
         }elsif($input_type eq "SelectJS"){
            my $options = "";
            my $TableObj = $self->{DBManager}->getTableObj($table);
            my $Hash = $TableObj->get_all();
            foreach my $ID (sort keys %{$Hash}) {
               $options .= qq~"<option value='$Hash->{$ID}->{$value}'>$Hash->{$ID}->{$display}</option>" +
                              ~;
            }
            $input = qq~"<select name='$name' id='$id'>" +
                        "   <option value=''>Select</option>" +
                           $options
                        "</select>" +
                     ~;
         }
      }else{
         if($tag =~ m/<!--Input\.(\w+)\.(\w+)\.(\w+)\.(\w+)-->/){
            my $input_type = $1;
            my $table = $2;
            my $value = $3;
            my $display = $4;
            if($input_type eq "Text"){
               $input = qq~<input type="text" name="$table.$display" /> ~;
            }elsif($input_type eq "TextArea"){
               $input = qq~<textarea name="$table.$display"></textarea> ~;
            }else{
               $self->{Debugger}->debug("I don't know what to do with this input type: $input_type!");
            }
         }
      }
   }

   return $input;
}

=head2 BlockUser

Blocks the user in cgi->UserID

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object
   2. $tag - the tag

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub BlockUser {
#############################################
   my $self = shift;

   my $UserID = $self->{cgi}->{UserID};

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->get_by_ID($UserID);

   $UserObj->update("Status", 0, $UserID);

   $self->{Message} = "<b>Successfully deleted user $User->{Username}: $UserID</b><br /><br />";

   return $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/users.html");

}

=head2 DeleteList

Deletes the list in cgi->ListID

=over 4

=item B<Parameters :>

   1. $self - Reference to a Printer object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteList {
#############################################
   my $self = shift;

   my $ListID = $self->{cgi}->{ListID};

   my $ListObj = $self->{DBManager}->getTableObj("List");
   my $List = $ListObj->get_by_ID($ListID);

   $ListObj->update("Status", 0, $ListID);

   $self->{Message} = "<b>Successfully deleted user $List->{Name}: $ListID</b><br /><br />";

   return $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/lists.html");

}

=head2 AddFeedbackReply

Adds a new feedback reply from the list central admin interface

=over 4

=item B<Parameters :>

   1. $self - Reference to a List object

=item B<Returns :>

   1. $content - the page to display

=back

=cut

#############################################
sub AddFeedbackReply {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddFeedbackReply");

   my $FeedbackManager = new Lists::Admin::FeedbackManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                  DBManager=>$self->{DBManager});
   $self->{ErrorMessages} = $FeedbackManager->addFeedbackReply($self->{ThisAdminUserID});
   
   $self->{cgi}->{"FeedbackID"} = $self->{cgi}->{"FeedbackReply.FeedbackID"};
   my $content = $self->printPage("$Lists::SETUP::ADMIN_DIR_PATH/feedback.html");

   return $content;
}

1;


=head1 AUTHOR INFORMATION

   Author: Marilyn Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut
