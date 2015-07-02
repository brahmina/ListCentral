package Lists::ListsManager;
use strict;

use Lists::SETUP;
use Lists::DB::DBManager;
use Lists::UserManager;
use Lists::Editor;

use Lists::Utilities::Cache;
use Lists::Utilities::Date;
use Lists::Utilities::Ranker;
use Lists::Utilities::Search;
use Lists::Utilities::GoogleAnalytics;

##########################################################
# Lists::ListsManager 
##########################################################

=head1 NAME

   Lists::ListsManager.pm

=head1 SYNOPSIS

   $ListsManager = new Lists::ListsManager($dbh, $cgi, $debug);

=head1 DESCRIPTION

Used to manage, and maintain the List application

=head2 Lists::List Constructor

=over 4

=item B<Parameters :>

   1. $dbh
   2. $cgi
   3. $debug
   

=item B<TODO :>

   ?

=back

=cut

########################################################
sub new {
########################################################
   my $classname = shift; 
   my $self; 
   %$self = @_; 
   bless $self, ref($classname)||$classname;

   $self->{Debugger}->debug("in Lists::ListsManager constructor");

   if(!$self->{Debugger}){
      print STDERR "No debugger? $self->{Debugger}\n";
      $self->{ErrorMessages} = "No debugger? $self->{Debugger}??";
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   if(!$self->{DBManager}){
      $self->{Debugger}->log("Where is ListsManager's DBManager??");
      $self->{ErrorMessages} = "Where is ListsManager's DBManager??";
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   if(!$self->{cgi}){
      $self->{Debugger}->log("Where is ListsManager's cgi??");
      $self->{ErrorMessages} = "Where is ListsManager's cgi??";
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   
   $self->{ListObj} = $self->{DBManager}->getTableObj("List"); 
   $self->{ListItemObj} = $self->{DBManager}->getTableObj("ListItem"); 
   $self->{ListItemStatusObj} = $self->{DBManager}->getTableObj("ListItemStatus"); 
   $self->{ListGroupObj} = $self->{DBManager}->getTableObj("ListGroup"); 
   $self->{LinkObj} = $self->{DBManager}->getTableObj("Link"); 

   $self->{ListItemObj}->{UserManager} = $self->{UserManager};

   $self->{Editor} = new Lists::Editor(Debugger => $self->{Debugger}, 
                                       cgi => $self->{cgi}, 
                                       DBManager => $self->{DBManager},
                                       UserManager => $self->{UserManager});

   $self->{ErrorMessages} = "";

   return ($self); 
}

=head2 handleRequest

Handles any request made to the Lists site

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
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

   $self->{Debugger}->debug("in Lists::ListsManager handleRequest with $file_requested & todo: $self->{cgi}->{todo}");

   if($ListsDev::SETUP::UNDER_CONSTUCTION){
      # Under construction
      my $IP = $ENV{'REMOTE_ADDR'};
      my $IPisPermitted = 0;
      foreach my $permittedIP(@Lists::SETUP::PERMITTED_IPS){
         if($IP eq $permittedIP){
            $IPisPermitted = 1;
         }
      }
      # Permitted IPs
      if (!$IPisPermitted) {
         $self->setThemeID();
         my $content = $self->processPage("$Lists::SETUP::DIR_PATH/under_construction.html");
         return $content;
      }
   }

   # Cookie Checking - Get ThisUser
   $self->{UserManager}->checkLogin();
   $self->{Debugger}->debug("Back from checkLogin ID - $self->{UserManager}->{ThisUser}->{ID}");  
   if(! $self->{UserManager}->{ThisUser}->{ID}){

      my $UserID = $self->{UserManager}->checkPersistentCookie();
      $self->{Debugger}->debug("From checkPersistentCookie: UserID: $UserID");  
      if($UserID){
         $self->{UserManager}->setNormalCookie($UserID);

         my $UserObj = $self->{DBManager}->getTableObj("User");
         $UserObj->update("LastLogin", time(), $UserID);

         my $UserObj = $self->{DBManager}->getTableObj("User");
         $self->{UserManager}->{ThisUser} = $UserObj->get_by_ID($UserID);
         $self->{UserManager}->getThisUserInfo();
      }
   }

   $self->{"file_requested"} = $file_requested;
   $self->setThemeID();

   # Debug the CGI variable
   if($self->{Debugger}->{debug}){
      foreach my $key (keys %{$self->{cgi}}) {
         if($key !~ m/^Upload/){
            $self->{Debugger}->debug("CGI: $key - $self->{cgi}->{$key}");
         }
      }
   }

   my $content = "";
   if($self->{cgi}->{todo}){
      $self->{Debugger}->debug("todo - $self->{cgi}->{todo}");
      $self->{cgi}->{todo} =~ s/ListsManager\.//;

      if(!$self->{UserManager}->{ThisUser}->{ID} && !$Lists::SETUP::NOT_LOGGED_IN_TODOS{$self->{cgi}->{todo}}){
         #$self->{Debugger}->throwNotifyingError("Someone trying to get page they shouldn't be: page: $page, self->{cgi}->{UserID}: $self->{cgi}->{UserID}, self->{UserManager}->{ThisUser}->{ID}: $self->{UserManager}->{ThisUser}->{ID}");
         if($self->{cgi}->{ajax}){
            $content =  "<p><b>" . $Lists::SETUP::MESSAGES{'NO_PERMISSION'} . "</b></p>";
         }else{
            $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION'};
            $content = $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
         }
      }else{
   
         if($self->{cgi}->{"todo"} eq "editInPlace"){
            $content = $self->{Editor}->doEditInPlace();
         }else{
            my $function = $self->{cgi}->{"todo"};
            if($function eq "getList"){
               $content = $self->getListHTML($self->{cgi}->{"ListID"});
            }else{
               $content = $self->$function();
            }
         } 
      }
   }else{
      my $Cacher = new Lists::Utilities::Cache(Debugger => $self->{Debugger}, 
                                               cgi => $self->{cgi}, UserManager => $self->{UserManager});
      my $cacheContent = $Cacher->checkCache($file_requested);
      if($cacheContent eq "build_and_cache"){
         $content = $self->getPage($file_requested);
         $Cacher->setCache($file_requested, $content);
      }elsif($cacheContent eq "build"){
         $content = $self->getPage($file_requested);
      }else{
         $content = $cacheContent;
      }
   }
 
   $self->{Debugger}->debug("leaving Lists::ListsManager handleRequest");

   $self->{PageTitle} = $self->getPageTitle();
  
   return $content;
}

=head2 getPage

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getPage {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getPage with page $page, ThemeID $self->{ThemeID} Logged in: $self->{UserManager}->{ThisUser}->{ID}");

   $page = $self->doPageMods($page);
   $page = $self->getPageData($page);
 
   $self->{Debugger}->debug("going to processPage with page $page");

   my $content = $self->processPage($page);

   return $content;
}

=head2 getPageData

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub getPageData {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getPageData with page $page");

   if($page !~ m/upper_links/ && $page !~ m/login/ && $page !~ m/preloaded_images/){
      # The other load pages in the template, don't bother with this
      if($self->{cgi}->{UserID}){
         my $UserObj = $self->{DBManager}->getTableObj("User");
         $self->{PageOwner} = $UserObj->get_by_ID($self->{cgi}->{UserID});
   
         if(! $self->{PageOwner}->{ID}){
            $self->{ThemeID} = $Lists::SETUP::CONSTANTS{'DEFAULT_THEME'};
            $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'DEACTIVATED_USER'};
            $page = "$Lists::SETUP::DIR_PATH/error.html";        
         }else{
            if($page =~ m/settings/){
               $self->{UserManager}->{UserSettings} = 1;
            }
            $self->{UserManager}->getUserInfo($self->{PageOwner});
         }    
   
         if(! $self->{ListsNavHeader}){
            $self->{ListsNavHeader} = "$self->{PageOwner}->{Username}'s lists";
         }
   
         # This is to handle the addition of the extra menu items on the about section
         if(!$self->{SliderJS}){  
            my ($ListsNavigation, $SliderJS) = $self->getListNavigation();
            if($self->{ListsNavigation}){
               $self->{ListsNavigation} = $self->{ListsNavigation} . $ListsNavigation;
            }else{
               $self->{ListsNavigation} = $ListsNavigation;
            }
            $self->{SliderJS} = $SliderJS;
         }   
      }
   }

   $self->{Debugger}->debug("self->{cgi}->{ListID}: $self->{cgi}->{ListID}, self->{DisplaySomethingOtherThanList}: $self->{DisplaySomethingOtherThanList}");
   if($page =~ m/lists/){
      if($self->{cgi}->{"ListID"}){        
         if(! $self->{ListsContent}){
            $self->{ListsContent} = $self->getListHTML($self->{cgi}->{"ListID"});
         }               
      }elsif($self->{"DisplaySomethingOtherThanList"}){
         $self->{ListsContent} = $self->processPage($self->{"DisplaySomethingOtherThanList"});
      }elsif(! $self->{ListsContent}){
         if($self->{UserManager}->{ThisUser}->{ID} == $self->{cgi}->{UserID}){
            if(! $self->{UserManager}->userListCount($self->{UserManager}->{ThisUser}->{ID})){
               $self->{MessageToUser} = $self->processPage("$Lists::SETUP::DIR_PATH/loggedin/welcome.html");
            }
         }
         $self->{ListsContent} = $self->getPage("$Lists::SETUP::DIR_PATH/users_space.html");
      }
   }

   return $page;
}

=head2 doPageMods

Handles any request made to the Lists Utility

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub doPageMods {
#############################################
   my $self = shift;
   my $page = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->doPageMods with page $page");

   # if its a template, the processing should be done, lets not mess with it
   if($page =~ m/template/){
      return $page;
   }

   if($self->{cgi}->{"ListID"} && $page =~ m/lists/){
      $self->{ThisList} = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});
      if(!$self->{ThisList}->{ID}){
         # This list has been deleted
         $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'DELETED_LIST'};
         $page = "$Lists::SETUP::DIR_PATH/error.html";
      }elsif(!$self->{ThisList}->{Public} && $self->{UserManager}->{ThisUser}->{ID} != $self->{ThisList}->{UserID}){
         # Private list
         $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_VIEW_LIST'};
         #$self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} tried to view the private list $List->{ID} belonging to $List->{UserID}");
         $page = "$Lists::SETUP::DIR_PATH/error.html";
      }else{
         # The list group slider to open if need be
         $self->{ListGroupSlideOpen} = $self->{ThisList}->{ListGroupID};
      }      
   }elsif($self->{cgi}->{"ListID"} && $page =~ m/email_list/){
      $self->{ThisList} = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});
      $self->{"ListName"} = $self->{ThisList}->{Name};
   }

   # Handle case of someone trying to get an account only page when no one is logged in! This case is where we
   # should kick the person, it seems they are requesting something they shouldn't be requesting
   $self->{Debugger}->debug("Testing account only pages! $page and loggedin userid:$self->{UserManager}->{ThisUser}->{ID}");
   if($Lists::SETUP::ACCOUNT_ONLY_PAGES{$page} && !$self->{UserManager}->{ThisUser}->{ID}){
      #$self->{Debugger}->throwNotifyingError("Someone trying to get page they shouldn't be: page: $page, self->{cgi}->{UserID}: $self->{cgi}->{UserID}, self->{UserManager}->{ThisUser}->{ID}: $self->{UserManager}->{ThisUser}->{ID}");
      if($self->{cgi}->{ajax}){
         return "<p><b>" . $Lists::SETUP::MESSAGES{'NO_PERMISSION'} . "</b></p>";
      }else{
         $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION'};
         $page = "$Lists::SETUP::DIR_PATH/error.html";
      }
   }

   # about page
   if($self->{cgi}->{"UserID"} == $Lists::SETUP::ABOUT_USER_ACCOUNT || $page =~ m/about/ || 
         ($page =~ m/users_space/ && $self->{cgi}->{"UserID"} == $Lists::SETUP::ABOUT_USER_ACCOUNT)){

      $self->{Debugger}->debug("Dealing with about page business with $page");

      $self->{cgi}->{"UserID"} = $Lists::SETUP::ABOUT_USER_ACCOUNT;

      $self->{ListsNavHeader} = "about list central";
      if($self->{ListsNavigation} !~ m/Tag Cloud/){
         my $aboutNavExtra = $self->processPage("$Lists::SETUP::DIR_PATH/about/about_nav_addition.html");
         $self->{ListsNavigation} = $aboutNavExtra . $self->{ListsNavigation};
      }      

      if($self->{UserManager}->{ThisUser}->{ID} != $Lists::SETUP::ABOUT_USER_ACCOUNT){
         $self->{"DontShowListForm"} = 1;
      }

      if($page =~ m/help/){
         if($page =~ m/help_page/){
            use Lists::Utilities::HelpManager;
            my $HelpManager = new Lists::Utilities::HelpManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                                         DBManager=>$self->{DBManager});
            ($self->{"HelpPageContent"}, $self->{PageTitle}) = $HelpManager->getHelpPage($self->{cgi}->{HelpPageID});
            $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/about/help_page.html";
         }else{
            $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/about/help.html";
         }

         
         $page = "$Lists::SETUP::DIR_PATH/lists.html";
      }elsif($page =~ m/tagcloud/){
         $page = "$Lists::SETUP::DIR_PATH/lists.html";
         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/about/tagcloud.html";
         $page = "$Lists::SETUP::DIR_PATH/lists.html";
      }elsif($page =~ m/faq/){
         #/list/about_list_central/frequently_asked_questions/35/193/lists.html
         $self->{cgi}->{"ListID"} = $Lists::SETUP::CONSTANTS{'FAQ_LISTID'};
         $self->{ThisList} = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});
         $page = "$Lists::SETUP::DIR_PATH/lists.html";
      }elsif($page =~ m/about.html/){
         if(! $self->{AboutBlogTeaser}){
            $self->{AboutBlogTeaser} = $self->processPage("$Lists::SETUP::DIR_PATH/about/about_blog_teaser.html");
         }  

         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/about/about.html";
         $page = "$Lists::SETUP::DIR_PATH/lists.html";
      }
   }

   if(($page =~ m/user_space/ || $page =~ m/settings/ || $page =~ m/create_and_edit/ || $page =~ m/messages/) && !$self->{cgi}->{ajax}){

      $self->{Debugger}->debug("Switching page here!!!");
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};      
      $self->{"DisplaySomethingOtherThanList"} = $page;

      # Set the default tag if this is a page load, not form process
      if($page =~ m/create_and_edit/ && !$self->{cgi}->{todo}){
         if($self->{cgi}->{DisplayTab}){
            $self->{CreateEditTab}->{$self->{cgi}->{DisplayCreateEditTab}} = 1;
         }else{
            $self->{CreateEditTab}->{CreateList} = 1;
         }
         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/create_and_edit.html";
      }elsif($page =~ m/settings/ && !$self->{cgi}->{todo}){
         if($self->{cgi}->{DisplaySettingsTab}){
            $self->{SettingsTab}->{$self->{cgi}->{DisplaySettingsTab}} = 1;
         }else{
            $self->{SettingsTab}->{BasicInfo} = 1;
         }
         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/settings.html";;
      }elsif($page =~ m/messages/ && !$self->{cgi}->{todo}){
         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/messages.html";;
      }else{
         $self->{"DisplaySomethingOtherThanList"} = $page;
      }
      $page = "$Lists::SETUP::DIR_PATH/lists.html";
   }

   # If someone is logged in
   if($self->{UserManager}->{ThisUser}->{ID}){
      $page =~ s/$Lists::SETUP::DIR_PATH\///;

      # If this is the list owner
      if($self->{UserManager}->{ThisUser}->{ID} == $self->{cgi}->{UserID}){
         if(-e "$Lists::SETUP::DIR_PATH/owner/$page"){      
            $page = "$Lists::SETUP::DIR_PATH/owner/$page";
         }elsif(-e "$Lists::SETUP::DIR_PATH/loggedin/$page"){
            $page = "$Lists::SETUP::DIR_PATH/loggedin/$page";
         }else{
            $page = "$Lists::SETUP::DIR_PATH/$page";
         }
      }else{
         if(-e "$Lists::SETUP::DIR_PATH/loggedin/$page"){
            $page = "$Lists::SETUP::DIR_PATH/loggedin/$page";
         }else{
            $page = "$Lists::SETUP::DIR_PATH/$page";
         }         
      }     
   }

   $self->{Debugger}->debug("doPageMods returning: $page");
   return $page;

}

=head2 processPage

A more basic version of getPage 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $page - the page to print
   3. $Data - Up to 2 level hash with corresponding data

=item B<Returns :>

   1. $html - The html 

=back

=cut

#############################################
sub processPage {
#############################################
   my $self = shift;
   my $page = shift;
   my $Data = shift;

   $self->{Debugger}->debug("in processPage with page $page, $Data, CGI->UserID: $self->{cgi}->{UserID}");

   # File Cache
   my @lines;
   if($self->{BasicFileCache}->{$page}){
      @lines = @{$self->{BasicFileCache}->{$page}};
   }else{     
      my $template = $page;
      if(! open (PAGE, $template)){
         my $error = "Cannot open file: $template $!";
         $self->{Debugger}->throwNotifyingError($error);
         $self->{ErrorMessages} = "Not found";
         return $self->processPage("$Lists::SETUP::DIR_PATH/errors/404.html");
      }
      @lines = <PAGE>;
      close PAGE;

      my @linesSave = @lines;
      $self->{BasicFileCache}->{$page} = \@linesSave;
   }


   my $content = ""; my $isPageTitle = 0;
   foreach my $line (@lines) {
      if($line =~ m/<!--(.+)-->/){
         $isPageTitle = 0;
         #$self->{Debugger}->debug("processPage tag: $1");
         if($line =~ m/<!--URL-->/){
            my $url = "http://$ENV{HTTP_HOST}";
            $line =~ s/<!--URL-->/$url/;
         }elsif($line =~ m/<!--Data\.([\w_]+)-->/){
            my $field = $1;
            if($field =~ m/(\w+)_(\w+)/){
               my $hashName = $1;
               my $hashValue = $2;
               $line =~ s/<!--Data\.$field-->/$Data->{$hashName}->{$hashValue}/;
            }else{
               $line =~ s/<!--Data\.$field-->/$Data->{$field}/;
            }
         }elsif($line =~ m/<!--ThisUser\.(\w+)-->/){
            my $field = $1;
            my $value = $self->{UserManager}->{ThisUser}->{$field};
            $line =~ s/<!--ThisUser\.$field-->/$value/;
         }elsif($line =~ m/<!--ListOwner\.(\w+)-->/){
            my $field = $1;
            my $value = $self->{PageOwner}->{$field};
            $line =~ s/<!--ListOwner\.$field-->/$value/;
         }elsif($line =~ m/<!--SETUP\.([\w_]+)-->/){
            my $variable = $1;
            $line =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/;
         }elsif($line =~ m/<!--Self\.([\w\.]+)-->/g){
            
            my $variable = $1;
            if($variable =~ m/ErrorMessages/ && $self->{$variable}){
               $self->{$variable} = "<p class=\"error\">$self->{$variable}</p>";
            }
            #$self->{Debugger}->debug("Matched Self - $variable");
            $line =~ s/<!--Self\.$variable-->/$self->{$variable}/g;
         }elsif($line =~ m/<!--CGI\.([\w\.]+)-->/){
            my $field = $1;
            my $value = $self->{cgi}->{$field};
            $self->{Debugger}->debug("From CGI: $field -> $value");
            $line =~ s/<!--CGI\.$field-->/$value/;
         }elsif($line =~ m/<!--ErrorMessages-->/){
            if($self->{ErrorMessages}){
               $self->{ErrorMessages} = "<p class=\"error\">$self->{ErrorMessages}</p>";
            }
            $line =~ s/<!--ErrorMessages-->/$self->{ErrorMessages}/;
         }elsif($line =~ m/<!--GetOutputFromFunc\.(\w+)-->/){
            my $params = $1;
            my ($func, $param) = split("_", $params);
            #my $func = $1;
            my $output = $self->$func($param);
            $line =~ s/<!--GetOutputFromFunc\.$params-->/$output/;
         }elsif($line =~ m/<!--Display\.Page\.(.+)-->/){
            # Display.Page.PathttoPageNameFromDocRoot
            my $page = $1;
            my $file = "$Lists::SETUP::DIR_PATH/$page";
            my $content = $self->getPage($file);
            $line =~ s/<!--Display\.Page\.$page-->/$content/;
         }elsif($line =~ m/<!--Adserver\.(\w+)\.(.+)-->/){
            my $todo = $1;
            my $extra = $2;
            my $input = $self->{AdServer}->$todo($extra);
            $line =~ s/<!--Adserver\.$todo\.$extra-->/$input/;
         }elsif($line =~ m/<!--Input\.(.+)-->/){
            my $input = $self->getInputHTMLTag($line);
            $line =~ s/<!--Input\.$1-->/$input/;
         }elsif($line =~ m/<!--Select\.(\w+)-->/){
            # This should be from the create list form
            my $table = $1;
            my $List = $Data->{"List"};
            $self->{Debugger}->debug("Found Select Tag ListID -> $List->{ID}");
            my $select = $self->getSelectTag($table, $List);
            $line =~ s/<!--Select\.$table-->/$select/;
         }elsif($line =~ m/<!--FailImage-->/){
            use Lists::Utilities::Fail;
            my $Fail = new Lists::Utilities::Fail(Debugger=>$self->{Debugger});
            my $FailImage = $Fail->getFailImage();
            $line =~ s/<!--FailImage-->/$FailImage/;
         }elsif($line =~ m/<!--List\.(\w+)-->/){
            my $field = $1;
            $line =~ s/<!--List\.$field-->/$self->{ThisList}->{$field}/;
         }elsif($line =~ m/<!--ListQ\.(\w+)-->/){
            # If we need to handle the quotes for javascript
            my $field = $1;
            my $value = $self->{ThisList}->{$field};
            $value =~ s/\'/\\\'/g;
            $line =~ s/<!--ListQ\.$field-->/$value/;
         }elsif($line =~ m/<!--Debug-->/){
            $line =~ s/<!--Debug-->/$self->{Debugger}->{DebugMessages}/;
         }elsif($line =~ m/<!--PageTitle-->/){
            $isPageTitle = 1;
            if(!$self->{PageTitle}){
               $self->{PageTitle} = $self->getPageTitle();
            }
            $line =~ s/<!--PageTitle-->/$self->{PageTitle}/;
         }elsif($line =~ m/<!--ErrorMessages-->/){
            if($self->{ErrorMessages}){
               $self->{ErrorMessages} = "<p class=\"error\">$self->{ErrorMessages}</p>";
            }
            $line =~ s/<!--ErrorMessages-->/$self->{ErrorMessages}/;
         }elsif($line =~ m/<!--GetOutputFromFunc\.(\w+)-->/){
            my $func = $1;
            my $output = $self->$func();
            $line =~ s/<!--GetOutputFromFunc\.$func-->/$output/;
         }elsif($line =~ m/<!--Editor\.(\w+)-->/){
            my $func = $1;
            my $output = $self->{Editor}->$func();
            $line =~ s/<!--Editor\.$func-->/$output/;
         }elsif($line =~ m/<!--DBObj\.(\w+)\.(\w+)-->/){
            my $table = $1;
            my $func = $2;
            my $tableObj = $self->{DBManager}->getTableObj($table);
            my $content = $tableObj->$func($self->{DBManager});
            $line =~ s/<!--DBObj\.$table\.$func-->/$content/;
         }elsif($line =~ m/<!--ReCaptcha-->/){
            use Lists::Utilities::ReCaptcha;
            my $reCaptchaObj = new Lists::Utilities::ReCaptcha("Debugger" => $self->{Debugger});
            my $reCatpcha = $reCaptchaObj->getReCaptchaHTML();
            $line =~ s/<!--ReCaptcha-->/$reCatpcha/;
         }elsif($line =~ m/<!--Select\.(\w+)-->/){
            # This should be from the create list form
            my $table = $1;
            my %Empty = ();
            my $select = $self->getSelectTag($table, $self->{ThisList});
            $line =~ s/<!--Select\.$table-->/$select/;
         }elsif($line =~ m/<!--ThisUser.Select\.(\w+)-->/){
            # This should be from the create list form
            my $table = $1;
            my $select = $self->getThisUserSelectTag($table);
            $line =~ s/<!--ThisUser.Select\.$table-->/$select/;
         }elsif($line =~ m/<!--DisplaySettingsTab\.(\w+)-->/){
            my $tab = $1;
            my $style = "display:none";
            if($self->{SettingsTab}->{$tab}){
               $style = "display:block";
            }            
            $line =~ s/<!--DisplaySettingsTab.$tab-->/$style/;
         }elsif($line =~ m/<!--NavOnSettingsTab\.(\w+)-->/){
            my $tab = $1;
            my $classAddition = "";
            if($self->{SettingsTab}->{$tab}){
               $classAddition = "On";
            }            
            $line =~ s/<!--NavOnSettingsTab.$tab-->/$classAddition/;
         }elsif($line =~ m/<!--DisplayCreateEditTab\.(\w+)-->/){
            my $tab = $1;
            my $style = "display:none";
            if($self->{"CreateEditTab"}->{$tab}){
               $style = "display:block";
            }            
            $line =~ s/<!--DisplayCreateEditTab.$tab-->/$style/;
         }elsif($line =~ m/<!--NavOnCreateEditTab\.(\w+)-->/){
            my $tab = $1;
            my $classAddition = "";
            if($self->{CreateEditTab}->{$tab}){
               $classAddition = "On";
            }            
            $line =~ s/<!--NavOnCreateEditTab.$tab-->/$classAddition/;
         }elsif($line =~ m/<!--DB\.(\w+)\.(\w+)\.(.+)-->/){
            my $table = $1;
            my $field = $2;
            my $last = $3;
            my $ID = $last;
            if($ID eq "LoggedInUser"){
               $ID = $self->{UserManager}->{ThisUser}->{ID};
            }elsif("UserID"){
               $ID = $self->{cgi}->{UserID};
            }
            if($ID){
               my $TableObj = $self->{DBManager}->getTableObj($table);
               my $value = $TableObj->get_field_by_ID($field, $ID);
               if($field =~ m/Date/){
                  my $dateFormatted = Lists::Utilities::Date::getHumanFriendlyDate($value);
                  $line =~ s/<!--DB\.$table\.$field\.$last-->/$dateFormatted/;
               }else{
                  $line =~ s/<!--DB\.$table\.$field\.$last-->/$value/;
               }
            }else{
               $line =~ s/<!--DB\.$table\.$field\.$last-->//;
            }
         }elsif($line =~ m/<!--ListDivDisplay\.(\w+)-->/){
            my $div = $1;
            if($self->{cgi}->{"ListDivDisplay"} eq ""){
               $self->{cgi}->{"ListDivDisplay"} = "ListNormalView";
            }
            if($self->{cgi}->{"ListDivDisplay"} eq $div){
               $line =~ s/<!--ListDivDisplay\.$div-->//;
            }else{
               $line =~ s/<!--ListDivDisplay\.$div-->/style="display:none"/;
            }
         }elsif($line =~ m/<!--Display\.ListElement\.(.+)-->/){
            # Display.Page.PathttoPageNameFromDocRoot
            my $page = $1;
            my $file = "$Lists::SETUP::DIR_PATH/listpieces/$page";
            my $content = $self->getListElement($file, $self->{List});
            $line =~ s/<!--Display\.ListElement\.$page-->/$content/;
         }elsif($line =~ m/<!--ContactEmail-->/){
            my $email = "";
            if($self->{UserManager}->{ThisUser}->{Email}){
               $email = $self->{UserManager}->{ThisUser}->{Email};
            }elsif($self->{DeactivatedEmail}){
               $email = $self->{DeactivatedEmail};
            }
            my $html = qq~<div><label>Email:</label><input type="text" name="Feedback.Email" value="$email" class="TextInput" /></div>~;
            $line =~ s/<!--ContactEmail-->/$html/;
         }elsif($line =~ m/<!--GoogleAnalytics-->/){
            use Lists::Utilities::GoogleAnalytics;
            my $code = Lists::Utilities::GoogleAnalytics::getCode();
            $line =~ s/<!--GoogleAnalytics-->/$code/;
         }elsif($line =~ m/<!--CurrentDate-->/){
            my $date = Lists::Utilities::Date::getFullHumanFriendlyDate(time());
            $line =~ s/<!--CurrentDate-->/$date/;
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


=head2 Post Functions from CGI->{todo}

=head2 AddList

Adds a new list 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddList {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddList");

   if($self->{cgi}->{"List.Name"} eq ""){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'BLANK_LIST_NAME'};   
      $self->{"DisplayCreateListForm"} = 1;
      $self->{CreateEditTab}->{CreateList} = 1;
      my $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/create_and_edit.html");
      return $content;
   }

   $self->{cgi}->{"List.Name"} = Lists::Utilities::StringFormator::htmlEncode($self->{cgi}->{"List.Name"});

   $self->{cgi}->{"List.UserID"} = $self->{UserManager}->{ThisUser}->{ID};
   if(! $self->{cgi}->{"List.ListTypeID"}){
      $self->{cgi}->{"List.ListTypeID"} = 1;
   }   
   $self->{cgi}->{"List.Status"} = 1;
   $self->{cgi}->{"List.Public"} = 0;

   my $content;
   my $ListID = $self->{ListObj}->store($self->{cgi});
   if($ListID =~ m/\D+/){
      # Error!
      $self->{ErrorMessage} = $ListID;
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
   }else{
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
      $self->{cgi}->{"ListID"} = $ListID;
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }

   return $content;
}


=head2 AddListItem

Ass a new ListItem

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListItemid - The list item to get updated

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddListItem {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddListItem");

   if(! $self->{cgi}->{"ListID"}){
      $self->{cgi}->{"ListID"} = $self->{cgi}->{"ListItem.ListID"};
   }
   if(! $self->{cgi}->{"ListID"}){
      $self->{Debugger}->throwNotifyingError("List Item adding with no list ID!");
      $self->{ErrorMessagesALI} = $Lists::SETUP::MESSAGES{'MISC'};
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   
   $self->{cgi}->{"ListItem.Name"} = Lists::Utilities::StringFormator::htmlEncode($self->{cgi}->{"ListItem.Name"});
   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListItem.ListID"});

   # Check for user owns this list!
   if(! $self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
      $self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} trying to add to list #List->{ID}!");
      $self->{ErrorMessagesALI} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   my $content = "";
   if(!$self->{cgi}->{"ListItem.Name"}){
      $self->{ErrorMessagesALI} = $Lists::SETUP::MESSAGES{'BLANK_LIST_ITEM'};
      #$content = $self->getListHTML($self->{cgi}->{"ListItem.ListID"});
   }

   if($self->{ErrorMessagesALI} eq ""){
      # First check that the list is not over the limit
      my $ListID = $self->{cgi}->{"ListID"};
      my $ListItemCount = $self->{ListItemObj}->get_count_with_restraints("ListID = $ListID");

      if($ListItemCount >= $Lists::SETUP::CONSTANTS{'LIST_ITEM_LIMIT'}){
         $self->{ErrorMessagesALI} = $Lists::SETUP::MESSAGES{'AT_LIST_ITEM_LIMIT'};
      }else{
         # Save the List Item!

         # There should only be one of these list item extras
         if($self->{cgi}->{"ListItem.ASIN"}){
            # Create Amazon link 
            my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager}, 
                                                   UserManager => $self->{UserManager});
            $self->{cgi}->{"ListItem.AmazonID"} = $Amazon->saveAmazonLink($self->{cgi});

            if($self->{cgi}->{"ListItem.AmazonID"} =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessagesALI} = $self->{cgi}->{"ListItem.AmazonID"};
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }
                        
         }elsif($self->{cgi}->{"ListItem.CCImage"}){
            my $CCImageObj = $self->{DBManager}->getTableObj("CCImage");
            $self->{cgi}->{"ListItem.CCImageID"} = $CCImageObj->saveCCImage($self->{cgi});

            if($self->{cgi}->{"ListItem.CCimageID"} =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessagesALI} = $self->{cgi}->{"ListItem.CCImageID"};
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }

         }elsif($self->{cgi}->{"ListItem.Embed"}){
            my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
            $self->{cgi}->{"ListItem.EmbedID"} = $EmbedObj->saveEmbed($self->{cgi});

            if($self->{cgi}->{"ListItem.EmbedID"} =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessagesALI} = $self->{cgi}->{"ListItem.EmbedID"};
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }
            
         }elsif($self->{cgi}->{"ListItem.ImageID"}){
            # There is an image, update the image with the List Item Name for the alt
            my $ImageObj = $self->{DBManager}->getTableObj("Image");
            $ImageObj->update("Alt", $self->{cgi}->{"ListItem.Name"}, $self->{cgi}->{"ListItem.ImageID"});
         }

         if($self->{cgi}->{"ListItem.Link"}){
            $self->{cgi}->{"ListItem.LinkID"} = $self->{LinkObj}->saveLink($self->{cgi}->{"ListItem.Link"});
            
            if($self->{cgi}->{"ListItem.LinkID"} =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessagesALI} = $self->{cgi}->{"ListItem.LinkID"};
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }
         }

         if($self->{cgi}->{"ListItem.Date"}){
            # Do the date stuff here!
            my $DateObj = $self->{DBManager}->getTableObj("Date");
            $self->{cgi}->{"ListItem.DateID"} = $DateObj->saveDate($self->{cgi}, $self->{UserManager}->{ThisUser}->{ID});
            if($self->{cgi}->{"ListItem.DateID"} =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessagesALI} = $self->{cgi}->{"ListItem.LinkID"};
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }
         }
         
         if(!$self->{cgi}->{"ListItem.ListItemStatusID"}){
            $self->{cgi}->{"ListItem.ListItemStatusID"} = $self->{ListItemStatusObj}->getInitialStatus($List->{StatusSet});
         }
         $self->{cgi}->{"ListItem.Status"} = 1;
         my $MaxPlaceInOrder = $self->{ListItemObj}->getMaxPlaceInOrder($self->{cgi}->{"ListID"}, $self->{cgi}->{"ListItem.ListItemStatusID"});
         $self->{cgi}->{"ListItem.PlaceInOrder"} = $MaxPlaceInOrder + 1;
         $self->{Debugger}->debug("MaxPlaceInOrder: $MaxPlaceInOrder, " .$self->{cgi}->{"ListItem.PlaceInOrder"});
         my $ListItemID = $self->{ListItemObj}->store($self->{cgi});
         if($ListItemID =~ m/\D+/){
            # Error!
            $self->{ErrorMessage} = $ListItemID;
            return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
         }

         my $ListID = $self->{cgi}->{"ListItem.ListID"};
         # Clear cgi for failed pre-pop
         foreach my $field (keys %{$self->{cgi}}){
            if($field =~ m/ListItem/){
               $self->{cgi}->{$field} = "";
            }
         }   
      }      
   }

   $self->{ListObj}->update("LastActiveDate", time(), $List->{ID});

   $content = $self->getListHTML($self->{cgi}->{"ListID"});

   # If the form submitted because of a file upload
   if($self->{cgi}->{ajax}){
      return $content;   
   }else{
      $self->{ListsContent} = $content;
      $self->{cgi}->{UserID} = $List->{UserID};
      $self->{ListGroupSlideOpen} = $List->{ListGroupID};
      return $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }
}

=head2 AddFeedback

Adds a new feedback entry from a user's use of the list central contact form

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddFeedback {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddFeedback");

   use Net::Akismet;
   my $spamchecker = 1;
   my $akismet = Net::Akismet->new(
                        KEY => '5248d5060124',
                        URL => $Lists::SETUP::URL,
                ) or $spamchecker = 0;


   if($spamchecker){
      my $verdict = $akismet->check(
                        USER_IP                 => $ENV{'REMOTE_ADDR'},
                        COMMENT_USER_AGENT      => $ENV{HTTP_USER_AGENT},
                        COMMENT_CONTENT         => $self->{cgi}->{"Feedback.Message"},
                        REFERRER                => $ENV{HTTP_REFERER}
                );

      if($verdict eq 'true'){
         $self->{cgi}->{"Feedback.Spam"} = 1;
      }else{
         $self->{cgi}->{"Feedback.Spam"} = 0;
      }
      
   }else{
      $self->{cgi}->{"Feedback.Spam"} = 0;
   }


   if($self->{cgi}->{"Feedback.FeedbackTypeID"} eq ""){
      $self->{cgi}->{"Feedback.FeedbackTypeID"} = 1;
   }

   $self->{cgi}->{"Feedback.ReportingUserID"} = $self->{UserManager}->{ThisUser}->{ID};
   $self->{cgi}->{"Feedback.FeedbackStatusID"} = 1;

   if($self->{cgi}->{"Feedback.ProblematicListID"}){
      my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{"Feedback.ProblematicListID"});
      $self->{cgi}->{"Feedback.ProblematicUserID"} = $List->{UserID};
   }
   $self->{cgi}->{"Feedback.Status"} = 1;
   $self->{cgi}->{"Feedback.IP"} = $ENV{'REMOTE_ADDR'};

   my $FeedbackObj = $self->{DBManager}->getTableObj("Feedback");
   my $FeedbackID = $FeedbackObj->store($self->{cgi});
   if($FeedbackID =~ m/\D+/){
      # Error!
      $self->{ErrorMessage} = $FeedbackID;
      return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
   }else{
      if(!$self->{cgi}->{"Feedback.Spam"}){
         $self->sendFeedbackNotify();
      }      
   
      my $content;
      if($self->{cgi}->{ajax}){
         $content = $self->getPage("$Lists::SETUP::DIR_PATH/thankyou.html");
      }else{
         $content = $self->processPage("$Lists::SETUP::DIR_PATH/thankyou.html");
      }
      
      return $content;
   }   
}

=head2 AddListTag

Add a new ListTag

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListItemid - The list item to get updated

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddListTag {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddListTag");

   my $TagObj = $self->{DBManager}->getTableObj("Tag");

   my $ListID = $self->{cgi}->{'ListID'};
   my $TagName = $self->{cgi}->{'Tag'};

   if(! $TagName){
      $self->{ErrorMessagesAT} .= $Lists::SETUP::MESSAGES{'BLANK_TAG'};
      my ($TagHTML, $TagCount, $Tags) = $TagObj->getListTags($ListID, $self->{DBManager}, $self->{cgi}->{ajax});
      return "<p class='error'>$self->{ErrorMessagesAT}</p><br />" . $TagHTML;
   }elsif($TagName =~ m/[^a-z0-9,\s_-]/i){
      $self->{ErrorMessagesAT} .= $Lists::SETUP::MESSAGES{'DISALLOWED_CHARACTERS'};
      my ($TagHTML, $TagCount, $Tags) = $TagObj->getListTags($ListID, $self->{DBManager}, $self->{cgi}->{ajax});
      return "<p class='error'>$self->{ErrorMessagesAT}</p><br />" . $TagHTML;
   }
   my @Tags = split(",", $TagName);

   my $TagObj = $self->{DBManager}->getTableObj("Tag");

   foreach my $tagname (@Tags) {
      # Strip leading and trailing spaces
      $tagname =~ s/^\s+//; $tagname =~ s/\s+$//;
      
      my $Tag = $TagObj->get_by_field("Name", $tagname);
      if($Tag){
         # Up the ListTag Count
         my $TagCount = $Tag->{TagCount} + 1;
         $TagObj->update("TagCount", $TagCount, $Tag->{ID});
   
         # Store the ListTagEntry
         my %ListTag;
         $ListTag{"ListTag.ListID"} = $ListID;
         $ListTag{"ListTag.TagID"} = $Tag->{ID};
         $ListTag{"ListTag.Status"} = 1;
         my $ListTagObj = $self->{DBManager}->getTableObj("ListTag");
         my $ListTagID = $ListTagObj->store(\%ListTag);
         if($ListTagID =~ m/\D+/){
            # Error!
            $self->{ErrorMessage} = $ListTagID;
         }
      }else{
         # Store the Tag
         my %Tag;
         $Tag{"Tag.Name"} = $tagname;
         $Tag{"Tag.TagCount"} = 1;
         $Tag{"Tag.CreatedByUserID"} = $self->{UserManager}->{ThisUser}->{ID};
         $Tag{"Tag.Status"} = 1;
         my $TagID = $TagObj->store(\%Tag);
         if($TagID =~ m/\D+/){
            # Error!
            $self->{ErrorMessage} = $TagID;
         }
   
         # Store the ListTagEntry
         my %ListTag;
         $ListTag{"ListTag.ListID"} = $ListID;
         $ListTag{"ListTag.TagID"} = $TagID;
         $ListTag{"ListTag.Status"} = 1;
         my $ListTagObj = $self->{DBManager}->getTableObj("ListTag");
         my $ListTagID = $ListTagObj->store(\%ListTag);
         if($ListTagID =~ m/\D+/){
            # Error!
            $self->{ErrorMessage} = $ListTagID;
         }
      }
   }

   if($self->{ErrorMessage}){
      return "<p class='error'>$self->{ErrorMessages}</p>";
   }else{
      my ($TagHTML, $TagCount, $Tags) =  $TagObj->getListTags($ListID, $self->{DBManager}, $self->{cgi}->{ajax});
      return "<p>" . $TagHTML . "</p>";
   }
}

=head2 AddListComment

Add a new ListComment

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddListComment {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddListComment");

   # This Error message isn't going to be displayed with the current set up
   if(! $self->{cgi}->{'Comment'}){
      $self->{"ErrorMessagesAC"} .= $Lists::SETUP::MESSAGES{'BLANK_COMMENT'};
      my $Comments = $self->getListComments($self->{cgi}->{'ListID'});
      return "<p class='error'>$self->{'ErrorMessagesAC'}</p><br /><br />$Comments";
   }

   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{"ErrorMessagesAC"} .= $Lists::SETUP::MESSAGES{'NO_ONE_LOGGED_IN_COMMENT'};
      my $Comments = $self->getListComments($self->{cgi}->{'ListID'});
      return "<p class='error'>$self->{'ErrorMessagesAC'}</p><br /><br />$Comments";
   }

   my $ListID = $self->{cgi}->{'ListID'};
   my $List = $self->{ListObj}->get_by_ID($ListID);

   my $CommenterID;
   my $Commenter = "Anonymous";
   if($self->{UserManager}->{ThisUser}->{ID}){
      my $UserObj = $self->{DBManager}->getTableObj("User"); 
      $Commenter = $UserObj->get_field_by_ID('Username', $self->{UserManager}->{ThisUser}->{ID});
      $CommenterID = $self->{UserManager}->{ThisUser}->{ID};
   }elsif($self->{cgi}->{'Commenter'}){
      $Commenter = $self->{cgi}->{'Commenter'};
   }

   my $CommentObj = $self->{DBManager}->getTableObj("Comment");

   # Store the Comment
   my %Comment;
   $Comment{"Comment.Comment"} = $self->{cgi}->{'Comment'};
   $Comment{"Comment.Commenter"} = $Commenter;
   $Comment{"Comment.CommenterID"} = $CommenterID;
   $Comment{"Comment.ListID"} = $ListID;
   $Comment{"Comment.Status"} = 1;
   my $CommentID = $CommentObj->store(\%Comment);
   if($CommentID =~ m/\D+/){
      # Error!
      $self->{"ErrorMessagesAC"} = $CommentID;
      my $Comments = $self->getListComments($self->{cgi}->{'ListID'});
      return "<p class='error'>$self->{'ErrorMessagesAC'}</p><br /><br />$Comments";
   }

   $self->{ListObj}->update("LastActiveDate", time(), $ListID);

   # Add the message
   my %Message;
   $Message{"Messages.UserID"} = $List->{UserID};
   $Message{"Messages.Action"} = 1;
   $Message{"Messages.DoerID"} = $CommenterID;
   $Message{"Messages.Seen"} = 0;
   $Message{"Messages.Status"} = 1;
   $Message{"Messages.SubjectID"} = $ListID;
   my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
   my $MessageID = $MessagesObj->store(\%Message);

   if($List->{UserID} != $self->{UserManager}->{ThisUser}->{ID}){
      my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
      my $UserSettings = $UserSettingsObj->getByUserID($List->{UserID});
      if($UserSettings->{ReceiveNotifications}){
         $self->sendNotificationEmail($MessageID);
      }
   }

   # The theme must be set as per the owner of the list, not the commenter
   $self->{cgi}->{UserID} = $List->{UserID};

   my $Comments = $self->getListComments($ListID);
   return $Comments;
}


=head2 AddListGroup

Adds a new ListGroup

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddListGroup {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddListGroup");

   $self->{cgi}->{"ListGroup.Status"} = 1;
   $self->{cgi}->{"ListGroup.UserID"} = $self->{UserManager}->{ThisUser}->{ID};
   my $ListGroupID = $self->{ListGroupObj}->store($self->{cgi});
   if($ListGroupID =~ m/\D+/){
      # Error!
      $self->{ErrorMessages} = $ListGroupID;
   }

   $self->{cgi}->{"UserID"} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();

   $self->{"CreateEditTab"}->{"CreateList"} = 1;
   $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/create_and_edit.html";
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 AddNotifyOfAlphaRelease

Adds a new entry in the notify of alpha release table

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddNotifyOfAlphaRelease {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddNotifyOfAlphaRelease");

   my $AlphaNotifyObj = $self->{DBManager}->getTableObj("AlphaNotify");

   my $content;
   $self->{cgi}->{"AlphaNotify.Status"} = 1;
   my $AlphaNotifyID = $AlphaNotifyObj->store($self->{cgi});
   if($AlphaNotifyID =~ m/\D+/){
      # Error!
      $self->{ErrorMessages} = $AlphaNotifyID;
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }else{
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/notify_thanks.html");
   }

   return $content;
}

=head2 AddStatusSet

Adds a new Status Set to be used by the user creating it only 

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddStatusSet {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddStatusSet");

   my @Statuses = split(',', $self->{cgi}->{'StatusSet'});

   if(!scalar(@Statuses)){
      # There is not even one status

      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'INVALID_STATUS_SET'};   
      $self->{"DisplayCreateEditForm"} = 1;
      my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
      return $content;
   }

   # Get the next Status Set ID
   my $ListItemStatusSetObj = $self->{DBManager}->getTableObj('ListItemStatus');
   my $NextStatusSetID = $ListItemStatusSetObj->getNextStatusSetID();

   foreach my $status(@Statuses) {
      $status =~ s/^\s+//;
      $status =~ s/\s+$//;
      $self->{Debugger}->debug("Cleaned Status : $status");

      $self->{cgi}->{"ListItemStatus.Status"} = 1;
      $self->{cgi}->{"ListItemStatus.Name"} = $status;
      $self->{cgi}->{"ListItemStatus.StatusSet"} = $NextStatusSetID;
      $self->{cgi}->{"ListItemStatus.UserID"} = $self->{UserManager}->{ThisUser}->{ID};

      my $ListItemStatusID = $self->{ListItemStatusObj}->store($self->{cgi});
      if($ListItemStatusID =~ m/\D+/){
         # Error!
         $self->{ErrorMessages} = $ListItemStatusID;
      }
   }

   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   $self->{"CreateEditTab"}->{"CreateList"} = 1;
   $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/create_and_edit.html";
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 AddUser

Adds a new User, via the sign up process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub AddUser {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->AddUser");

   use Lists::Utilities::Mailer;
   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
   my $ErrorMessage = $self->{UserManager}->addUser($Mailer);

   my $content;  
   if($ErrorMessage eq "BETA"){
      $ErrorMessage = "";
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/notify.html");
   }elsif($ErrorMessage ne ""){
      $self->{SignUpErrorMessages} = $ErrorMessage;
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/signup.html");
   }else{
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
      $self->{UserManager}->{UserObj}->clearCache($self->{UserManager}->{ThisUser}->{ID});
      $self->{UserManager}->{ClearCache} = 1;
      $self->{UserManager}->getThisUserInfo();
      $self->{UserManager}->{ThisUser}->{Password} = $self->{cgi}->{"User.Password"};


      #foreach (keys %{$self->{UserManager}->{ThisUser}}) {
      #   $self->{Debugger}->debug("This user: $_ -> $self->{UserManager}->{ThisUser}->{$_}");
      #}

      $self->sendWelcomeEmail($self->{UserManager}->{ThisUser}, $Mailer);

      my $UsernameHistoryObj = $self->{DBManager}->getTableObj("UsernameHistory");
      my %UsernameHistory = ("UsernameHistory.Username" =>  $self->{UserManager}->{ThisUser}->{Username},
                             "UsernameHistory.UserID" => $self->{UserManager}->{ThisUser}->{ID},
                             "UsernameHistory.Status" => 1);
      $UsernameHistoryObj->store(\%UsernameHistory);

      $self->{PageTitle}= "lc: lists by $self->{cgi}->{'User.Name'}";
      $self->{MessageToUser} = $self->processPage("$Lists::SETUP::DIR_PATH/loggedin/welcome.html");
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }

   return $content;
}

=head2 DeactivateAccount

Deactivates an account

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the deactivated account page

=back

=cut

#############################################
sub DeactivateAccount {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->DeactivateAccount, $self->{UserManager}->{ThisUser}->{ID} logged in");

   my $content = "";
   if($self->{UserManager}->{ThisUser}->{ID}){
      my $hashedCGIPassword = $self->{UserManager}->encryptPassword($self->{cgi}->{'PasswordVerifyHidden'});
      my $hashedPassword = $self->{UserManager}->getUsersEncryptedPassword($self->{UserManager}->{ThisUser}->{ID});
      if($hashedCGIPassword eq $hashedPassword){
         my $UserObj = $self->{DBManager}->getTableObj("User");
         my $User = $UserObj->get_by_ID($self->{UserManager}->{ThisUser}->{ID});
         $self->{DeactivatedEmail} = $User->{Email};
         $UserObj->update("Status", 0, $self->{UserManager}->{ThisUser}->{ID});
         $self->{UserManager}->doLogout();
         $content = $self->processPage("$Lists::SETUP::DIR_PATH/deactivate.html");
      }else{
         $self->{ErrorMessagesEBI} = $Lists::SETUP::MESSAGES{'FAIL_PASSWORD_EDIT_ACCOUNT'};
         $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
         $self->setThemeID();
         $self->{SettingsTab}->{BasicInfo} = 1;
         $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/settings.html";
         $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
      }      
   }else{
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/index.html");
   }   

   return $content;
}

=head2 DeleteList

Deletes a List

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteList {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteList Logged in user: $self->{UserManager}->{ThisUser}->{ID}");

   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});
   my $OwnerOfList = $List->{UserID};

   $self->{cgi}->{"UserID"} = $List->{UserID};
   $self->{cgi}->{"ListID"} = 0;
   $self->setThemeID();

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfList){
      $self->{ListObj}->update('Status', 0, $List->{ID});

      # Update the messages
      my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
      my $Messages = $MessagesObj->get_with_restraints("Action = 1 AND SubjectID = $List->{ID}");
      foreach my $id (keys %{$Messages}) {
         $MessagesObj->update('Status', 0, $id);
      }
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }else{
      $self->{ErrorMessages} = "You don't have permission to delete that list";
      $self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} tried to delete a list($List->{ID}) that isn't theirs ");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}

=head2 DeleteListGroup

Deletes a List Group

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteListGroup {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteListGroup");

   # Check that the logged in user owns this list group
   my $ListGroup = $self->{ListGroupObj}->get_by_ID($self->{cgi}->{"ListGroupID"});
   my $OwnerOfListGroup = $ListGroup->{UserID};

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfListGroup){
      $self->{ListGroupObj}->update('Status', 0, $self->{cgi}->{"ListGroupID"});

      $self->{ListObj}->changeListGroupToUncategorized($self->{cgi}->{"ListGroupID"}, $self->{UserManager}->{ThisUser}->{ID});

      $self->{cgi}->{UserID} = $ListGroup->{UserID};
      $self->setThemeID();
      $self->{"CreateEditTab"}->{"ListGroups"} = 1;
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/create_and_edit.html");
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_DELETE_GROUP'};
      $self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} tried to delete a listgroup($self->{cgi}->{ListGroupID}) that isn't theirs ");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}

=head2 DeleteListItem

Deletes a List Item

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteListItem {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteListItem");

   # Check that the logged in user owns this list group
   my $ListItem = $self->{ListItemObj}->get_by_ID($self->{cgi}->{"ListItemID"});
   my $List = $self->{ListObj}->get_by_ID($ListItem->{ListID});
   my $OwnerOfListItem = $List->{UserID};

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfListItem){
      $self->{ListItemObj}->update('ListItemStatusID', 0, $self->{cgi}->{"ListItemID"});

      $self->{cgi}->{ListID} = $List->{ID};
      $self->{cgi}->{UserID} = $List->{UserID};
      $self->{cgi}->{"ListDivDisplay"} = "ListNormalView";
      $content = $self->getListHTML($List->{ID});
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_DELETE_ITEM'};
      $self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} tried to delete a listitem($self->{cgi}->{ListItemID}) that isn't theirs ");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}


=head2 DeleteListTags

Deletes all the list tags for the list in cgi->{ListID}

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteListTags {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteListTags");

   my $TagObj = $self->{DBManager}->getTableObj("Tag");
   my $ListTagObj = $self->{DBManager}->getTableObj("ListTag");

   # First get the list tags so we can reduce tag count in tag
   my $ListTags = $ListTagObj->get_with_restraints("ListID = $self->{cgi}->{'ListID'}");
   foreach my $ListTagID(keys %{$ListTags}) {
      $TagObj->reduceTagCount($ListTags->{$ListTagID}->{TagID});
   }

   # Now delete the tags
   $ListTagObj->deleteListTagsByList($self->{cgi}->{"ListID"});

   my ($TagHTML, $TagCount, $Tags) = $TagObj->getListTags($self->{cgi}->{"ListID"}, $self->{DBManager}, $self->{cgi}->{ajax});
   return $TagHTML;
}


=head2 DeleteStatusSet

Deletes a List Group

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteStatusSet {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteStatusSet");

   # Check that the logged in user owns this status set
   my $ListItemStatuses = $self->{ListItemStatusObj}->get_with_restraints("StatusSet = $self->{cgi}->{StatusSetID}");

   my $OwnerOfStatusSet;
   foreach my $ID(keys %{$ListItemStatuses}) {
      $OwnerOfStatusSet = $ListItemStatuses->{$ID}->{UserID};
      last;
   }

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfStatusSet){
      foreach my $ID(keys %{$ListItemStatuses}) {
         $self->{ListItemStatusObj}->update('Status', 0, $ID);
         $self->{ListItemObj}->changeListItemsStatusToNone($ID, $self->{UserManager}->{ThisUser}->{ID}, $self->{ListItemStatusObj});
      }
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
      $self->setThemeID();
      $self->{"CreateEditTab"}->{"StatusSets"} = 1;
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/create_and_edit.html");
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_DELETE_STATUS_SET'};
      $self->{Debugger}->throwNotifyingError("User $self->{UserManager}->{ThisUser}->{ID} tried to delete a status set($self->{cgi}->{StatusSetID}) that isn't theirs ");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}

=head2 DeleteBoardPost

Deletes a Board Post

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteBoardPost {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteBoardPost");

   # Check that the logged in user owns either the board or the comment
   my $BoardObj = $self->{DBManager}->getTableObj("Board");
   my $BoardPost = $BoardObj->get_by_ID($self->{cgi}->{"BoardPostID"});
   my $OwnerOfBoard = $BoardPost->{UserID};
   my $OwnerOfBoardPost = $BoardPost->{PosterUserID};

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfBoard || $self->{UserManager}->{ThisUser}->{ID} == $OwnerOfBoardPost){
      $BoardObj->update('Status', 0, $self->{cgi}->{"BoardPostID"});

      # Update the messages
      my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
      my $Messages = $MessagesObj->get_with_restraints("Action = 2 AND SubjectID = $self->{cgi}->{BoardPostID}");
      foreach my $id (keys %{$Messages}) {
         $MessagesObj->update('Status', 0, $id);
      }

      $self->{cgi}->{UserID} = $BoardPost->{UserID};
      $self->setThemeID();
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/users_space.html");
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_DELETE_BOARD_POST'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to delete board post ($self->{cgi}->{BoardPostID}) they should");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}

=head2 DeleteComment

Deletes a List Group

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub DeleteComment {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::DeleteComment");

   # Check that the logged in user owns this list or comment
   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $Comment = $CommentObj->get_by_ID($self->{cgi}->{"CommentID"});
   my $OwnerOfComment = $Comment->{CommenterID};
   my $List = $self->{ListObj}->get_by_ID($Comment->{ListID});
   my $OwnerOfList = $List->{UserID};

   my $content;
   if($self->{UserManager}->{ThisUser}->{ID} == $OwnerOfComment || $self->{UserManager}->{ThisUser}->{ID} == $OwnerOfList){
     $CommentObj->update('Status', 0, $self->{cgi}->{"CommentID"});
     $self->{cgi}->{UserID} = $OwnerOfList;
     $self->{cgi}->{ListID} = $Comment->{ListID};
     $self->setThemeID();
     $content = $self->getListComments($List->{ID});
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_DELETE_COMMENT'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to delete comment ($self->{cgi}->{CommentID}) they should");
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   return $content;
}

=head2 EditAvatar

Handles the edit avatar process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditAvatar {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditAvatar");

   $self->{ErrorMessagesEA} = "";

   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings"); 
   my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});

   if($self->{cgi}->{ImageID}){
      my $ImageObj = $self->{DBManager}->getTableObj("Image"); 
      my $ImageID = $self->{cgi}->{ImageID};
      my $Image = $ImageObj->get_by_ID($ImageID);   
      my $path = $self->{UserManager}->getUsersDirectory($self->{UserManager}->{ThisUser}->{ID});
      my $imageSrc = $Image->{ID} . "A." . $Image->{Extension};
      $UserSettingsObj->update("Avatar", $imageSrc, $UserSettings->{ID});
      $self->{ErrorMessagesEA} = "New avatar uploaded";
   }

   if($UserSettings->{"GravatarOrAvatar"} ne $self->{cgi}->{"GravatarOrAvatar"}){
      $UserSettingsObj->update("GravatarOrAvatar", $self->{cgi}->{"GravatarOrAvatar"}, $UserSettings->{ID});
      if($self->{ErrorMessagesEA} eq "New avatar uploaded" && $self->{cgi}->{"GravatarOrAvatar"} eq 'A'){
         $self->{ErrorMessagesEA} .= " and activated";
      }else{
         if($self->{cgi}->{"GravatarOrAvatar"} eq 'G'){
            $self->{ErrorMessagesEA} = "Now using your Gravatar";
         }else{
            $self->{ErrorMessagesEA} = "Now using your List Central avatar";
         }         
      }
   }

   if($UserSettings->{"GravatarEmail"} ne $self->{cgi}->{GravatarEmail}){     
      $UserSettingsObj->update("GravatarEmail", $self->{cgi}->{GravatarEmail}, $UserSettings->{ID});
      $self->{ErrorMessagesEA} .= " and Gravatar email updated";
   }

   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{SettingsTab}->{Avatar} = 1;
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/settings.html");
   return $content;
}

=head2 EditAboutMe

Handles the edit about me process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditAboutMe {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditAboutMe");

   # No one logged in, shouldn't be editing anything!
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_ACCOUNT'};
      $self->{Debugger}->throwNotifyingError("User tried to edit account, but no one logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});

   if($self->{cgi}->{"UserSettings.RegionID"}){
      $self->{cgi}->{"UserSettings.Region"} = "";
   }elsif($self->{cgi}->{"UserSettings.Region"}){
      $self->{cgi}->{"UserSettings.RegionID"} = 0;
   }  

   foreach my $param(keys %{$self->{cgi}}) {
      if($param =~ m/UserSettings\.(\w+)/){
         my $field = $1;
         if($self->{UserManager}->{ThisUser}->{$field} ne $self->{cgi}->{$param}){
            $self->{Debugger}->debug("EditAboutMe editing $field with $self->{cgi}->{$param}");
            $UserSettingsObj->update($field, $self->{cgi}->{$param}, $UserSettings->{ID});
         }
      }
   }
   $self->{ErrorMessagesEAM} = "";

   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{SettingsTab}->{AboutMe} = 1;
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/settings.html");

   return $content;
}

=head2 EditBasicInfo

Handles the edit basic info process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditBasicInfo {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditBasicInfo");

   # No one logged in, shouldn't be editing anything!
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_ACCOUNT'};
      $self->{Debugger}->throwNotifyingError("User tried to edit account, but no one logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{UserManager}->{ThisUser}->{Password} = $self->{UserManager}->getUsersEncryptedPassword($self->{UserManager}->{ThisUser}->{ID});

   $self->{ErrorMessagesEBI} = "";

   # Verify password correct
   my $encryptedPassword = $self->{UserManager}->encryptPassword($self->{cgi}->{"PasswordVerify"});

   $self->{Debugger}->debug("UserID $self->{UserManager}->{ThisUser}->{ID} -> self->{UserManager}->{ThisUser}->{Password}: $self->{UserManager}->{ThisUser}->{Password}, encryptedPassword: $encryptedPassword");

   if($encryptedPassword ne $self->{UserManager}->{ThisUser}->{Password}){
      $self->{ErrorMessagesEBI} = $Lists::SETUP::MESSAGES{'FAIL_PASSWORD_EDIT_ACCOUNT'};
   }else{
      my $UserObj = $self->{DBManager}->getTableObj("User");
      # Good to change the info
      if($self->{cgi}->{"User.Password1"} ne ""){
         #Change password
         if($self->{cgi}->{"User.Password1"} ne $self->{cgi}->{"User.Password2"}){
            $self->{ErrorMessagesEBI} = $Lists::SETUP::MESSAGES{'PASSWORD_NONMATCH'};
         }else{
            my $NewEncryptedPassword = $self->{UserManager}->encryptPassword($self->{cgi}->{"User.Password1"});
            $UserObj->update("Password", $NewEncryptedPassword, $self->{UserManager}->{ThisUser}->{ID});
         }
      }
      if($self->{cgi}->{"User.Email"} ne $self->{UserManager}->{ThisUser}->{Email}){
         # Change email
         my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
         if(! $Mailer->emailValid($self->{cgi}->{"User.Email"})){
            $self->{ErrorMessagesEBI} .= $Lists::SETUP::MESSAGES{'INVALID_EMAIL'} . "<br />";
         }else{
            my $Users = $UserObj->get_with_restraints("Email = \"$self->{cgi}->{'User.Email'}\"");
            foreach (keys %{$Users}) {
               if($Users->{$_}){
                  $self->{ErrorMessagesEBI} .= $Lists::SETUP::MESSAGES{'DUPLICATE_EMAIL'} . "</br>";
               }  
            }
            if($self->{ErrorMessagesEBI} eq ""){
               $UserObj->update("Email", $self->{cgi}->{"User.Email"}, $self->{UserManager}->{ThisUser}->{ID});
            }
         }
      }

      if($self->{cgi}->{"User.Name"} ne $self->{UserManager}->{ThisUser}->{Name}){
         # Change name
         if($self->{cgi}->{"User.Name"} eq ""){
            $self->{ErrorMessagesEBI} .= $Lists::SETUP::MESSAGES{'BLANK_NAME'} . "<br />";
         }else{
            $UserObj->update("Name", $self->{cgi}->{"User.Name"}, $self->{UserManager}->{ThisUser}->{ID});
         }
      }

      if($self->{cgi}->{"User.Username"} ne $self->{UserManager}->{ThisUser}->{Username}){
         # Change username
         if($self->{cgi}->{"User.Username"} eq ""){   
            $self->{ErrorMessagesEBI} .= $Lists::SETUP::MESSAGES{'BLANK_USERNAME'} . "<br />"; 
         }else{
            my $Users = $UserObj->get_with_restraints("Username = \"$self->{cgi}->{'User.Username'}\"");
            foreach (keys %{$Users}) {
               if($Users->{$_}){
                  $self->{ErrorMessagesEBI} .= $Lists::SETUP::MESSAGES{'DUPLICATE_USERNAME'} . "<br />"; 
               }  
            }
            if($self->{ErrorMessagesEBI} eq ""){
               $UserObj->update("Username", $self->{cgi}->{"User.Username"}, $self->{UserManager}->{ThisUser}->{ID});

               # Record UsernameHistory
               my $UsernameHistoryObj = $self->{DBManager}->getTableObj("UsernameHistory");
               my %UsernameHistory = ("UsernameHistory.Username" => $self->{cgi}->{"User.Username"},
                                      "UsernameHistory.UserID" => $self->{UserManager}->{ThisUser}->{ID},
                                      "UsernameHistory.Status" => 1);
               $UsernameHistoryObj->store(\%UsernameHistory);

               $self->{UserManager}->changeUsersDirectory($self->{UserManager}->{ThisUser}->{ID}, 
                                             $self->{UserManager}->{ThisUser}->{Username}, $self->{cgi}->{"User.Username"});
            }
         }         
      }
   }

   if($self->{ErrorMessagesEBI} eq ""){
      $self->{ErrorMessagesEBI} = "Changed successfully";
      $self->{UserManager}->{ClearCache} = 1;
      $self->{UserManager}->getThisUserInfo();
   }

   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();

   $self->{SettingsTab}->{BasicInfo} = 1;
   $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/settings.html";
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 EditTheme

Handles the edit site settings process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditTheme {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditTheme");

   # No one logged in, shouldn't be editing anything!
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_ACCOUNT'};
      $self->{Debugger}->throwNotifyingError("User tried to edit account, but no one logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{ErrorMessagesET} = "";
   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});
   if($UserSettings->{ThemeID} != $self->{cgi}->{"UserSettings.ThemeID"} && $self->{cgi}->{"UserSettings.ThemeID"}){
      $UserSettingsObj->update("ThemeID", $self->{cgi}->{"UserSettings.ThemeID"}, $UserSettings->{ID});
      $self->{ThemeID} = $self->{cgi}->{"UserSettings.ThemeID"};
   }


   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{SettingsTab}->{Theme} = 1;
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();

   $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/settings.html";
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 EditEmailing

Handles the edit site settings process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditEmailing {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditEmailing");

   # No one logged in, shouldn't be editing anything!
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_ACCOUNT'};
      $self->{Debugger}->throwNotifyingError("User tried to edit account, but no one logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{ErrorMessagesEE} = "";
   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});
   if($UserSettings->{ReceiveUpdateEmails} != $self->{cgi}->{"UserSettings.ReceiveUpdateEmails"}){
      $UserSettingsObj->update("ReceiveUpdateEmails", $self->{cgi}->{"UserSettings.ReceiveUpdateEmails"}, $UserSettings->{ID});
   }

   if($UserSettings->{ReceiveNotifications} != $self->{cgi}->{"UserSettings.ReceiveNotifications"}){
      $UserSettingsObj->update("ReceiveNotifications", $self->{cgi}->{"UserSettings.ReceiveNotifications"}, $UserSettings->{ID});
   }


   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{SettingsTab}->{Emailing} = 1;
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/settings.html");

   return $content;
}

=head2 EditPrivacy

Handles the edit site settings process from the settings page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the settings page

=back

=cut

#############################################
sub EditPrivacy {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditPrivacy");

   # No one logged in, shouldn't be editing anything!
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_ACCOUNT'};
      $self->{Debugger}->throwNotifyingError("User tried to edit account, but no one logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{ErrorMessagesEP} = "";
   my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
   my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});

   foreach my $field (keys %{$self->{cgi}}) {
      if($field =~ m/^UserSettings\.Privacy(\w+)/){
         my $tableField = "Privacy". $1;
         if($UserSettings->{$tableField} != $self->{cgi}->{$field}){
            $UserSettingsObj->update($field, $self->{cgi}->{$field}, $UserSettings->{ID});
         }
      }
   }


   $self->{UserManager}->{ClearCache} = 1;
   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->getThisUserInfo();
   $self->{SettingsTab}->{Privacy} = 1;
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/owner/settings.html");

   return $content;
}

=head2 EditListDetails

Handles the edit list details process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list post detail changes

=back

=cut

#############################################
sub EditListDetails {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->EditListDetails");

   if($self->{cgi}->{"List.Name"} eq ""){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'BLANK_LIST_NAME'};   
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
      my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
      return $content;
   }

   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});

   # Test this is from the logged in list owner
   if($List->{UserID} != $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to edit list($List->{UserID}) s/he shouldn't");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   my $updated = 0;
   $self->{cgi}->{"List.Name"} = Lists::Utilities::StringFormator::htmlEncode($self->{cgi}->{"List.Name"});
   foreach my $key(keys %{$self->{cgi}}) {
      if($key =~ m/List\.(\w+)/){
         my $field = $1;
         if($self->{cgi}->{$key} ne $List->{$field}){
            $self->{ListObj}->update($field, $self->{cgi}->{$key}, $List->{ID});

            if($field eq "Public" && $self->{cgi}->{$key} == 1){
               $self->setDateMadePublic($self->{cgi}->{"ListID"});
            }
         }
      }
   }
   if($updated){
      $self->{ListObj}->update("LastActiveDate", time(), $List->{ID});
   }

   if($self->{cgi}->{'SetAllStatusTo'}){
      my $ListItems = $self->{ListItemObj}->get_with_restraints("ListID = $List->{ID}");
      my $count = 1;
      foreach my $ListItemID(sort keys %{$ListItems}) {
         $self->{ListItemObj}->update("ListItemStatusID", $self->{cgi}->{"SetAllStatusTo"}, $ListItemID);
         $self->{ListItemObj}->update("PlaceInOrder", $count, $ListItemID);
         $count++;
      }
   }

   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->{cgi}->{ListID} = $List->{ID};
   $self->{cgi}->{ListDivDisplay} = "ListNormalView";

   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 EditListItem

Gets the content of a list item

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $listid - The list to get

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub EditListItem {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in Lists::ListsManager->EditListItem");

   $self->{cgi}->{"ListItem.Name"} = Lists::Utilities::StringFormator::htmlEncode($self->{cgi}->{"ListItem.Name"});

   # Get the list Item
   my %EditedListItem;
   foreach my $key(keys %{$self->{cgi}}) {
      if($key =~ m/ListItem\.(\w+)/){
         my $field = $1;
         $EditedListItem{$field} = $self->{cgi}->{$key};
      }
   }

   my $ListItemID = $EditedListItem{ID};
   my $ListItem = $self->{ListItemObj}->get_by_ID($ListItemID);
   my $List = $self->{ListObj}->get_by_ID($ListItem->{ListID});

   if(! $self->{cgi}->{"ListID"}){
      $self->{cgi}->{"ListID"} = $ListItem->{ListID};
   }

   # Check permission to edit
   if(! $self->{UserManager}->{ThisUser}->{ID} || $self->{UserManager}->{ThisUser}->{ID} != $List->{UserID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST_ITEM'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to edit list item($ListItemID) s/he shouldn't");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   # Handle to simple ones first, the Name ListItemStatus and Description
   if($EditedListItem{Name} ne $ListItem->{Name}){
      if($EditedListItem{Name} ne ""){
         $self->{ListItemObj}->update("Name", $EditedListItem{Name}, $ListItemID);
      }else{
         $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'EMPTY_LIST_NAME'};
      }
   }
   if($EditedListItem{Description} ne $ListItem->{Description}){
      $self->{ListItemObj}->update("Description", $EditedListItem{Description}, $ListItemID);
   }
   if($EditedListItem{ListItemStatusID} ne $ListItem->{ListItemStatusID}){
      $self->{ListItemObj}->update("ListItemStatusID", $EditedListItem{ListItemStatusID}, $ListItemID);

      # Get the new PlaceInOrder
      my $PlaceInOrder = $self->{ListItemObj}->getMaxPlaceInOrder($self->{cgi}->{"ListID"}, $EditedListItem{ListItemStatusID});
      $PlaceInOrder = $PlaceInOrder + 1;
      $self->{ListItemObj}->update("PlaceInOrder", $PlaceInOrder, $ListItemID);
   }


   # Now the trickier pieces
   # Link here
   if($EditedListItem{Link}){
      if($ListItem->{LinkID}){
         my $Link = $self->{LinkObj}->get_by_ID($ListItem->{LinkID});
         if($EditedListItem{Link} ne $Link->{Link}){
            # Store a new link and update the linkid in the ListItem
            my $LinkID = $self->{LinkObj}->saveLink($EditedListItem{Link});
            if($LinkID =~ m/\D+/){
               # DB Error!
               $self->{ErrorMessages} = $LinkID;
               return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
            }else{
               $self->{ListItemObj}->update("LinkID", $LinkID, $ListItemID);
            }
         }
      }else{
         # Store a new link and update the linkid in the ListItem
         my $LinkID = $self->{LinkObj}->saveLink($EditedListItem{Link});
         if($LinkID =~ m/\D+/){
            # DB Error!
            $self->{ErrorMessages} = $LinkID;
            return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
         }else{
            $self->{ListItemObj}->update("LinkID", $LinkID, $ListItemID);
         }
      }
   }elsif($ListItem->{LinkID}){
      # They deleted the link
      $self->{ListItemObj}->update("LinkID", "", $ListItemID);
   }

   # Date here
   if($EditedListItem{Date}){
      my $DateObj = $self->{DBManager}->getTableObj("Date");
      if($ListItem->{DateID}){         
         my $Date = $DateObj->get_by_ID($ListItem->{DateID});
         if($EditedListItem{Date} ne $Date->{DateEng}){
            $DateObj->update("DateEng", $EditedListItem{Date}, $ListItem->{DateID});

            my $epoch = Lists::Utilities::Date::getEpochDateTime($EditedListItem{Date});
            $DateObj->update("DateEpoch", $epoch, $ListItem->{DateID});
         }
         if($EditedListItem{EmailFrequency} ne $Date->{"ListItem.EmailFrequency"}){
            $DateObj->update("EmailFrequency", $EditedListItem{EmailFrequency}, $ListItem->{DateID});
         }
      }else{
         # Store a new date and update the linkid in the ListItem
         my $DateID = $DateObj->saveDate($self->{cgi}, $self->{UserManager}->{ThisUser}->{ID});
         if($DateID =~ m/\D+/){
            # DB Error!
            $self->{ErrorMessages} = $DateID;
            return $self->getPage("$Lists::SETUP::DIR_PATH/error.html");
         }else{
            $self->{ListItem}->update("DateID", $DateID, $ListItemID);
         }
      }
   }

   # Amazon, CCImage, Image and Embed here
   if($EditedListItem{"ASIN"}){
      my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager}, 
                                                   UserManager => $self->{UserManager});
      my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
      if($ListItem->{AmazonID}){
         my $AmazonLinks = $AmazonLinksObj->get_by_ID($ListItem->{AmazonID});
         if($EditedListItem{"ASIN"} ne $AmazonLinks->{ASIN}){
            # Store the new Amazon link, and update the AmazonID            
            my $AmazonID = $Amazon->saveAmazonLink($self->{cgi});
            $self->{ListItemObj}->update("AmazonID", $AmazonID, $ListItem->{ID});
            $self->{ListItemObj}->clearListItemExtras($ListItem, "AmazonID");
         }
      }else{
         # Store the new Amazon link, and update the AmazonID, and null out ImageID, CCImageID and EmbedID
         my $AmazonID = $Amazon->saveAmazonLink($self->{cgi});
         $self->{ListItemObj}->update("AmazonID", $AmazonID, $ListItem->{ID});
         $self->{ListItemObj}->clearListItemExtras($ListItem, "AmazonID");
      }
   }elsif($EditedListItem{"CCImage"}){
      my $CCImageObj = $self->{DBManager}->getTableObj("CCImage");
      if($ListItem->{CCImageID}){
         if($EditedListItem{"CCImage"} ne $ListItem->{CCImageID}){
            my $CCImageID = $CCImageObj->saveCCImage($self->{cgi});
            $self->{ListItemObj}->update("CCImageID", $CCImageID, $ListItem->{ID});
            $self->{ListItemObj}->clearListItemExtras($ListItem, "CCImageID");
         }
      }else{
         my $CCImageID = $CCImageObj->saveCCImage($self->{cgi});
         $self->{ListItemObj}->update("CCImageID", $CCImageID, $ListItem->{ID});
         $self->{ListItemObj}->clearListItemExtras($ListItem, "CCImageID");
      }
   }elsif($EditedListItem{"ImageID"}){
      my $ImageObj = $self->{DBManager}->getTableObj("Image");
      if($ListItem->{ImageID}){
         my $Image = $ImageObj->get_by_ID($ListItem->{ImageID});
         if($EditedListItem{"ImageID"} ne $Image->{ID}){
            $self->{ListItemObj}->update("ImageID", $EditedListItem{"ImageID"}, $ListItem->{ID});
            $self->{ListItemObj}->clearListItemExtras($ListItem, "ImageID");
         }
      }else{
         $self->{ListItemObj}->update("ImageID", $EditedListItem{"ImageID"}, $ListItem->{ID});
         $self->{ListItemObj}->clearListItemExtras($ListItem, "ImageID");
      }
   }elsif($EditedListItem{"Embed"}){
      my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
      if($ListItem->{EmbedID}){
         my $Embed = $EmbedObj->get_by_ID($ListItem->{EmbedID});
         if($EditedListItem{"Embed"} ne $Embed->{EmbedCode}){
            my $EmbedID = $EmbedObj->saveEmbed($self->{cgi});
            $self->{ListItemObj}->update("EmbedID", $EmbedID, $ListItem->{ID});
            $self->{ListItemObj}->clearListItemExtras($ListItem, "EmbedID");
         }
      }else{
         my $EmbedID = $EmbedObj->saveEmbed($self->{cgi});
         $self->{ListItemObj}->update("EmbedID", $EmbedID, $ListItem->{ID});
         $self->{ListItemObj}->clearListItemExtras($ListItem, "EmbedID");
      }
   }else{
      # Clear the four, if any were there
      $self->{ListItemObj}->clearListItemExtras($ListItem);
   }

   $self->{ListObj}->update("LastActiveDate", time(), $List->{ID});
   

   return $self->getListHTML($ListItem->{ListID});
}

=head2 EditListItemOrder

Edits the order of the items in a list

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub EditListItemOrder {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in Lists::ListsManager->EditListItemOrder");

   # Check permission to edit
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to reorder list s/he shouldn't $self->{cgi}->{ListOrder}");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   my $Order = $self->{cgi}->{ListOrder};
   $Order =~ s/^,//;
   # ListItemIDa:PlaceInOrdera,ListItemIDa2:PlaceInOrdera2,ListItemIDb:PlaceInOrderb,ListItemIDb2:PlaceInOrderb2

   my $ListID;
   my @pairs = split(/,/, $Order);

   # Lets get the list id
   my ($ListItemID, $PlaceInOrder) = split(/-/, $pairs[0]);
   my $ListItem = $self->{ListItemObj}->get_by_ID($ListItemID);
   my $List = $self->{ListObj}->get_by_ID($ListItem->{ListID});
   if($self->{UserManager}->{ThisUser}->{ID} != $List->{UserID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User($self->{UserManager}->{ThisUser}->{ID}) tried to reorder list s/he shouldn't $self->{cgi}->{ListOrder}");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   # Now for the ordering
   if($List->{Ordering} eq "a"){
      # Ascending, the straight-forward way
      foreach my $pair(@pairs) {
         my ($ListItemID, $PlaceInOrder) = split(/-/, $pair);
         if(!$ListID){
            my $ListItem = $self->{ListItemObj}->get_by_ID($ListItemID);
            $ListID = $ListItem->{ListID}; 
         }
         if($ListItem->{PlaceInOrder} ne $PlaceInOrder){
            $self->{ListItemObj}->update("PlaceInOrder", $PlaceInOrder, $ListItemID);
         }
      }
   }else{
      my %adjustedPairs;
      foreach my $pair(@pairs) {
         my ($ListItemID, $PlaceInOrder) = split(/-/, $pair);
         if(!$ListID){
            my $ListItem = $self->{ListItemObj}->get_by_ID($ListItemID);
            $ListID = $ListItem->{ListID}; 
         }
         
         $adjustedPairs{$ListItemID}{FromJS} = $PlaceInOrder;
      }

      my $PlaceInOrder = 1;
      foreach my $listitemid(sort{$adjustedPairs{$b}{FromJS} <=> $adjustedPairs{$a}{FromJS}} keys %adjustedPairs){
         $self->{ListItemObj}->update("PlaceInOrder", $PlaceInOrder, $listitemid);
         $PlaceInOrder++;
      }
   }  

   
   $self->{cgi}->{"ListID"} = $ListID;
   return $self->getListHTML($ListID);
}

=head2 EmailList

Emails a List to a given email address

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub EmailList {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in ListsManager::EmailList");

   # Test Email Address given
   use Lists::Utilities::Mailer;
   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{"ListID"});

   my $ErrorMessage = "";
   if($Mailer->emailValid($self->{cgi}->{ToEmail})){
      if($List->{Public} || ($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID})){

         my ($EmailHTML, $EmailTXT, $boundary) = $self->getListEmail($self->{cgi}->{"ListID"});
         $Mailer->sendEmail($self->{cgi}->{ToEmail}, 
                            $Lists::SETUP::MAIL_FROM_LISTS, 
                            "A list from List Central", 
                            $EmailHTML, $EmailTXT, $boundary);

         # Record the Email List Hit
         $self->logListHit($List, $self->{cgi}->{ToEmail});
      }else{
         # don't send
         $ErrorMessage = $Lists::SETUP::MESSAGES{'NO_PERMISSION_VIEW_LIST'};
      }      
   }else{
      # Don't send
      $ErrorMessage = $Lists::SETUP::MESSAGES{'INVALID_EMAIL'};
   }

   $self->{cgi}->{"UserID"} = $List->{UserID};
   $self->{"ListName"} = $List->{Name};
   $self->setThemeID();

   my $content;
   if($ErrorMessage eq ""){
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/email_list_success.html");
   }else{
      $self->{ErrorMessages} .= $ErrorMessage;
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/email_list.html");
   }
   return $content;
}

=head2 GetCreateEditForm

Returns the html for the edit list groups and status sets form

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub GetCreateEditForm {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::GetEditGroupsForm");

   # Check permission to edit
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User tried to get create/edit form, but not logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{CreateEditTab}->{CreateList} = 1;

   # Fill the ThisUser with the logged in user's info
   $self->{UserManager}->getUserInfo($self->{UserManager}->{ThisUser});

   my $createEdit = "";
   if($self->{cgi}->{ajax}){
      $createEdit =  $self->getPage("$Lists::SETUP::DIR_PATH/owner/create_and_edit.html");
   }else{
      $self->{"DisplayCreateEditForm"} = 1;
      $createEdit =  $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }

   $self->{Debugger}->debug("createEdit: \n$createEdit");
   return $createEdit;

}


=head2 GetEditListItemForm

Returns the html for the edit list item form for the list item in cgi->ListItemID

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub GetEditListItemForm {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::GetEditListItemForm");

   # Check permission to edit
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User tried to get edit list item form, but not logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      $content .= qq~<input type='button' name='Close' value='Close' id='editlistitemcancel' class='Button' onClick='doNothing()' />" + ~;
      return $content;
   }
   if(!$self->{cgi}->{"ListItemID"}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'MISC_ERROR'};
      $self->{Debugger}->throwNotifyingError("User tried to get edit list item form, but not logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      $content .= qq~<input type='button' name='Close' value='Close' id='editlistitemcancel' class='Button' onClick='doNothing()' />" + ~;
      return $content;
   }

   my $ListItem = $self->{ListItemObj}->get_by_ID($self->{cgi}->{"ListItemID"});
   my $List = $self->{ListObj}->get_by_ID($ListItem->{ListID});
   my ($ListItemAdditions, $JSCalls, $ListItemFormExtra, $ListItemFormExtraHiddenFields) = $self->getEditListFormAdditions($ListItem); 

   my %Data;
   $Data{'List'} = $List;
   $Data{'ListItem'} = $ListItem;
   $Data{'ListItemStatusSelect'} = $self->{ListItemStatusObj}->getListItemStatusSetSelect($List, $ListItem->{"ListItemStatusID"});  
   if(! $Data{'ListItemStatusSelect'}){
      # Without this the edit list item form deletes the items when the list 
      #  has no status set
      $Data{'ListItemStatusSelect'} = qq~<input type="hidden" name="ListItem.ListItemStatusID" id="EditListItemStatusID" value="1" />~;
   }
   $Data{'ListItemAdditions'} = $ListItemAdditions;
   $Data{'JSCalls'} = $JSCalls;
   $Data{'ExtraElement'} = $ListItemFormExtra;
   $Data{'ExtraHiddenFields'} = $ListItemFormExtraHiddenFields;

   my $editListItemForm =  $self->processPage("$Lists::SETUP::DIR_PATH/owner/listpieces/list_item_edit_form.html", \%Data);

   return $editListItemForm;
}

=head2 getEditListFormAdditions

Gets the edit list item form additions

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
   2. $ListItem - Reference to the ListItem being edited 

=item B<Returns :>

   1. $ListItemFormAdditions - the html for the form additions
   2. $JSCalls - The corresponding javascript calls

=back

=cut

#############################################
sub getEditListFormAdditions {
#############################################
   my $self = shift;
   my $ListItem = shift;

   $self->{Debugger}->debug("in Lists::ListManager::getEditListFormAdditions with $ListItem->{Name}");

   # Get the additions
   my $JSCalls = "";
   my $ListItemAdditions = ""; 
   my $ListItemFormExtra = ""; 
   my $ListItemFormExtraHiddenFields = ""; 
   if($ListItem->{LinkID}){

      my $LinkObj = $self->{DBManager}->getTableObj("Link");
      my $Link = $LinkObj->get_by_ID($ListItem->{LinkID});

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"Link"} = $Link->{Link};
      $ListItemAdditions .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_link.html", \%Data);

      $JSCalls .= "disableListItemButton('Edit', 'Link');";
   }

   if($ListItem->{Description} ne ""){

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"Description"} = $ListItem->{Description};
      $ListItemAdditions .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_description.html", \%Data);

      $JSCalls .= "createEditor('Edit');";
      $JSCalls .= "disableListItemButton('Edit', 'Description');";
   }

   if($ListItem->{DateID}){

      my $DateObj = $self->{DBManager}->getTableObj("Date");
      my $Date = $DateObj->get_by_ID($ListItem->{DateID});

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"Date"} = $Date->{DateEng};
      $ListItemAdditions .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_date.html", \%Data);

      #$JSCalls .= "datePicker = new DatePicker('.DateInput', { timePicker: true, format: 'd-m-Y @ H:i', inputID: 'EditListItemDate' });";
      #$JSCalls .= "datePicker.attach();";
      $JSCalls .= "disableListItemButton('Edit', 'Date');";
   }

   if($ListItem->{AmazonID}){
      my $AmazonLinksObj = $self->{DBManager}->getTableObj("AmazonLinks");
      my $AmazonLink = $AmazonLinksObj->get_by_ID($ListItem->{AmazonID});

      # Set country properly
      my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager}, 
                                                   UserManager => $self->{UserManager});
      my $country = $Amazon->getCountryByRemoteIP();

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"ExtraASIN"} = $AmazonLink->{ASIN};
      $Data{"ExtraDisplay"} = "display:block";
      $Data{"ExtraLabel"} = "Amazon link:";
      $Data{"RemoveExtraLink"} = "javascript:removeListItemExtra('Edit', 'Amazon');";
      $Data{"ExtraLink"} = $AmazonLink->{$country};
      $Data{"ExtraImage"} = $AmazonLink->{$country . "Image"};

      $ListItemFormExtra .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_element.html", \%Data);
      $ListItemFormExtraHiddenFields .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%Data);

      $JSCalls .= "disableListItemButton('Edit', 'Amazon');";

   }elsif($ListItem->{CCImageID}){
      my $CCImageObj = $self->{DBManager}->getTableObj("CCImage");
      my $CCImage = $CCImageObj->get_by_ID($ListItem->{CCImageID});

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"ExtraCCImage"} = $ListItem->{CCImageID};
      $Data{"ExtraDisplay"} = "display:block";
      $Data{"ExtraLabel"} = "Creative commons image:";
      $Data{"RemoveExtraLink"} = "javascript:removeListItemExtra('Edit', 'CCImage');";
      $Data{"ExtraLink"} = $CCImage->{Source};
      $Data{"ExtraImage"} = $CCImage->{Image};

      $ListItemFormExtra .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_element.html", \%Data);
      $ListItemFormExtraHiddenFields .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%Data);

      $JSCalls .= "disableListItemButton('Edit', 'CCImage');";

   }elsif($ListItem->{ImageID}){
      my $ImageObj = $self->{DBManager}->getTableObj("Image");
      my $Image = $ImageObj->get_by_ID($ListItem->{ImageID});

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"ExtraImageID"} = $ListItem->{ImageID};
      $Data{"ExtraDisplay"} = "display:block";
      $Data{"ExtraLabel"} = "Image:";
      $Data{"RemoveExtraLink"} = "javascript:removeListItemExtra('Edit', 'Image');";
      
      my $path = $self->{UserManager}->getUsersDirectory($self->{UserManager}->{ThisUser}->{ID});
      $Data{"ExtraImage"} = $Lists::SETUP::USER_CONTENT_DIRECTORY . "/" . $path . "/" . $Image->{ID} . "M." . $Image->{Extension};
      $Data{"ExtraLink"} = $Lists::SETUP::USER_CONTENT_DIRECTORY . "/" . $path . "/" . $Image->{ID} . "L." . $Image->{Extension};

      $ListItemFormExtra .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_element.html", \%Data);
      $ListItemFormExtraHiddenFields .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%Data);

      $JSCalls .= "disableListItemButton('Edit', 'Image');";

   }elsif($ListItem->{EmbedID}){
      my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
      my $Embed = $EmbedObj->get_by_ID($ListItem->{EmbedID});

      my %Data;
      $Data{"action"} = "Edit";
      $Data{"ExtraEmbedID"} = $ListItem->{EmbedID};
      $Data{"Embed"} = $Embed->{EmbedCode};
      $ListItemAdditions .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_embed.html", \%Data);
      $ListItemFormExtraHiddenFields .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%Data);

      $JSCalls .= "disableListItemButton('Edit', 'Embed');";
   }else{
      my %Data;
      $Data{"action"} = "Edit";
      $Data{"ExtraDisplay"} = "display:none";

      $ListItemFormExtra .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_element.html", \%Data);
      $ListItemFormExtraHiddenFields .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%Data);
   }

   return ($ListItemAdditions, $JSCalls, $ListItemFormExtra, $ListItemFormExtraHiddenFields);
}

=head2 GetRegionOptions

Gets the regions in a select for the countryid in cgi

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $options - the html for the regions options

=back

=cut

#############################################
sub GetHelpListings {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::GetHelpListings");

   use Lists::Utilities::HelpManager;
   my $HelpManager = new Lists::Utilities::HelpManager(cgi=>$self->{cgi}, Debugger=>$self->{Debugger}, 
                                                         DBManager=>$self->{DBManager});

   my $Listings = $HelpManager->getHelpListings();

   return $Listings;
}


=head2 GetRegionOptions

Gets the regions in a select for the countryid in cgi

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $options - the html for the regions options

=back

=cut

#############################################
sub GetRegionOptions {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::GetRegionsSelect");

   my $RegionObj = $self->{DBManager}->getTableObj("Region");
   my $Regions;
   if($self->{cgi}->{CountryID}){
      $Regions = $RegionObj->get_with_restraints("CountryID = $self->{cgi}->{CountryID}");
   }

   if(! scalar(keys %{$Regions})){
      return qq~<input type="text" name="UserSettings.Region" id="Region" value="$self->{UserManager}->{ThisUser}->{Region}" />~;
   }

   my $options = qq~<option value="">Select</option>~;
   foreach my $key(sort{$Regions->{$a}->{Name} cmp $Regions->{$b}->{Name}} keys %{$Regions}){
      if($self->{UserManager}->{ThisUser}->{RegionID} eq $Regions->{$key}->{ID}){
         $options .= qq~<option value="$Regions->{$key}->{ID}" selected="selected">$Regions->{$key}->{Name}</option>~;
      }else{
         $options .= qq~<option value="$Regions->{$key}->{ID}">$Regions->{$key}->{Name}</option>~;
      }
   }

   my $select = qq~<select name="UserSettings.RegionID" id="RegionSelect" class="SelectInput"> 
                     $options
                     </select>~;

   return $select;
}

=head2 GetSettings

Returns the html for the edit settings form

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub GetSettings {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->GetSettings");

   $self->{UserManager}->{UserSettings} = 1;
   $self->{UserManager}->{ClearCache} = 1;
   # Check permission to edit
   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};
      $self->{Debugger}->throwNotifyingError("User tried to get settings form, but not logged in");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{SettingsTab}->{BasicInfo} = 1;

   # Fill the ThisUser with the looged in user's info
   $self->{UserManager}->getUserInfo($self->{UserManager}->{ThisUser});

   my $settings = "";
   if($self->{cgi}->{ajax}){
      $settings = $self->getPage("$Lists::SETUP::DIR_PATH/owner/settings.html");
   }else{
      $self->{"DisplaySomethingOtherThanList"} = "$Lists::SETUP::DIR_PATH/owner/settings.html";
      $settings = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
   }
   $self->{Debugger}->debug("Settings: $settings");
   return $settings;
}


=head2 Login

Handles the login process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub Login {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::Login");

   my $content = "";
   my $ID;
   ($ID, $self->{LoginErrorMessages}) = $self->{UserManager}->doLogin();
   if($ID == -1){
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/deactivated_account.html");
   }else{
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
      if($self->{UserManager}->{ThisUser}->{ID}){
         $self->setThemeID();

         $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");
      }else{
         $content = $self->getPage("$Lists::SETUP::DIR_PATH/login.html");
      }
   }
   return $content;
}

=head2 Logout

Handles the logout process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub Logout {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::Logout");

   $self->{UserManager}->doLogout();
   $self->getPage("$Lists::SETUP::DIR_PATH/index.html");
}

=head2 PostOnBoard

Handles the process of posting on someones board

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the html for the users board

=back

=cut

#####################################
sub PostOnBoard {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::PostOnBoard: ". $self->{cgi}->{'Board.Message'});

   if($self->{cgi}->{"Board.Message"} eq "" || $self->{cgi}->{"Board.Message"}  eq "Write Something..."){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'BLANK_BOARD_MESSAGE'};   
   }elsif(! $self->{cgi}->{"Board.UserID"} || ! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'MISC_ERROR'};   
      $self->{Debugger}->throwNotifyingError("Post on board problem: No Board owner ($self->{cgi}->{'Board.UserID'}), or no one logged in($self->{UserManager}->{ThisUser}->{ID})");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   if($self->{ErrorMessages} eq ""){
      $self->{cgi}->{"Board.PosterUserID"} = $self->{UserManager}->{ThisUser}->{ID};
      $self->{cgi}->{"Board.Status"} = 1;
      my $BoardObj = $self->{DBManager}->getTableObj("Board");
      my $BoardPostID = $BoardObj->store($self->{cgi});
      if($BoardPostID =~ m/\D+/){
         # Error!
         $self->{ErrorMessages} = $BoardPostID;
         my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
         return $content;
      }

      # Add the message
      my %Message;
      $Message{"Messages.UserID"} = $self->{cgi}->{"Board.UserID"};
      $Message{"Messages.Action"} = 2;
      $Message{"Messages.DoerID"} = $self->{UserManager}->{ThisUser}->{ID};
      $Message{"Messages.Seen"} = 0;
      $Message{"Messages.Status"} = 1;
      $Message{"Messages.SubjectID"} = $BoardPostID;
      my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
      my $MessageID = $MessagesObj->store(\%Message);

      if($self->{cgi}->{"Board.UserID"} != $self->{UserManager}->{ThisUser}->{ID}){
         my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings");
         my $UserSettings = $UserSettingsObj->getByUserID($self->{cgi}->{"Board.UserID"});
         if($UserSettings->{ReceiveNotifications}){
            $self->sendNotificationEmail($MessageID);
         }
      }
   }

   $self->{cgi}->{UserID} = $self->{cgi}->{"Board.UserID"};
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}

=head2 PublishList

Handles the process of a user publishing their own list

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the html for the list

=back

=cut

#####################################
sub PublishList {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::PublishList");

   if(! $self->{cgi}->{ListID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'MISC_ERROR'};   
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }
   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{ListID});
   if($List->{UserID} != $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NO_PERMISSION_EDIT_LIST'};   
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   $self->{ListObj}->update("Public", 1, $self->{cgi}->{ListID});

   $self->setDateMadePublic($self->{cgi}->{ListID}); 
   
   $self->setThemeID();
   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/lists.html");

   return $content;
}


=head2 SearchLists

Handles the Search List process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub SearchLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::SearchLists"); 

   my $content = "";
   if($self->{cgi}->{Query} ne ""){      
      my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                      'UserManager'=>$self->{UserManager}, 'cgi' => $self->{cgi});

      my $page = $self->{cgi}->{page}  ? $self->{cgi}->{page}: 1;
      my ($SearchResultsCount, $ListsHash) = $SearchModule->doBasicListSearch($self->{cgi}->{Query}, $page, $self->{cgi}->{IncludeUsersPrivateLists});
      my $pageCount = int($SearchResultsCount / $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'});
      if($SearchResultsCount % $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'}){
         $pageCount++;
      }

      foreach my $ID (keys %{$ListsHash}) {
         $self->{ListObj}->getListInfo($ListsHash->{$ID}, $self->{DBManager}, $self->{UserManager}, 1);
      }
      my $ResultsRows = $SearchModule->processSearchResults("$Lists::SETUP::DIR_PATH/widgets/listing_row.html", $ListsHash);
      if($SearchResultsCount){
         $self->{Pagenation} = $SearchModule->getPagenation($page, $pageCount, "/", "search", "");
      }

      $self->{SearchResultsRows} = $ResultsRows;
      if($SearchResultsCount == 1){
         $self->{ResultsCount} = "$SearchResultsCount list";
      }else{
         $self->{ResultsCount} = "$SearchResultsCount lists";
      }
      

      if($self->{cgi}->{IncludeUsersPrivateLists}){
         $self->{cgi}->{IncludeUsersPrivateLists} = "checked";
      }

      $content = $self->getPage("$Lists::SETUP::DIR_PATH/search.html");
   }else{
      $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'BLANK_SERACH_QUERY'};
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/index.html");
   }

   return $content;
}

=head2 SearchUsers

Handles the Search Users process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub SearchUsers {
#############################################
   my $self = shift;

   my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                   'UserManager'=>$self->{UserManager}, 'cgi' => $self->{cgi});
   my $ListsHash = $SearchModule->doBasicUserSearch($self->{cgi}->{Query});

   my $ResultsRows = $SearchModule->processSearchResults("$Lists::SETUP::DIR_PATH/user_search_rows.html", $ListsHash);

   $self->{SearchResultsRows} = $ResultsRows;
   $self->{Pagenation} = "Pages";

   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/user_search.html");

   return $content;
}

=head2 SendForgotPassword

If we have an account for the email address in cgi->Email, we send the reminder 
email to the email address and tell the user we did so. If we don't have an account
for the email address passed, we tell the user so.

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $content - the content to be printed

=back

=cut

#############################################
sub SendForgotPassword {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::SendForgotPassword");

   # Do we have an account with this email address?
   my $content = "";
   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->getUserByEmail($self->{cgi}->{Email});
   if($User->{ID}){
      my $UserID = $User->{ID};

      $User->{Password} = $self->{UserManager}->generateAndSetNewPassword($UserID);
      
      $self->sendAccountDetailsEmail($User);
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/sentforgotpassword.html");
   }else{
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_EMAIL_FOUND'} . $self->{cgi}->{Email}. '<br />';
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/forgotpassword.html");
   }

   return $content;
}

=head2 UploadImage

Given a filename and file handle from cgi, save an uploaded image

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListsManager object
   2. $filename - The file name of the image being uploaded
   3. $fileHandle - The file handle of the image being uploaded
   4. $alt - The alt text for the image

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub UploadImage {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::UploadImage"); 

   my $filename = $self->{cgi}->{"imageFile"};
   my $fileHandle = $self->{cgi}->{"UploadimageFile"};
   my $alt = "";

   my $content = "";
   if($filename){
      # If there's an image, we have to save it    

      # Test for acceptable extensions
      my $extension;
      if($filename =~ m/\.(\w+)$/){
         $extension = $1;
      }
      $extension = lc($extension);
      my $imageTypePermitted = 0;
      foreach my $ext(@Lists::SETUP::PERMITTED_IMAGE_EXTENSIONS) {
         if($extension eq $ext){
            $imageTypePermitted = 1;
         }
      }
      if(! $imageTypePermitted){
         $self->{ErrorMessages} .= $Lists::SETUP::MESSAGES{'NOT_PERMITTED_IMAGE_TYPE'};
         my $content = $self->processPage("$Lists::SETUP::DIR_PATH/upload_image.html");
         return $content;
      }    
	
      # Save the entry in the Image table, with original name
      my %Image = ("Image.Filename" => $filename,
                   "Image.Alt" => $alt,
                   "Image.Status" => 1,
                   "Image.Extension" => $extension,
                   "Image.UserID" => $self->{UserManager}->{ThisUser}->{ID},
                );

      my $ImageObj = $self->{DBManager}->getTableObj("Image");
      my $ImageID = $ImageObj->store(\%Image);
      if($ImageID =~ m/\D+/){
         # Error!
         $self->{ErrorMessages} = $ImageID;
         return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      }

      $self->{"Image.ID"} = $ImageID;

      my $directory = $self->{UserManager}->getUsersDirectory($self->{UserManager}->{ThisUser}->{ID});

      # Save image to users directory
      my $userfile = "$Lists::SETUP::USER_CONTENT_DIRECTORY/$directory/$ImageID.$extension";

      if(! open (IMAGE, "+>$userfile")){
         my $error = "Cannot write file: $userfile $!";
         $self->{Debugger}->throwNotifyingError($error);
         $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
         return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      }
      print IMAGE $fileHandle;
      close (IMAGE); 
      $self->{Debugger}->debug("should have written image: $userfile"); 

      # Rezize image
      use Lists::Utilities::ImageResizer;
      my $ImageResizer = new Lists::Utilities::ImageResizer(Debugger => $self->{Debugger});
      if($self->{cgi}->{isAvatar}){
         $ImageResizer->resizeAvatar($userfile);
      }else{
         $ImageResizer->resizeImage($userfile);
      }

      my $userContentDir = $Lists::SETUP::USER_CONTENT_DIRECTORY;
      $userContentDir =~ s/$Lists::SETUP::DIR_PATH\///;

      $self->{Debugger}->debug("should have stored image in DB"); 

      my $userContentDirectory = $Lists::SETUP::USER_CONTENT_DIRECTORY;
      $userContentDirectory =~ s/$Lists::SETUP::DIR_PATH//;
      my $imageSource = $userContentDirectory . "/" . $directory . "/" . $ImageID ."M." . $extension;
      if($self->{cgi}->{isAvatar}){
         $imageSource = $userContentDirectory . "/" . $directory . "/" . $ImageID ."A." . $extension;
      }

      my $action = $self->{cgi}->{action};
      if(! $self->{cgi}->{action}){
         $action = "avatar";
      }

      $self->{ImageJSParams}= "$ImageID, '$imageSource', '$action'";
      $self->{ImageSRC} = $imageSource;
      $self->{ImageName} = $self->{cgi}->{"imageFile"};
      if(!$self->{cgi}->{DynamicFormID}){
         $self->{cgi}->{DynamicFormID} = 0;
      }

      $content = $self->processPage("$Lists::SETUP::DIR_PATH/upload_image_success.html");
   }else{
      $self->{"ErrorMessages"} = $Lists::SETUP::MESSAGES{'IMAGE_UPLOAD_FAIL'};
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/upload_image.html");
   }

   return $content;
}

=head1 Getters and helper functions

=head2 getListNavigation

Gets the html for the lists navigation. A fairly complex function


=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the navigation
   2. $js - The javascript that powers the navigation

=back

=cut

#############################################
sub getListNavigation {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListNavigation fore UserID $self->{cgi}->{UserID}");

   my %Navigation;
   my $Lists;

   if(!$self->{cgi}->{UserID}){
      $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   }
   if(!$self->{cgi}->{UserID}){
      return ("", "");
   }

   if($self->{UserManager}->{ThisUser}->{ID} == $self->{cgi}->{UserID}){
      $Lists = $self->{ListObj}->get_with_restraints("UserID = $self->{cgi}->{UserID}");
   }else{
      $Lists = $self->{ListObj}->get_with_restraints("UserID = $self->{cgi}->{UserID} AND Public = 1");
   }

   my %ListGroupCache;
   foreach my $ID(sort{$Lists->{$a}->{Name} cmp $Lists->{$b}->{Name}} keys %{$Lists}) {
      # The lists within the list groups
      my $link;   
      if(! $ListGroupCache{$Lists->{$ID}->{ListGroupID}}){
         $ListGroupCache{$Lists->{$ID}->{ListGroupID}} = $self->{ListGroupObj}->get_field_by_ID("Name", $Lists->{$ID}->{ListGroupID});
      }
      $Lists->{$ID}->{ListGroup} = $ListGroupCache{$Lists->{$ID}->{ListGroupID}};

      my $NavClass = "Nav";
      if($self->{cgi}->{ListID} == $ID){
         $NavClass = "NavCurrent";
      }
      if($self->{UserManager}->{ThisUser}->{ID}){
         if($self->{cgi}->{ListID} == $ID){
            $link = qq~<li class="$NavClass" id="ListNav$ID" onclick="loadList($ID)">$Lists->{$ID}->{Name}</li>\n~;
         }else{
            $link = qq~<li class="$NavClass" id="ListNav$ID" onmouseover="changeClass('NavOver', this)" onmouseout="changeClass('Nav', this)" onclick="loadList($ID)">$Lists->{$ID}->{Name}</li>\n~;
         }
      }else{
         my $ListURL = $self->{ListObj}->getListURL($Lists->{$ID}, $ListGroupCache{$Lists->{$ID}->{ListGroupID}});
         if($self->{cgi}->{ListID} == $ID){
            $link = qq~<li class="$NavClass" onclick="location.href='$ListURL'"><a href="$ListURL"><div>$Lists->{$ID}->{Name}</div></a></li>\n~;
         }else{
            $link = qq~<li class="$NavClass" onclick="location.href='$ListURL'" onmouseover="changeClass('NavOver', this)" onmouseout="changeClass('Nav', this)""><a href="$ListURL"><div>$Lists->{$ID}->{Name}</div></a></li>\n~;
         }         
      }
      if(!$Navigation{$Lists->{$ID}->{ListGroupID}}){
         $Navigation{$Lists->{$ID}->{ListGroupID}}->{html} = $link;
         $Navigation{$Lists->{$ID}->{ListGroupID}}->{ListGroupName} = $ListGroupCache{$Lists->{$ID}->{ListGroupID}};
      }else{
         $Navigation{$Lists->{$ID}->{ListGroupID}}->{html} .= $link;
      }
   }

   my $SliderJS = "";
   my $Navigation = "";
   foreach my $ListGroupID (sort{$Navigation{$a}->{ListGroupName} cmp $Navigation{$b}->{ListGroupName}} keys %Navigation) {
      # The list groups
      
      $Navigation .= qq~<li id="SlideHeader$ListGroupID" class=\"NavHeader\" onmouseover="changeClass('NavHeaderOver', this)" onmouseout="changeClass('NavHeader', this)">$Navigation{$ListGroupID}->{ListGroupName}</li>\n~;
      $Navigation .= qq~<li id="Slide$ListGroupID" class="NavULContainer">\n<ul>\n$Navigation{$ListGroupID}->{html}\n</ul>\n</li>\n~;

      $SliderJS .= qq~
                     var mySlide$ListGroupID = new Fx.Slide('Slide$ListGroupID');
                     mySlide$ListGroupID.hide();
                     \$('SlideHeader$ListGroupID').addEvent('click', function(e){
                             e = new Event(e);
                             mySlide$ListGroupID.toggle();
                             e.stop();
                     });
                  ~;
   }

   if($self->{ListGroupSlideOpen}){
      $SliderJS .= qq~mySlide$self->{ListGroupSlideOpen}.toggle();~; 
   }

   if($Navigation eq ""){
      if($self->{UserManager}->{ThisUser}->{ID} == $self->{cgi}->{UserID}){
         $Navigation .= qq~<span>No lists yet</span>
         ~;
      }else{
         $Navigation .= qq~<span>No public lists</span>
         ~;
      }

      # Stop it from going through 3 times when no lists
      $SliderJS = qq~var filler = 0;~;
   }

   return $Navigation, $SliderJS;
}

=head2 RetryAmazon

Retries the amazon seach with modified parameters

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub RetryAmazon {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->RetryAmazon");

   $self->{cgi}->{ListID} = $self->{cgi}->{"ListItem.ListID"};
   my $content = $self->GetAmazonChoices();

   return $content;   
}

=head2 GetAmazonChoices

Gets choices from Amazon, and asks user to pick one

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $List

=item B<Returns :>

   1. $html - The html of the list choices

=back

=cut

#############################################
sub GetAmazonChoices {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->GetAmazonChoices");

   # For the message atop the choices
   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{ListID});
   $self->{"ListName"} = $List->{Name};

   if($self->{cgi}->{"ListItem.Name"} eq ""){
      return $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/Amazon/empty_list_item.html");
   }

   if(! $self->{cgi}->{page}){
      $self->{cgi}->{page} = 1;
   }

   use Lists::Utilities::Amazon;
   my $AmazonObj = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, cgi => $self->{cgi}, 
                                 DBManager => $self->{DBManager}, UserManager => $self->{UserManager});
   $self->{cgi}->{"ListItem.NameDecoded"} = Lists::Utilities::StringFormator::htmlDecode($self->{cgi}->{"ListItem.Name"});
   $self->{AmazonChoices} = $AmazonObj->getAmazonChoices($List, $self->{cgi}->{page});

   $self->{AmazonModeSelect} = $self->getSelectTag("AmazonMode");
   $self->{ListItemStatusSelect} = $self->{ListItemStatusObj}->getListItemStatusSetSelect($List, $self->{cgi}->{"ListItem.ListItemStatusID"}) . "<br />";
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   $self->{cgi}->{page}++;

   my $Content;
   if($self->{AmazonChoices} =~ m/^Error/){
      $self->{ErrorMessages} = $self->{AmazonChoices};
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }elsif($self->{AmazonChoices} eq ""){
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/Amazon/no_choices.html");
   }else{
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/Amazon/choices.html");
   }

   return $Content;
}

=head2 GetCCImageChoices

Gets Creative Commongs images choices from Flickr, and asks user to pick one

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $List

=item B<Returns :>

   1. $html - The html of the list choices

=back

=cut

#############################################
sub GetCCImageChoices {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->GetCCImageChoices");

   # For the message atop the choices
   my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{ListID});
   $self->{"ListName"} = $List->{Name};
   
   if($self->{cgi}->{"ListItem.Name"} eq ""){
      return $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/CCImage/empty_list_item.html");
   }
   
   use Lists::Utilities::CCImage;
   my $CCImageObj = new Lists::Utilities::CCImage(Debugger => $self->{Debugger}, cgi => $self->{cgi}, DBManager => $self->{DBManager});

   if(! $self->{cgi}->{page}){
      $self->{cgi}->{page} = 1;
   }
   
   $self->{cgi}->{"ListItem.NameDecoded"} = Lists::Utilities::StringFormator::htmlDecode($self->{cgi}->{"ListItem.Name"});
   $self->{CCImageChoices} = $CCImageObj->getCCImageChoices($self->{cgi}->{"ListItem.NameDecoded"}, $self->{cgi}->{page});
   $self->{cgi}->{UserID} = $self->{UserManager}->{ThisUser}->{ID};
   $self->setThemeID();
   $self->{cgi}->{page}++;
   
   my $Content;
   if($self->{CCImageChoices} =~ m/^500/ || $self->{CCImageChoices} =~ m/^Error/){
      $self->{ErrorMessages} = $self->{CCImageChoices};
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }elsif($self->{CCImageChoices} eq ""){
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/CCImage/no_choices.html");
   }else{
      $Content = $self->processPage("$Lists::SETUP::DIR_PATH/Utilities/CCImage/choices.html");
   }
   
   return $Content;
}


=head2 getListHTML

Gets the content of a list in HTML format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListHTML {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListHTML with $ListID");

   # Gracefilly handle no ListID
   if(! $ListID){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_LIST_ID'};
      $self->{Debugger}->throwNotifyingError("No ListID in getListHTML, User: $self->{UserManager}->{ThisUser}->{ID}");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }

   # Get the List info
   my $List = $self->{ListObj}->get_by_ID($ListID);

   # Reject if private and not the list owner
   if(!$List->{Public} && $self->{UserManager}->{ThisUser}->{ID} != $List->{UserID}){
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_PERMISSION_VIEW_LIST'};
      $self->{Debugger}->throwNotifyingError("User ($self->{UserManager}->{ThisUser}->{ID}) tried to view private list($List->{UserID}) that isn't theirs");
      my $content = $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      return $content;
   }    


   # Get list information
   $self->{cgi}->{UserID} = $List->{UserID};
   $self->setThemeID();
   $self->{ListObj}->getListInfo($List, $self->{DBManager}, $self->{UserManager}, 0);

    # Log the List Hit
   $self->logListHit($List, "");

   my $ListItemStatuses = $self->{ListItemStatusObj}->get_with_restraints("StatusSet = $List->{StatusSet}");

   # Get the more, for second or higher page
   if($self->{cgi}->{page} > 1){
      my ($ListsNormalHTML, $ListItemCount);
      if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
         ($ListsNormalHTML, $ListItemCount) = $self->getListView("owner", $List, $ListItemStatuses);
      }else{
         ($ListsNormalHTML, $ListItemCount) = $self->getListView("viewer", $List, $ListItemStatuses);
      }
      
      return $ListsNormalHTML;
   }

   # First page from here on
   my $ListItemCount;
   my $ListsNormalHTML;
   if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
      # If this list belongs to the user

      my $ordering = "ASC";
      if($List->{Ordering} eq "d"){
         $ordering = "DESC";
      }
         
      my $AllListItems = $self->{ListItemObj}->get_with_restraints("ListID = $ListID", "ListItemStatusID ASC, PlaceInOrder $ordering");
      $self->{ListItemObj}->getListItemsInfo($AllListItems, $List, $self->{Editor});
      ($self->{ListsReorder}, $self->{ListsReorderJS}) = $self->getListReorderViewHTML($List, $AllListItems, $ListItemStatuses);

      ($ListsNormalHTML, $ListItemCount) = $self->getListView("owner", $List, $ListItemStatuses);
      $self->{ListsNormal} = $ListsNormalHTML;
   }else{
      ($ListsNormalHTML, $ListItemCount) = $self->getListView("viewer", $List, $ListItemStatuses);
      $self->{ListsNormal} = $ListsNormalHTML;
   }

   # The list ratings
   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
   my $Clickable = $self->isListRatingClickable($List->{UserID});
   my($ListRatingsHTML, $ListRatingsText) = $ListRatingsObj->getListRatingsHTML($List->{ID}, $Clickable);

   $self->{ListRating} = "$ListRatingsHTML";
   $self->{ListURL} = $List->{ListURL};

   # The forms
   if(! $self->{"DontShowListForm"}){
      $self->{ListForm} = $self->getListForm($List);
      $self->{ListFormEdit} = $self->getListFormEdit($List);
   }

   $self->{Keywords} = "List, $List->{Name}, $List->{StrippedTags}";
   if($List->{ID} == $Lists::SETUP::CONSTANTS{'FAQ_LISTID'}){
      $self->{PageTitle} = "list central faqs";
   }else{
      my $ListName = $List->{Name};
      $ListName =~ s/&amp;/&/g;
      $self->{PageTitle} = "lc: $ListName a list by $List->{Username}";
   }
   

   my $content = "";
   my $template = "$Lists::SETUP::DIR_PATH/listpieces/list.html";
   if($ListItemCount == 0){
      $template = "$Lists::SETUP::DIR_PATH/listpieces/emptylist.html";
   }
   if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
      $template =~ s/$Lists::SETUP::DIR_PATH/$Lists::SETUP::DIR_PATH\/owner/;
   }elsif($self->{UserManager}->{ThisUser}->{ID} && -e "$Lists::SETUP::DIR_PATH/loggedin/listpieces/emptylist.html"){
      $template =~ s/$Lists::SETUP::DIR_PATH/$Lists::SETUP::DIR_PATH\/loggedin/;
   }

   my $UserObj = $self->{DBManager}->getTableObj("User"); 
   $self->{ListCreator} = $UserObj->get_field_by_ID('Name', $List->{UserID});

   foreach my $field (keys %{$List}) {
      $self->{$field} = $List->{$field};
   }
   $self->{ListID} = $List->{ID};
   $self->{List} = $List;

   
   $self->{ListNameQ} = $List->{Name};
   $self->{ListNameQ} =~ s/\'/\\\'/g;
   $self->{ListNameQ} =~ s/&amp;/&/g;

   # For the color of the wysiwyg editor
   my $ThemeColoursObj = $self->{DBManager}->getTableObj("ThemeColours");
   my $Colors = $ThemeColoursObj->get_with_restraints("ThemeID = $self->{ThemeID} AND Position = 3");
   foreach my $ID(keys %{$Colors}) {
      # There should be only one
      $self->{ThemeColor3} = $Colors->{$ID}->{Colour};
   }

   $self->{ListItemStatusSetJSArray} = $self->{ListItemStatusObj}->getListItemStatusSetJSArray($ListID, $self->{DBManager});

   my $content = $self->getPage($template);

   return $content;
}

=head2 getListView

Gets the content of a list in HTML format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListView {
#############################################
   my $self = shift;
   my $type = shift;
   my $List = shift;
   my $ListItemStatuses = shift;

   $self->{Debugger}->debug("in ListsManager::getListView");

   my ($ListItems, $MoreItems) = $self->{ListItemObj}->getListItems($List, $self->{cgi}->{"page"});
   my $ListCount = scalar keys(%{$ListItems});

   my %ListView;
   my $ShowFirstStatus = 0; my $FirstStatus;
   if($ListCount != 0){
      # Initialize all the hash options
      foreach my $ID(keys %{$ListItems}) {
         if($ListView{$ListItems->{$ID}->{ListItemStatusID}} ne ""){
            $ListView{$ListItems->{$ID}->{ListItemStatusID}} = "";
         }
      }

      # Get the extra info for all the list items
      $self->{ListItemObj}->getListItemsInfo($ListItems, $List, $self->{Editor});

      # Build the html for the list items      
      my $checkedShowFirstStatus = 0;
      foreach my $ListItemID(sort{$ListItems->{$a}->{SortOrder} <=> $ListItems->{$b}->{SortOrder}} keys %{$ListItems}) {

         # The "More" button repeats the status title without this check
         if($self->{cgi}->{page} > 1 && !$checkedShowFirstStatus){
            my $MinPlaceInOrder = $self->{ListItemObj}->getMinPlaceInOrder($List->{ID}, $ListItems->{$ListItemID}->{ListItemStatusID});
            if($ListItems->{$ListItemID}->{PlaceInOrder} <=  $MinPlaceInOrder){
               $ShowFirstStatus = 1;
               $FirstStatus = $ListItems->{$ListItemID}->{ListItemStatusID}
            }
            $checkedShowFirstStatus = 1;
         }

         my $type = "viewer";
         if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
            $type = "owner";
         }

         $ListItems->{$ListItemID}->{Extra} = $self->getListItemExtra($ListItems->{$ListItemID}, $List);
         $self->{Debugger}->debug("Extra: " .$ListItems->{$ListItemID}->{Extra});
         $ListView{$ListItems->{$ListItemID}->{ListItemStatusID}} .= $self->getListItemHTML($type, $ListItems->{$ListItemID}, $List);
      }
   }

   my $listTypeClass = " Bullets";
   if($List->{ListTypeID} == 2){
      $listTypeClass = " Numbers";
   }elsif($List->{ListTypeID} == 3){
      $listTypeClass = " Letters";
   }
   my $ListView = "";
   my $FoundOneStatus = 0;
   if($ListCount != 0){
      foreach my $status (sort keys %ListView) {
         my $StatusName = $ListItemStatuses->{$status}->{Name};
         if($StatusName eq "" || $StatusName eq "None"){
            $StatusName = qq~<h2>&nbsp;</h2>~;
         }else{
            $StatusName = qq~<h2>$StatusName</h2>~;
         }
         
         if($ListView{$status}){
            # For the "More" style paging
            if(! (!$self->{cgi}->{page} || $self->{cgi}->{page} == 1 || $ShowFirstStatus)){
               $ListView .= qq~
                           <ul class="ListNormalView$listTypeClass">
                              $ListView{$status}
                           </ul>~;
            }else{
               $ListView .= qq~$StatusName
                           <ul class="ListNormalView$listTypeClass">
                              $ListView{$status}
                           </ul>~;
            }       
            $FoundOneStatus = 1;
         }
      }
   }

   my $MoreButton = "";
   if($MoreItems){
      my $page = $self->{cgi}->{page};
      if(!$page){
         $page = 1;
      }
      my $nextPage = $page + 1;

      if($self->{cgi}->{page} > 1){
         my $Div = "More" . $self->{cgi}->{page};
         $MoreButton = qq~<div id="$Div"><div class="MoreButtonContainer"><a href="javascript:loadMoreList($List->{ID}, $nextPage, '$Div')" class="MoreButton">&nbsp;</a></div></div>~;
      }else{
         $MoreButton = qq~<div id="More"><div class="MoreButtonContainer"><a href="javascript:loadMoreList($List->{ID}, $nextPage, 'More')" class="MoreButton">&nbsp;</a></div></div>~;
      }
      
      $ListView .= $MoreButton;   
   }
   
   return ($ListView, $ListCount);
}

=head2 getListReorderViewHTML

Gets the content of a list in HTML format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListReorderViewHTML {
#############################################
   my $self = shift;
   my $List = shift;
   my $ListItems = shift;
   my $ListItemStatuses = shift;

   $self->{Debugger}->debug("in ListManager::getListReorderViewHTML");

   my $ListsCount = scalar keys(%{$ListItems});

   my %ListsReorder;
   if($ListsCount != 0){

      foreach my $ID(keys %{$ListItems}) {
         if($ListsReorder{$ListItems->{$ID}->{ListItemStatusID}} ne ""){
            $ListsReorder{$ListItems->{$ID}->{ListItemStatusID}} = "";
         }
      }

      # Build the html for the list items
      foreach my $ListItemID(sort{$ListItems->{$a}->{SortOrder} <=> $ListItems->{$b}->{SortOrder}} keys %{$ListItems}) {
         $ListsReorder{$ListItems->{$ListItemID}->{ListItemStatusID}} .= $self->getListItemHTML("reorder", 
                                                                                 $ListItems->{$ListItemID}, $List);
      }
   }

   my $ListsReorder = "";
   my $ListReorderJS = "";
   if($ListsCount != 0){
      foreach my $status (sort keys %ListsReorder) {
         my $StatusName = $ListItemStatuses->{$status}->{Name};
         if($StatusName eq "" || $StatusName eq "None"){
            $StatusName = qq~<h2>&nbsp;</h2>~;
         }else{
            $StatusName = qq~<h2>$StatusName</h2>~;
         }
         if($ListsReorder{$status}){
            $ListsReorder .= qq~$StatusName
                               <ul class="ListReorderView" id="Sortable$status">
                                 $ListsReorder{$status}
                              </ul>~;

            $ListReorderJS .= qq~var sortable$status = new Sortables(\$('Sortable$status'), {
                                     constrain: true,
                                     clone: true,
                                     revert: true
                                 });
                                 SortableListArray['Sortable$status'] = sortable$status;
                                ~;
         }
      }
   }
   return ($ListsReorder, $ListReorderJS);
}

=head2 getListItemExtra

Gets the content of a list in HTML format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListItemExtra {
#############################################
   my $self = shift;
   my $ListItem = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListManager::getListItemExtra with $ListItem->{Name}");
   my $template;
   my $Templates = $self->getListItemTemplateHash("extra");

   if($ListItem->{"AmazonID"}){
      my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager}, 
                                                   UserManager => $self->{UserManager});
      ($ListItem->{AmazonLink}, $ListItem->{AmazonImage}) = $Amazon->getAmazonLinkAndImage($ListItem->{"AmazonID"});
      
      $template = $Templates->{"amazon"};
   }elsif($ListItem->{"CCImageID"}){
      my $CCImageObj = $self->{DBManager}->getTableObj("CCImage");
      my $CCImage = $CCImageObj->get_by_ID($ListItem->{CCImageID});
      $ListItem->{CCImage} = $CCImage->{Image};
      $ListItem->{Source} = $CCImage->{Source};
      $ListItem->{Credit} = $CCImage->{Credit};
      $template = $Templates->{"ccimage"};
   }elsif($ListItem->{"ImageID"}){
      my $ImageObj = $self->{DBManager}->getTableObj("Image");
      my $Image = $ImageObj->get_by_ID($ListItem->{ImageID});

      my $usersdir = $self->{UserManager}->getUsersDirectory($List->{UserID});
      $ListItem->{ImagePath} = "/usercontent/$usersdir/$ListItem->{ImageID}M.$Image->{Extension}";
      $ListItem->{ImageLink} = "/usercontent/$usersdir/$ListItem->{ImageID}L.$Image->{Extension}";
      $template = $Templates->{"image"};
   }elsif($ListItem->{"EmbedID"}){
      my $EmbedObj = $self->{DBManager}->getTableObj("Embed");
      my $Embed = $EmbedObj->get_by_ID($ListItem->{EmbedID});
      $ListItem->{Embed} = $Embed->{EmbedCode};

      # Handle the width & height busniess
      my $width; my $height;
      if($ListItem->{Embed} =~ m/width="(\d+)"/){
         $width = $1;
      }
      if($ListItem->{Embed} =~ m/height="(\d+)"/){
         $height = $1;
      }
      if($width > $Lists::SETUP::CONSTANTS{'EMBED_MAX_WIDTH'}){
         my $newWidth = $Lists::SETUP::CONSTANTS{'EMBED_MAX_WIDTH'};
         my $newHeight = int(($height * $newWidth) / $width);

         $self->{Debugger}->debug("width: $width, height: $height, newWidth: $newWidth, newHeight, $newHeight");
         $ListItem->{Embed} =~ s/width="$width"/width="$newWidth"/g;
         $ListItem->{Embed} =~ s/height="$height"/height="$newHeight"/g;
      }

      # Fix the z-index business
      $ListItem->{Embed} =~ s/<embed/<param name="wmode" value="transparent"><\/param><embed wmode="transparent" /;

      $template = $Templates->{"embed"};
   }

   my $ListItemExtra = ""; 
   
   
   while($template =~ m/<!--ListItem\.(\w+)-->/g){
      my $field = $1;
      $template =~ s/<!--ListItem\.$field-->/$ListItem->{$field}/g;  
   }
   while($template =~ m/<!--SETUP\.([\w_]+)-->/g){
      my $variable = $1;
      $template =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/g;
   }
   $ListItemExtra = $template;

   return $ListItemExtra;
    
}


=head2 getListItemTemplateHash

Gets the content of a list in HTML format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListItemTemplateHash {
#############################################
   my $self = shift;
   my $piece = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListTemplateHash $piece $self->{TemplateHash}");

   if($self->{TemplateHash}->{$piece}){
      return $self->{TemplateHash}->{$piece};
   }else{
      # open listpieces dir
      my $ListPiecesDir = "$Lists::SETUP::DIR_PATH/listpieces";
      if(! opendir (DIR, $ListPiecesDir)){
         my $error = "can't opendir $ListPiecesDir: $!";
         $self->{Debugger}->throwNotifyingError($error);
         $self->{ErrorMessages} = $error;
         return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
      }
   
      my @files = grep {-f "$ListPiecesDir/$_" } readdir(DIR);
      closedir DIR;
   
      # foreach file, if starts with 'list_item', put in template hash
      my %Templates;
      foreach my $file(@files) {
         if($piece eq "list_item"){
            if($file =~ m/list_item_([\w_]+)\.html/){
               my $filename = "$Lists::SETUP::DIR_PATH/listpieces/$file";
               my $template_type = $1;
               if(! open(PAGE, $filename) ){
                  my $error = "cannot open file: $filename - $!";
                  $self->{Debugger}->throwNotifyingError($error);
                  $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
                  return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
               }
               my @lines = <PAGE>;
               close PAGE;
               $Templates{$template_type} = "";
               foreach my $line (@lines) {
                  $Templates{$template_type} .= $line;
               }
            }
         }else{
            if($file =~ m/extra_([\w_]+)\.html/){
               my $filename = "$Lists::SETUP::DIR_PATH/listpieces/$file";
               my $template_type = $1;
               if(! open(PAGE, $filename) ){
                  my $error = "cannot open file: $filename - $!";
                  $self->{Debugger}->throwNotifyingError($error);
                  $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
                  return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
               }
               my @lines = <PAGE>;
               close PAGE;
               $Templates{$template_type} = "";
               foreach my $line (@lines) {
                  $Templates{$template_type} .= $line;
               }
            }
         }
      }
      $self->{TemplateHash}->{$piece} = \%Templates;
      return $self->{TemplateHash}->{$piece};
   }
}


=head2 getListElement

Given an arrary of lines and a hash ref of ListItem info, returns the html for the list item

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListElement {
#############################################
   my $self = shift;
   my $page = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListElement $page and LIST: $List");

   if($self->{ListElementCache}->{$page}->{$List}->{ID}){
      return $self->{ListElementCache}->{$page}->{$List}->{ID};
   }

   if(! open(PAGE, $page) ){
      my $error = "cannot open file: $page - $!";
      $self->{Debugger}->throwNotifyingError($error);
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   my @lines = <PAGE>;
   close PAGE;

   my $content = "";
   foreach my $line (@lines) {
      while($line =~ m/<!--/g){
         if($line =~ m/<!--List\.(\w+)-->/){
            my $element = $1;
            
            my $value = "";
            if($element eq "CreateDateFormatted"){
               $value = Lists::Utilities::Date::getShortHumanFriendlyDate($List->{CreateDate});
            }else{
               $value = $List->{$element};
            }
            $line =~ s/<!--List\.$element-->/$value/;
         }
         if($line =~ m/<!--ListRating-->/){
            my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
            my $Clickable = $self->isListRatingClickable($List->{UserID});
            my ($ListRatingsHTML, $ListRatingsText) = $ListRatingsObj->getListRatingsHTML($List->{ID}, $Clickable);
            $line =~ s/<!--ListRating-->/$ListRatingsHTML $ListRatingsText/;
         }
         if($line =~ m/<!--SETUP\.(\w+)-->/){
            my $field = $1;
            $line =~ s/<!--SETUP\.$field-->/$Lists::SETUP::CONSTANTS{$field}/;
         }
      }
      $content .= $line;
   }

   $self->{ListElementCache}->{$page}->{$List}->{ID} = $content;
   return $content;
}


=head2 getListItemHTML

Given an arrary of lines and a hash ref of ListItem info, returns the html for the list item

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListItemHTML {
#############################################
   my $self = shift;
   my $type = shift;
   my $ListItem = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListItemHTML with $type, Item: $ListItem->{Name}");
   
   my $Templates = $self->getListItemTemplateHash("list_item");
   
   my $template = $Templates->{$type};

   my $ListItemHTML = "";       
   while($template =~ m/<!--ListItem\.(\w+)-->/g){
      my $field = $1;
      $template =~ s/<!--ListItem\.$field-->/$ListItem->{$field}/g;  

      #if($ListItem->{AmazonID} && $edit && ($field eq "Linkhref" || $field eq "ImageID" || $field eq "ImagePath")){
      #   $template =~ s/<!--ListItem\.$field-->//g;
      #}else{
      
      #}
   }
   while($template =~ m/<!--SETUP\.([\w_]+)-->/g){
      my $variable = $1;
      $template =~ s/<!--SETUP\.$variable-->/$Lists::SETUP::CONSTANTS{$variable}/g;
   }
   $ListItemHTML .= $template;

   return $ListItemHTML;
}

=head2 getListEmail

Gets the content of a list in TXT format

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListEmail {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListEmail with $ListID");

   my $List = $self->{ListObj}->get_by_ID($ListID);
   my $ListGroup = $self->{ListGroupObj}->get_by_ID($List->{ListGroupID});
   my $ListURL =  $Lists::SETUP::URL . $self->{ListObj}->getListURL($List, $ListGroup->{Name});
   my $ListItemStatuses = $self->{ListItemStatusObj}->get_with_restraints("StatusSet = $List->{StatusSet}");
   $self->{ListName} = $List->{Name};

   my $LinkObj = $self->{DBManager}->getTableObj("Link");
   my $ImageObj = $self->{DBManager}->getTableObj("Image");
   my $CCImageObj = $self->{DBManager}->getTableObj("CCImage");
   my $Amazon = new Lists::Utilities::Amazon(Debugger => $self->{Debugger}, DBManager => $self->{DBManager},
                                                   UserManager => $self->{UserManager});

   my $imageCount = 0; my $truncatedMsg = "";
   my %ListsHTML; my %ListsTXT;
   my $liStyle = 'style=3D"margin-bottom:5px;"';
   my $ListItems = $self->{ListItemObj}->get_with_restraints("ListID = $ListID");
   foreach my $ListItemID(sort{$ListItems->{$a}->{PlaceInOrder} <=> $ListItems->{$b}->{PlaceInOrder}} keys %{$ListItems}) {
      if($truncatedMsg ne ""){
         next;
      }
      my $ListItem = $ListItems->{$ListItemID}->{Name};

      my $Link; my $Image;
      if($ListItems->{$ListItemID}->{LinkID}){
         # Regular link
         $Link = $LinkObj->get_field_by_ID("Link", $ListItems->{$ListItemID}->{LinkID});
         $ListItem = qq~<a href=3D"$Link" style=3D"color:#1d687a; font-weight:bold;">$ListItem</a>~;
      }elsif($ListItems->{$ListItemID}->{AmazonID}){
         # Amazon link
         ($Link, $Image) = $Amazon->getAmazonLinkAndImage($ListItems->{$ListItemID}->{AmazonID});
         $ListItem = qq~<a href=3D"$Link" style=3D"color:#1d687a; font-weight:bold;">$ListItem</a>~;
      }	 
      if($ListItems->{$ListItemID}->{ImageID} || $ListItems->{$ListItemID}->{CCImageID} || $ListItems->{$ListItemID}->{AmazonID}){
         # images, and amazon images
         if($imageCount < $Lists::SETUP::CONSTANTS{'IMAGE_IN_EMAIL_LIMIT'}){
            if($ListItems->{$ListItemID}->{ImageID}){
               my $Image = $ImageObj->get_by_ID($ListItems->{$ListItemID}->{ImageID});
               my $path = $self->{UserManager}->getUsersDirectory($List->{UserID});
               my $src = $Lists::SETUP::URL . $Lists::SETUP::USER_CONTENT_PATH . "/" . $path . "/" . $ListItems->{$ListItemID}->{ImageID} . "M." . $Image->{Extension};
               $ListItem = qq~$ListItem<br /><a href=3D"$Link"><img src=3D"$src" alt="$ListItems->{$ListItemID}->{Name}" /></a>\n~;
            }elsif($ListItems->{$ListItemID}->{CCImageID}){
               my $CCImage = $CCImageObj->get_by_ID($ListItems->{$ListItemID}->{CCImageID});
               my $src = $CCImage->{Image};
               $ListItem = qq~$ListItem<br /><a href=3D"$CCImage->{Source}"><img src=3D"$src" alt="$ListItems->{$ListItemID}->{Name}" /></a>\n~;
            }elsif($ListItems->{$ListItemID}->{AmazonID}){
               $ListItem = qq~<a href=3D"$Link">$ListItem<br /><img src=3D"$Image" alt="$ListItems->{$ListItemID}->{Name}" /></a>\n~;
            }
            
            $imageCount++;
         }else{
            $truncatedMsg = $Lists::SETUP::MESSAGES{'TRUNCATED_EMAIL_MESSAGE'};
         }
      }elsif($ListItems->{$ListItemID}->{EmbedID}){
         $ListItem .= qq~<p>[List item includes embedded content that has been omitted]</p>\n~;
      }

      my $DescriptionHTML = "";
      my $DescriptionTXT = "";
      if($ListItems->{$ListItemID}->{Description}){
         $DescriptionHTML = "$ListItems->{$ListItemID}->{Description}";
         $DescriptionTXT = "$ListItems->{$ListItemID}->{Description}\n";
      }
      
      if(!$ListsHTML{$ListItems->{$ListItemID}->{ListItemStatusID}}){
         $ListsTXT{$ListItems->{$ListItemID}->{ListItemStatusID}} = "- $ListItems->{$ListItemID}->{Name}\n$DescriptionTXT";
         $ListsHTML{$ListItems->{$ListItemID}->{ListItemStatusID}} = "<li $liStyle>$ListItem $DescriptionHTML</li>\n";
      }else{
         $ListsTXT{$ListItems->{$ListItemID}->{ListItemStatusID}} .= "- $ListItems->{$ListItemID}->{Name}\n$DescriptionTXT";  
         $ListsHTML{$ListItems->{$ListItemID}->{ListItemStatusID}} .= "<li $liStyle>$ListItem $DescriptionHTML</li>\n";  
      }  
   }

   my $ListsTXT = "";
   my $ListsHTML = "";
   foreach my $status (sort keys %ListsHTML) {
      if($ListsHTML{$status}){
         if($ListItemStatuses->{$status}->{Name}){
            $ListsHTML .= qq~<b style=3D"font-size:15px;">$ListItemStatuses->{$status}->{Name}</b>\n~;
            $ListsTXT .= "$ListItemStatuses->{$status}->{Name}\n";
         }         

         $ListsHTML .= "<ul>$ListsHTML{$status}</ul>";         
         $ListsTXT .= "$ListsHTML{$status}";
      }
   }

   if($ListsHTML eq ""){
      $ListsHTML = "No list items";
      $ListsTXT = "No list items";
   }

   my $UserObj = $self->{DBManager}->getTableObj("User"); 
   my $ListCreatorUser = $UserObj->get_by_ID($List->{UserID}); 
   $ListCreatorUser->{"UserURL"} = $Lists::SETUP::URL . $self->{UserManager}->getUserURL($ListCreatorUser);

   my $User;
   if($self->{UserManager}->{ThisUser}->{ID}){
      $User = $UserObj->get_by_ID($self->{UserManager}->{ThisUser}->{ID});
      $User->{"UserURL"} = $self->{UserManager}->getUserURL($User);
   }


   my %Data;
   $Data{"ListBodyTXT"} = $ListsTXT;
   $Data{"ListBodyHTML"} = $ListsHTML;
   $Data{"Message"} = $self->{cgi}->{EmailMessage};
   if($Data{"Message"}){
      $Data{"Message"} = $Data{"Message"};
   }
   $Data{"ListCreator"} = $ListCreatorUser;
   $Data{"User"} = $User;

   $Data{"TruncatedMessage"} = "<p>$truncatedMsg</p>";

   $List->{"ListURL"} = $ListURL;
   $List->{"ListGroup"} = $ListGroup->{Name};
   $Data{"List"} = $List;

   # The user link of the person logged in, if someone was logged in
   $Data{"EmailFrom"} = qq~by <a href=3D"$Lists::SETUP::URL$User->{UserURL}" style=3D"color:#1d687a;font-weight:bold;">$User->{Username}</a>~;

   $Data{"BodyTXT"} = $self->processPage("$Lists::SETUP::DIR_PATH/emails/list.txt", \%Data);
   $Data{"BodyHTML"} = $self->processPage("$Lists::SETUP::DIR_PATH/emails/list.html", \%Data);

   my $text = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);
   my $html = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   return ($html, $text, $boundary);
}

=head2 getListForm

Gets the html for the form to add new list items, tags, and comments

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list form

=back

=cut

#############################################
sub getListForm {
#############################################
   my $self = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListsManager getListForm");

   my $template = "$Lists::SETUP::DIR_PATH/listpieces/listform.html";
   if($self->{UserManager}->{ThisUser}->{ID} == $List->{UserID}){
      $template =~ s/$Lists::SETUP::DIR_PATH/$Lists::SETUP::DIR_PATH\/owner/;
   }elsif($self->{UserManager}->{ThisUser}->{ID}){
	$template =~ s/$Lists::SETUP::DIR_PATH/$Lists::SETUP::DIR_PATH\/loggedin/;
   }

   my %DataExtra;
   $DataExtra{"action"} = "Add";
   $DataExtra{"ExtraDisplay"} = "display: none";
   my $ExtrElement = $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_element.html", \%DataExtra);
   my $ExtraHiddenFields = $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/form_element_extra_hidden_fields.html", \%DataExtra);

   my %Data;
   $Data{"List"} = $List;
   $Data{"ListItemStatusSelect"} = $self->{ListItemStatusObj}->getListItemStatusSetSelect($List, -1);
   $Data{"ExtraElement"} = $ExtrElement;
   $Data{"ExtraHiddenFields"} = $ExtraHiddenFields;

   my $content = $self->processPage($template, \%Data);

   return $content;
}

=head2 getListFormEdit

Gets the html for the form to edit the list details, should not be served to 
anyone except the list owner

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list form

=back

=cut

#############################################
sub getListFormEdit {
#############################################
   my $self = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListsManager getListFormEdit");

   if($List->{UserID} != $self->{UserManager}->{ThisUser}->{ID}){
      return "";
   }

   my %Data;
   $Data{"List"} = $List;

   my $template = "$Lists::SETUP::DIR_PATH/owner/listpieces/listformedit.html";
   my $content = $self->processPage($template, \%Data);

   return $content;
}

=head2 getListComments

Gets the Comments of a certain list

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list Comments

=back

=cut

#############################################
sub getListComments {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getListComments with $ListID");

   if(!$ListID){
      $ListID = $self->{cgi}->{"ListID"};
   }

   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $UserObj =  $self->{DBManager}->getTableObj("User");

   my $List = $self->{ListObj}->get_by_ID($ListID);

   $self->{Debugger}->debug("--------- ListID: $ListID, UserID: $List->{UserID}");

   $self->{cgi}->{UserID} = $List->{UserID};
   $self->setThemeID();

   # Pagenation on list comments
   my $page = $self->{cgi}->{page}  ? $self->{cgi}->{page}: 1;
   my ($ListComments,$pageCount) = $CommentObj->getListComments($List, $page);

   my $Comments = "";
   my $EvenOrOdd = "Odd";
   foreach my $ID (sort{$ListComments->{$b}->{CreateDate} <=> $ListComments->{$a}->{CreateDate}}keys %{$ListComments}) {
      my $Comment = $ListComments->{$ID};

      $Comment->{'CreateDateFormatted'} = Lists::Utilities::Date::getShortHumanFriendlyDate($Comment->{'CreateDate'});
      
      my $Commenter = $UserObj->get_by_ID($Comment->{CommenterID});
      if($Comment->{CommenterID}){
         my $url = $self->{UserManager}->getUserURL($Commenter);
         $Commenter->{'Commenter'};
         $Commenter->{'CommenterURL'} = "$url";
         $self->{UserManager}->getUserAvatar($Commenter);
      }

      if($EvenOrOdd eq "Odd"){
         $EvenOrOdd = "Even";
      }else{
         $EvenOrOdd = "Odd";
      }

      my %Comment = ('Comment' => $Comment,
                     'Commenter' => $Commenter,
                     'EvenOrOdd' => $EvenOrOdd);

      if($List->{UserID} == $self->{UserManager}->{ThisUser}->{ID} || $Comment->{CommenterID} == $self->{UserManager}->{ThisUser}->{ID}){
         $Comments .= $self->processPage("$Lists::SETUP::DIR_PATH/owner/listpieces/list_comment.html", \%Comment);      
      }else{
         $Comments .= $self->processPage("$Lists::SETUP::DIR_PATH/listpieces/list_comment.html", \%Comment);      
      }      
   }

   if($Comments eq ""){
      $Comments = "<p class='NoComments'>No comments</p>";
   }else{
      my $CommentNewerLink; my $CommentNewestLink; 
      my $CommentOlderLink; my $CommentOldestLink; 

      if($page < $pageCount){
         my $nextPage = $page + 1;
         $CommentOlderLink = qq~<a href="javascript:getListComments($ListID, 'page=$nextPage')" class="CommentsOlderLink">Older >></a>~;
      }
      if($page > 1){
         my $prevPage = $page - 1;
         $CommentNewerLink = qq~<a href="javascript:getListComments($ListID, 'page=$prevPage')" class="CommentsNewerLink"><< Newer</a>~;
      }
      if($page != $pageCount){
         $CommentOldestLink = qq~<a href="javascript:getListComments($ListID, 'page=$pageCount')" class="CommentsOldestLink">Oldest >></a>~;
      }
      if($page != 0){
         $CommentNewestLink = qq~<a href="javascript:getListComments($ListID, 'page=1')" class="CommentsNewestLink"><< Newest</a>~;
      }

      $Comments = qq~$Comments
                     $CommentNewerLink
                     $CommentOlderLink~;
   }

   return $Comments;
}

=head2 getInputHTMLTag

Gets the html of a form input element

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
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
         #<!--Input.Select.AmazonModes.Mode.Name.AmazonMode--> 
         # Input.Select.Table.Value.Display.name
         my $input_type = $1;
         my $table = $2;
         my $value = $3;
         my $display = $4;
         my $name = $5;

         my $id = $name;
         if($id =~ m/_/){
            my @temparray = split(/_/, $id);
            $id = $temparray[1];
         }
         
         if($input_type eq "Select"){
            my $options = "";
            my $TableObj = $self->{DBManager}->getTableObj($table);
            my $Hash = $TableObj->get_all();
            my $thing = "$table$value";
            foreach my $ID (sort {$a <=> $b} keys %{$Hash}) {
               if($self->{cgi}->{"$thing"} eq $ID){
                  $options .= qq~<option value="$Hash->{$ID}->{$value}" selected="selected">$Hash->{$ID}->{$display}</option>
                              ~;
               }else{
                  $options .= qq~<option value="$Hash->{$ID}->{$value}">$Hash->{$ID}->{$display}</option>
                              ~;
               }               
            }
            $input = qq~<select name="$name" id="$id" class="SelectInput">
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
            $input = qq~"<select name='$name' id='$id' class='SelectInput'>" +
                        "   <option value=''>Select</option>" +
                           $options
                        "</select>" +
                     ~;
         }
      }elsif($tag =~ m/<!--Input\.Select\.(\w+)-->/){
         my $Specification = $1;
         if($Specification eq "CreateListListGroupOptions"){
            my $options = "";
            my $TableObj = $self->{DBManager}->getTableObj("ListGroup");
            my $Hash = $TableObj->get_with_restraints("UserID = $self->{UserManager}->{ThisUser}->{ID} OR UserID = 0");
            foreach my $ID (sort keys %{$Hash}) {
               $options .= qq~<option value="$ID">$Hash->{$ID}->{Name}</option>
                              ~;
            }
            $input = qq~<select name="List.ListGroupID" id="ListGroupID" class="SelectInput">
                           <option value="">Select</option>
                           $options
                        </select>
                     ~;
         }elsif($Specification eq "CreateListStatusSetOptions"){
            my $options = "";
            my $TableObj = $self->{DBManager}->getTableObj("ListItemStatus");
            my $ListItemStatus = $TableObj->get_with_restraints("ID > 2 AND (UserID = $self->{UserManager}->{ThisUser}->{ID} OR UserID = 0)");

            my %StatusSets;
            foreach my $ID (sort keys %{$ListItemStatus}) {
               if($StatusSets{$ListItemStatus->{$ID}->{StatusSet}}){
                  $StatusSets{$ListItemStatus->{$ID}->{StatusSet}} .= "\/$ListItemStatus->{$ID}->{Name}";
               }else{
                  $StatusSets{$ListItemStatus->{$ID}->{StatusSet}} = "$ListItemStatus->{$ID}->{Name}";
               }              
            }
            my $selected = 0;
            foreach my $ID(sort{$StatusSets{$a} cmp $StatusSets{$b}} keys %StatusSets) {
               if($self->{ListObj}->{StatusSet} == $ID){
                     $selected = 1;
                     $options .= qq~<option value="$ID" selected="selected">$StatusSets{$ID}</option>
                              ~;
               }else{
                  $options .= qq~<option value="$ID">$StatusSets{$ID}</option>
                              ~;
               }               
            }
            my $no = "";
            if(!$selected){
               $no = "selected=\"selected\"";
            }
            $input = qq~<select name="List.StatusSet" id="StatusSet" class="SelectInput">
                           <option value="0"$no>None</option>
                           $options
                        </select>
                     ~;
         }elsif($Specification eq "CreateListListTypeOptions"){
            my $options = "";
            my $ListTypeObj = $self->{DBManager}->getTableObj("ListType");
            my $ListTypes = $ListTypeObj->get_all();

            foreach my $ID(sort keys %{$ListTypes}) {
               if($self->{ListObj}->{ListTypeID} == $ID){
                     $options .= qq~<option value="$ID" selected="selected">$ListTypes->{$ID}->{Name}</option>
                              ~;
               }else{
                  $options .= qq~<option value="$ID">$ListTypes->{$ID}->{Name}</option>
                              ~;
               }
               
            }
            $input = qq~<select name="List.ListTypeID" id="ListType" class="SelectInput">
                           <option value="">Select</option>
                           $options
                        </select>
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
               $self->{Debugger}->now("I don't know what to do with this input type: $input_type!");
            }
         }
      }
   }

   return $input;
}

=head2 getListsByTag

Handles the get lists by tag process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub getListsByTag {
#############################################
   my $self = shift;
   
   $self->{Debugger}->debug("in Lists::ListsManager::getListsByTag"); 

   my $ListTagObj = $self->{DBManager}->getTableObj('ListTag');
   my $TagObj = $self->{DBManager}->getTableObj('Tag');
   my $TagID = $self->{cgi}->{'TagID'};

   my $Tag = $TagObj->get_by_ID("$TagID");
   $self->{PageTitle}= "lc: lists tagged with $Tag->{Name}";

   my $page = $self->{cgi}->{page} ? $self->{cgi}->{page}: 1;
   my ($ListsByTagCount, $ListOfListByTag) = $TagObj->getListsByTag($Tag->{ID}, $page);
   my $pageCount = int($ListsByTagCount / $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'});
   if($ListsByTagCount % $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'}){
      $pageCount++;
   }

   foreach my $ID (keys %{$ListOfListByTag}) {
      $self->{ListObj}->getListInfo($ListOfListByTag->{$ID}, $self->{DBManager}, $self->{UserManager}, 1);
   }

   my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                   'UserManager'=>$self->{UserManager}, 'cgi' => $self->{cgi});
   my $ResultsRows = $SearchModule->processSearchResults("$Lists::SETUP::DIR_PATH/widgets/listing_row.html", $ListOfListByTag);

   my $TagURL = $TagObj->getTagURL($Tag);
   my $Pagenation = "";
   if($ListsByTagCount){
      $Pagenation = $SearchModule->getPagenation($page, $pageCount, "/", "tag", "");
   }

   $self->{Pagenation} = $Pagenation;
   $self->{TagListing} = $ResultsRows;
   if($ListsByTagCount == 1){
      $self->{ResultsCount} = "$ListsByTagCount list";
   }else{
      $self->{ResultsCount} = "$ListsByTagCount lists";
   }
   $self->{Tag} = $Tag->{Name};
   my $Content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/tag_listing.html");

   return $Content;
}

=head2 doListRating

Handles the List rating process

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list

=back

=cut

#############################################
sub doListRating {
#############################################
   my $self = shift;

   my $ListRatingsObj = $self->{DBManager}->getTableObj("ListRatings");
   my ($html, $text) = $ListRatingsObj->doRating($self->{cgi}->{"ListID"}, $self->{cgi}->{"Rating"}, $self->{UserManager}->{ThisUser}->{ID});

   my $Ranker = new Lists::Utilities::Ranker(Debugger => $self->{Debugger}, DBManager => $self->{DBManager});
   $Ranker->setListPopularityPoints($self->{cgi}->{ListID});

   return "$html $text";
}

=head2 getTagCloud

Gets the Tag cloud for the index page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the tag cloud

=back

=cut

#############################################
sub getTagCloud {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getTagCloud"); 

   my $TagObj = $self->{DBManager}->getTableObj("Tag");
   my $Tags = $TagObj->get_all();

   my $cloudHTML = "TagCloud";
   if(scalar keys %{$Tags}){
      use HTML::TagCloud;
      my $cloud = HTML::TagCloud->new();
      foreach  my $ID(keys %{$Tags}) {
         my $TagURL = $TagObj->getTagURL($Tags->{$ID});
         $cloud->add($Tags->{$ID}->{Name}, $TagURL, $Tags->{$ID}->{TagCount});
      }

      $cloudHTML = $cloud->html_and_css(10);
   }

   $self->{"TagCloud"} = $cloudHTML;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/3d_tagcloud.html"); 

   return $content;
}

=head2 get3DTagCloud

Gets the 3D Tag Cloud adapted from Cumulus

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the tag cloud

=back

=cut

#############################################
sub get3DTagCloud {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::get3DTagCloud"); 

   use Lists::Utilities::TagCloud;
   my $TagCloud = new Lists::Utilities::TagCloud("Debugger" => $self->{Debugger}, "DBManager" => $self->{DBManager});
   my $cloudHTML = $TagCloud->get3DTagCloud();

   $self->{"3DTagCloud"} = $cloudHTML;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/3d_tagcloud.html"); 

   return $content;
}

=head2 getCSSLinks

Returns the right CSS links based on the browser

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $css

=back

=cut

#####################################
sub getCSSLinks {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getCSSLinks - UserID: $self->{cgi}->{UserID}");

   my $Browser = "mozilla"; 
   if($ENV{HTTP_USER_AGENT} =~ m/MSIE 6.0/){
      $Browser = "ie6";      
   }elsif($ENV{HTTP_USER_AGENT} =~ m/MSIE 7.0/){
      $Browser = "ie7";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/MSIE 8.0/){
      $Browser = "ie8";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/Safari/){
      $Browser = "safari";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/Opera/){
      $Browser = "opera";
   }

   $self->{Debugger}->debug("USER_AGENT: $ENV{HTTP_USER_AGENT}\nBrowser: $Browser, Theme: $self->{ThemeID}");

   my $dir = "/css/$self->{ThemeID}";
   my $csslinks = qq~
                     <link href="$dir/all.css" rel="stylesheet" type="text/css" />
                  ~; 

   if($Browser ne "mozilla"){
      $csslinks .= qq~<link href="$dir/$Browser.css" rel="stylesheet" type="text/css" />~;
      if($Lists::SETUP::USE_FIREBUG_LITE){
         $csslinks .= qq~<script type='text/javascript' src='http://getfirebug.com/releases/lite/1.2/firebug-lite-compressed.js'></script>~;
      }
   }

   return $csslinks;
}

=head2 getCSSLinksMultibox

Returns the right CSS links based on the browser for the multibox

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $css

=back

=cut

#####################################
sub getCSSLinksMultibox {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getCSSLinksMultibox ");

   my $Browser = "mozilla"; 
   if($ENV{HTTP_USER_AGENT} =~ m/MSIE 6.0/){
      $Browser = "ie6";      
   }elsif($ENV{HTTP_USER_AGENT} =~ m/MSIE 7.0/){
      $Browser = "ie7";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/MSIE 8.0/){
      $Browser = "ie8";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/Safari/){
      $Browser = "safari";
   }elsif($ENV{HTTP_USER_AGENT} =~ m/Opera/){
      $Browser = "opera";
   }

   $self->{Debugger}->debug("USER_AGENT: $ENV{HTTP_USER_AGENT}\nBrowser: $Browser, Theme: $self->{ThemeID}");

   my $csslinks = "";
   if($Browser eq "ie6"){
      $csslinks .= qq~<link rel="stylesheet" href="/css/$self->{ThemeID}/mb_ie.css" type="text/css" media="screen" />  ~;
   }

   return $csslinks;
}


=head2 getUsersBoard

Returns the html for the user's board

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub getUsersBoard {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getUsersBoard");

   # Figure out how many pages of board posts there are
   my $page = $self->{cgi}->{page}  ? $self->{cgi}->{page}: 1;
   my $BoardObj = $self->{DBManager}->getTableObj("Board");
   my ($BoardMessages, $pageCount) = $BoardObj->getBoardMessages($self->{cgi}->{UserID}, $page);
   my $UserObj = $self->{DBManager}->getTableObj("User");

   my $EvenOrOdd = "Odd";
   my %PostersCache; my $Board = ""; 
   foreach my $ID(sort{$BoardMessages->{$b}->{CreateDate} <=> $BoardMessages->{$a}->{CreateDate}} keys %{$BoardMessages}) {
      $BoardMessages->{$ID}->{'CreateDateFormatted'} = Lists::Utilities::Date::getShortHumanFriendlyDate($BoardMessages->{$ID}->{CreateDate});
      if(! $PostersCache{$BoardMessages->{$ID}->{PosterUserID}}){
         $PostersCache{$BoardMessages->{$ID}->{PosterUserID}} = $UserObj->get_by_ID($BoardMessages->{$ID}->{PosterUserID});
         $self->{UserManager}->getUserAvatar($PostersCache{$BoardMessages->{$ID}->{PosterUserID}});
         $PostersCache{$BoardMessages->{$ID}->{PosterUserID}}->{"PosterURL"} = $self->{UserManager}->getUserURL($PostersCache{$BoardMessages->{$ID}->{PosterUserID}});
      }

      if($EvenOrOdd eq "Odd"){
         $EvenOrOdd = "Even";
      }else{
         $EvenOrOdd = "Odd";
      }

      my $DeleteButton;
      if($BoardMessages->{$ID}->{PosterUserID} == $self->{UserManager}->{ThisUser}->{ID} || 
         $self->{cgi}->{UserID} == $self->{UserManager}->{ThisUser}->{ID}){
         $DeleteButton = qq~<a href="javascript:deleteBoardPost($ID)" class="DeleteButton"></a>~;
      }

      $BoardMessages->{$ID}->{Message} =~ s/\n/<br \/>/g;

      my %BoardRow = ('EvenOrOdd' => $EvenOrOdd,
                      'Poster' => $PostersCache{$BoardMessages->{$ID}->{PosterUserID}},
                      'BoardMessages' => $BoardMessages->{$ID},
                      'DeleteButton' => $DeleteButton);

      $Board .= $self->processPage("$Lists::SETUP::DIR_PATH/board_rows.html", \%BoardRow);      
   }

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $BoardOwner = $UserObj->get_by_ID($self->{cgi}->{UserID});
   $self->{BoradUserURL} = $self->{UserManager}->getUserURL($BoardOwner);
   $self->{BoardMessages} = $Board;

   if($page < $pageCount){
      my $nextPage = $page + 1;
      $self->{BoardOlderLink} = qq~<a href="javascript:loadNonListElement('getUsersSpace', $self->{cgi}->{UserID}, 'page=$nextPage');" class="BoardOlderLink">Older >></a>~;
   }
   if($page > 1){
      my $prevPage = $page - 1;
      $self->{BoardNewerLink} = qq~<a href="javascript:loadNonListElement('getUsersSpace', $self->{cgi}->{UserID}, 'page=$prevPage');" class="BoardNewerLink"><< Newer</a>~;
   }
   if($page != $pageCount){
      $self->{BoardOldestLink} = qq~<a href="javascript:loadNonListElement('getUsersSpace', $self->{cgi}->{UserID}, 'page=$pageCount');" class="BoardOldestLink">Oldest >></a>~;
   }
   if($page != 0){
      $self->{BoardNewestLink} = qq~<a href="javascript:loadNonListElement('getUsersSpace', $self->{cgi}->{UserID}, 'page=1');" class="BoardNewestLink"><< Newest</a>~;
   }

   my $content = $self->getPage("$Lists::SETUP::DIR_PATH/board.html");
   return $content;
}


=head2 getMessages

Returns the html for the messages page

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html - of the messages

=back

=cut

#####################################
sub getMessages {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getMessages");

   if(! $self->{UserManager}->{ThisUser}->{ID}){
      $self->{ErrorMessages} =  $Lists::SETUP::MESSAGES{'MISC_ERROR'};
      $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }

   my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
   my $Messages = $MessagesObj->get_with_restraints("UserID = $self->{UserManager}->{ThisUser}->{ID}", 
                                          "CreateDate DESC", $Lists::SETUP::CONSTANTS{'MESSAGE_LIMIT'});

   if(! keys %{$Messages}){
      return "<p>No messages.</p>";
   }

   my $MessageActionsObj = $self->{DBManager}->getTableObj("MessageActions");
   my $MessageActions = $MessageActionsObj->get_all();

   my $UserObj = $self->{DBManager}->getTableObj("User");

   my $today = Lists::Utilities::Date::getFullHumanFriendlyDate(time());
   my $todayKey; 
   if($today =~ m/(\w+)\s(\w+)\s([\d\w]+)\s(\d+)\sat\s(\d+):(\d+)(\w+)/ ){
      $todayKey = "$2 $3 $4";
   }
   my $yesterday = $today - (60*60*24);
   my $yesterdayKey; 
   if($yesterday =~ m/(\w+)\s(\w+)\s([\d\w]+)\s(\d+)\sat\s(\d+):(\d+)(\w+)/ ){
      $yesterdayKey = "$2 $3 $4";
   }

   my %DateHash; 
   my $SortOrder = 1;
   foreach my $ID(sort{$Messages->{$b}->{CreateDate} <=> $Messages->{$a}->{CreateDate}} keys %{$Messages}) {

      my $User = $UserObj->get_by_ID($Messages->{$ID}->{UserID});
      my $Doer = $UserObj->get_by_ID($Messages->{$ID}->{DoerID});

      my %Data;
      $Data{"Image"} = "/images/$self->{ThemeID}/$MessageActions->{$Messages->{$ID}->{Action}}->{Image}";
      $Data{"Phrase"} = $MessageActions->{$Messages->{$ID}->{Action}}->{Phrase};
      $Data{"DoerURL"} = $self->{UserManager}->getUserURL($Doer); 
      $Data{"DoerName"} = $Doer->{Username};
      $Data{"Date"} = Lists::Utilities::Date::getFullHumanFriendlyDate($Messages->{$ID}->{CreateDate});

      if($Messages->{$ID}->{Action} == 1){
         # Comment
         my $List = $self->{ListObj}->get_by_ID($Messages->{$ID}->{SubjectID});
         my $ListGroupName = $self->{ListGroupObj}->get_field_by_ID("Name", $List->{ListGroupID});
         $Data{"SubjectURL"} = $self->{ListObj}->getListURL($List, $ListGroupName);
         $Data{"SubjectName"} = $List->{Name};
      }elsif($Messages->{$ID}->{Action} == 2){
         # Board Post
         $Data{"SubjectURL"} = $self->{UserManager}->getUserURL($self->{UserManager}->{ThisUser});
         $Data{"SubjectName"} = "your board";
      }

      my $dateKey; 
      if($Data{"Date"} =~ m/(\w+)\s(\w+)\s([\d\w]+)\s(\d+)\sat\s(\d+):(\d+)(\w+)/ ){
         $dateKey = "$2 $3 $4";
         $Data{"Time"} = "$5:$6 $7";

         if($dateKey eq $todayKey){
            $dateKey = "Today";
         }
         if($dateKey eq $yesterdayKey){
            $dateKey = "Yesterday";
         }
      }else{
         $self->{Debugger}->debug("No Match!!! $Data{'Date'}");
      }
      if(! $Messages->{$ID}->{Seen}){
         $Data{"New"} = qq~<span class="New">* New *</span>~;
      }
      $DateHash{$dateKey}{HTML} .= $self->processPage("$Lists::SETUP::DIR_PATH/owner/message_row.html", \%Data);
      $DateHash{$dateKey}{SortOrder} = $SortOrder;
      $SortOrder++;
   }

   my $content;
   foreach my $date(sort{$DateHash{$a}{SortOrder} <=> $DateHash{$b}{SortOrder}} keys %DateHash) {
      $content .= qq~<p class="MessageHeading">$date</h3><ul class="MessagesList">$DateHash{$date}{HTML}</ul>~;
   }

   $MessagesObj->setAsSeen($self->{UserManager}->{ThisUser}->{ID});

   return $content;
}

=head2 getUsersSpace

Returns the html for the user's space

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object

=item B<Returns :>

   1. $html

=back

=cut

#####################################
sub getUsersSpace {
#####################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager->getUsersSpace");

   my $content;

   if($self->{cgi}->{UserID} == $Lists::SETUP::ABOUT_USER_ACCOUNT){
      $content = $self->processPage("$Lists::SETUP::DIR_PATH/about/about.html");
   }else{
      $content = $self->getPage("$Lists::SETUP::DIR_PATH/users_space.html");
   }

   return $content;
}


=head2 getBasicFile

Helper function to get the contents of a file without processing

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
   2. $template - the basic template to return without processing

=item B<Returns :>

   1. $css

=back

=cut

#####################################
sub getBasicFile {
#####################################
   my $self = shift;
   my $template = shift;

   if(! open(PAGE, $template) ){
      my $error = "cannot open file: $template - $!";
      $self->{Debugger}->throwNotifyingError($error);
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'MISC_ERROR'};
      return $self->processPage("$Lists::SETUP::DIR_PATH/error.html");
   }
   my @lines = <PAGE>;
   close PAGE;

   my $file = "";
   foreach my $line(@lines) {
      $file .= $line;
   }
   return $file;
}


=head2 getSelectTag

Simpler than using getInputTag for selects

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
   2. $table
   3. $List Reference to the list

=item B<Returns :>

   1. $select - The select tag

=back

=cut

#####################################
sub getSelectTag {
#####################################
   my $self = shift;
   my $table = shift;
   my $List = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getSelectTag with $table and ListGroupID: $List->{ListGroupID}");

   my $select;
   if($table eq "Public"){
      my $yes = ""; my $no = "";
      if($List->{"Public"}){
         $yes = " selected=\"selected\"";
      }else{
         $no = " selected=\"selected\"";
      }
      $select = qq~<select name="List.Public" id="Public" class="SelectInput">
                     <option value="1"$yes>Public</option>
                     <option value="0"$no>Private</option>
                  </select>~;
   }elsif($table eq "Links"){
      my $yes = ""; my $no = ""; my $amazon = ""; my $disabled = "";
      if($List->{"Links"} == 1){
         $yes = " selected=\"selected\"";
      }elsif($List->{"Links"} == 2){
         $amazon = " selected=\"selected\"";
         $disabled = "disabled";
      }else{
         $no = " selected=\"selected\"";
      }
      $select = qq~<select name="List.Links" id="Links" class="SelectInput" onchange="forceNoImagesOnAmazon(this)" $disabled>
                     <option value="1"$yes>Yes</option>
                     <option value="0"$no>No</option>
                     <option value="2"$amazon>Amazon</option>
                  </select>~;
   }elsif($table eq "Images"){
      my $yes = ""; my $no = ""; my $disabled = "";
      if($List->{"Images"}){
         $yes = " selected=\"selected\"";
      }else{
         $no = " selected=\"selected\"";
      }
      if($List->{"Links"} == 2){
         $disabled = "disabled";
      }
      $select = qq~<select name="List.Images" id="Images" class="SelectInput" $disabled>
                     <option value="1"$yes>Yes</option>
                     <option value="0"$no>No</option>
                  </select>~;
   }elsif($table eq "ListOrder"){
         my $asc = ""; my $desc = "";
         if($List->{"Ordering"} eq "a"){
            $asc = " selected=\"selected\"";
         }else{
            $desc = " selected=\"selected\"";
         }
         $select = qq~<select name="List.Ordering" id="ListOrder">
                        <option value="a"$asc>Ascending</option>
                        <option value="d"$desc>Descending</option>
                        </select>~;
   }elsif($table eq "StatusSet"){
      $self->{ThisList} = $List;
      $select = $self->getInputHTMLTag("<!--Input.Select.CreateListStatusSetOptions-->");
   }elsif($table eq "ListItemStatus"){
      if($List->{StatusSet}){
         my $ListItemStatusObj = $self->{DBManager}->getTableObj("ListItemStatus");
         my $rows = $ListItemStatusObj->get_with_restraints("StatusSet = $List->{StatusSet}");
         $select = qq~<label for="ListItemStatus" id="ListItemStatusLabel">Set all item's status to:</label>
                        <select name="SetAllStatusTo" id="$table" class="SelectInput"><option value="">Select</option>~;
         foreach my $key(sort{$rows->{$a}->{ID} <=> $rows->{$b}->{ID}} keys %{$rows}){
            $select .= qq~<option value="$rows->{$key}->{ID}">$rows->{$key}->{Name}</option>~;         
         }
         $select .= qq~</select><br />~;
      }else{
         $self->{ThisList} = $List;
         $select = qq~<label for="StatusSet" id="StatusSetLabel">Status Set:</label>~;
         $select .= $self->getInputHTMLTag("<!--Input.Select.CreateListStatusSetOptions-->");
      }      
   }elsif($table eq "AmazonMode"){
      $self->{Debugger}->debug("Making amazon mode select tag");
      my $options = "";
      foreach my $key (sort keys %Lists::SETUP::AMAZON_MODES) {
         if($key eq $self->{cgi}->{mode}){
            $options .= qq~<option value="$key" selected="selected">$Lists::SETUP::AMAZON_MODES{$key}</option>
                     ~;
         }else{
            $options .= qq~<option value="$key">$Lists::SETUP::AMAZON_MODES{$key}</option>
                     ~;
         }         
      }
      $select = qq~<select name="AmazonMode" id="AmazonMode" class="SelectInput">
                      <option value="">Select</option>
                      $options
                   </select> 
                  ~;
   }elsif($table =~ m/Birth(\w+)/){
      my $birthfield = $1;
      $select = Lists::Utilities::Date::getDateDropDowns($birthfield, "UserSettings.Birth$birthfield", "Birthday", $self->{cgi}->{"UserSettings.Birth$birthfield"});
   }else{
      my $TableObj = $self->{DBManager}->getTableObj($table);
      my $rows;
      my $selectBlank = "";
      my $selectName = "";
      my $field = $table . "ID";

      if($table eq "ListGroup"){
         if($self->{UserManager}->{ThisUser}->{ID}){
            $rows = $TableObj->get_with_restraints("UserID = 0 OR UserID = $self->{UserManager}->{ThisUser}->{ID}");
         }else{
            $rows = $TableObj->get_with_restraints("UserID = 0");
         }
         $selectName = "List.$field";
      }else{
         $rows = $TableObj->get_all();
         $selectName = "List.$field";
      }      

      $self->{Debugger}->debug("List->{ListGroupID}: $List->{ListGroupID}");
      if($field eq "ListTypeID" && !$List->{"ListTypeID"}){
         $List->{"ListTypeID"} = 1;
      }
      if($field eq "ListGroupID" && !$List->{"ListGroupID"}){
         $List->{"ListGroupID"} = 1;
      }
      
      $select = qq~<select name="$selectName" id="$table" class="SelectInput">$selectBlank~;
      foreach my $key(sort{$rows->{$a}->{Name} cmp $rows->{$b}->{Name}} keys %{$rows}){
         if($List->{$field} eq $rows->{$key}->{ID}){
            $select .= qq~<option value="$rows->{$key}->{ID}" selected="selected">$rows->{$key}->{Name}</option>~;
         }else{
            $select .= qq~<option value="$rows->{$key}->{ID}">$rows->{$key}->{Name}</option>~;
         }         
      }
      $select .= qq~</select>~;
   }

   return $select;
}

=head2 getThisUserSelectTag

Gets select tags pre-poped with data for the logged in user

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
   2. $table

=item B<Returns :>

   1. $select - The select tag

=back

=cut

#####################################
sub getThisUserSelectTag {
#####################################
   my $self = shift;
   my $table = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getThisUserSelectTag with $table");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->get_by_ID($self->{UserManager}->{ThisUser}->{ID});
  
   $self->{UserManager}->getUserInfo($User);

   my $select;
   if($table eq "Gender"){
      #foreach (keys %{$User}) {
      #   $self->{Debugger}->debug("$_ ---> $User->{$_}");
      #}
      my $male = ""; my $female = "";
      if($User->{"Gender"} eq "Male"){
         $male = " selected=\"selected\"";
      }elsif($User->{"Gender"} eq "Female"){
         $female = " selected=\"selected\"";
      }
      $select = qq~<select name="UserSettings.Gender" id="Gender" class="SelectInput">
                     <option value="">Select</option>
                     <option value="M" $male>Male</option>
                     <option value="F" $female>Female</option>
                  </select>~;
   }elsif($table eq "Country"){
      my $CountryObj = $self->{DBManager}->getTableObj("Country");
      my $Countries = $CountryObj->get_all();
      $select = qq~<select name="UserSettings.CountryID" id="Country" class="SelectInput" onchange="changeRegions(this.value)">
                        <option value="">Select</option>
                        <option value="4">United States</option>
                        <option value="2">Canada</option>
                        <option value="3">United Kingdom</option>
                        <option value="1">Australia</option>
                        <option value="">______________________</option>
                  ~;
      foreach my $key(sort{$Countries->{$a}->{Name} cmp $Countries->{$b}->{Name}} keys %{$Countries}){
         if($self->{UserManager}->{ThisUser}->{CountryID} eq $Countries->{$key}->{ID}){
            $select .= qq~<option value="$Countries->{$key}->{ID}" selected="selected">$Countries->{$key}->{Name}</option>~;
         }else{
            $select .= qq~<option value="$Countries->{$key}->{ID}">$Countries->{$key}->{Name}</option>~;
         }
      }
      $select .= qq~</select>~;
   }elsif($table eq "Region"){
      # Region is trick because we have DB regions for only the US, UK, AU & CA
      #   If the user is from any other country, we offer an input box for Region
      my $options;
      if($self->{UserManager}->{ThisUser}->{CountryID}){
         $self->{cgi}->{CountryID} = $self->{UserManager}->{ThisUser}->{CountryID};
      }
      $select = $self->GetRegionOptions();
   }elsif($table eq "Theme"){
      my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
      my $rows = $ThemeObj->get_with_restraints("Enabled = 1");
      $select = qq~<select name="UserSettings.ThemeID" id="ThemeSelect" class="SelectInput" onchange="setThemeVisuals(this.options[selectedIndex].value)">~;
      foreach my $key(sort{$rows->{$a}->{Name} cmp $rows->{$b}->{Name}} keys %{$rows}){
         if($self->{UserManager}->{ThisUser}->{ThemeID} eq $rows->{$key}->{ID}){
            $select .= qq~<option value="$rows->{$key}->{ID}" selected="selected">$rows->{$key}->{Name}</option>~;
         }else{
            $select .= qq~<option value="$rows->{$key}->{ID}">$rows->{$key}->{Name}</option>~;
         }
      }
      $select .= qq~</select>~;
   }elsif($table =~ m/Privacy(\w+)/){
      $select = qq~<select name="UserSettings\.$table" class="SelectInput" id=Privacy"$table">~;
      if($self->{UserManager}->{ThisUser}->{$table}){
         $select .= qq~<option value="1" selected="selected">Yes</option><option value="0">No</option>~;
      }else{
         $select .= qq~<option value="1">Yes</option><option value="0" selected="selected">No</option>~;
      }
      $select .= "</select>";
   }elsif($table eq "ReceiveUpdateEmails"){
      $select = qq~<select name="UserSettings\.ReceiveUpdateEmails" class="SelectInput" id="ReceiveUpdateEmailsSelect">~;
      if($self->{UserManager}->{ThisUser}->{ReceiveUpdateEmails}){
         $select .= qq~<option value="1" selected="selected">Yes</option><option value="0">No</option>~;
      }else{
         $select .= qq~<option value="1">Yes</option><option value="0" selected="selected">No</option>~;
      }
      $select .= "</select>";
   }elsif($table eq "ReceiveNotifications"){
      $select = qq~<select name="UserSettings\.ReceiveNotifications" class="SelectInput" id="ReceiveNotificationsSelect">~;
      if($self->{UserManager}->{ThisUser}->{ReceiveNotifications}){
         $select .= qq~<option value="1" selected="selected">Yes</option><option value="0">No</option>~;
      }else{
         $select .= qq~<option value="1">Yes</option><option value="0" selected="selected">No</option>~;
      }
      $select .= "</select>";
   }

   return $select;
}


=head2 isListRatingClickable

Given a list owner id, determinies if a list's rating should be clickable

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists::ListsManager object
   2. $List->Userid

=item B<Returns :>

   1. $clickable - 1 or 0

=back

=cut

#####################################
sub isListRatingClickable {
#####################################
   my $self = shift;
   my $ListOwnerID = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::isListRatingClickable");

   my $Clickable = 0;
   if($self->{UserManager}->{ThisUser}->{ID}){
      $Clickable = 1;
   }
   if($self->{UserManager}->{ThisUser}->{ID} == $ListOwnerID && 
               $Lists::SETUP::CONSTANTS{'USERS_CANT_RATE_THEIR_OWN_LISTS'}){
      $Clickable = 0;
   }

   return $Clickable;
}

=head2 getBigListOfLists

Gets the html for the Big list of lists that is displayed on the home page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list of lists

=back

=cut

#############################################
sub getBigListOfLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getBigListOfLists"); 

   if(! $self->{cgi}->{WhichListings}){
      $self->{cgi}->{WhichListings} = "popular";
   }

   my $page = 1;
   if($self->{cgi}->{page}){
      $page = $self->{cgi}->{page};
   }
   my $BigListOfList;
   if($self->{cgi}->{WhichListings} eq "popular"){
      $BigListOfList = $self->{ListObj}->getPopularLists($page); # getTopLists
   }elsif($self->{cgi}->{WhichListings} eq "new"){
      $BigListOfList = $self->{ListObj}->getNewLists($page);
   }elsif($self->{cgi}->{WhichListings} eq "active"){
      $BigListOfList = $self->{ListObj}->getActiveLists($page);
   }  

    
   my $TopListCount = $self->{ListObj}->getListsCount(); # getTopListCount
   my $pageCount = int($TopListCount / $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'});
   if($TopListCount % $Lists::SETUP::CONSTANTS{'LISTING_ROWS_LIMIT'}){
      $pageCount++;
   }

   if(!$pageCount){
      # Once this is working, this should never happen
      $self->{ErrorMessages} = $Lists::SETUP::MESSAGES{'NO_TOP_LISTS'};
      return $self->processPage("$Lists::SETUP::DIR_PATH/widgets/top_lists.html"); 
   }

   my $SearchModule = new Lists::Utilities::Search('Debugger'=>$self->{Debugger}, 'DBManager'=>$self->{DBManager}, 
                                                   'UserManager'=>$self->{UserManager}, 'cgi' => $self->{cgi});

   foreach my $ID (keys %{$BigListOfList}) {
      $self->{ListObj}->getListInfo($BigListOfList->{$ID}, $self->{DBManager}, $self->{UserManager}, 1);
   }
   $self->{TopListsRows} = $SearchModule->processSearchResults("$Lists::SETUP::DIR_PATH/widgets/listing_row.html", $BigListOfList);
   if($TopListCount){
      my $TimeFrame = "";
      $self->{Pagenation} = $SearchModule->getPagenation($page, $pageCount, "/", $self->{cgi}->{WhichListings});
   }

   $self->{TopListsNavigation} = $self->getTopListsNavigation();

   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/top_lists.html"); 

   return $content;
}

=head2 getTopListsNavigation

Gets the html for the top lists navigation with the tab corresponding to the 
Time Frame passed properly classed

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $timeFrame

=item B<Returns :>

   1. $html - The html of the list of top users

=back

=cut

#############################################
sub getTopListsNavigation {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getTopListsNavigation"); 

   if(!$self->{cgi}->{WhichListings}){
      $self->{cgi}->{WhichListings} = 'popular';
   }
   my $popClass = ""; my $newClass = ""; my $activeClass = "";
   if($self->{cgi}->{WhichListings} eq "popular"){
      $popClass = 'class="On"';
   }elsif($self->{cgi}->{WhichListings} eq "new"){
      $newClass = 'class="On"';
   }elsif($self->{cgi}->{WhichListings} eq "active"){
      $activeClass = 'class="On"';
   }

   my $Navigation .= qq~<li><a href="/popular.html" $popClass>popular</a></li>
                     <li><a href="/new.html" $newClass>new</a></li>
                     <li><a href="/active.html" $activeClass>active</a></li> ~;

   return $Navigation;
}


=head2 getTopUsers

Gets the html for the top users box that is displayed on the home page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list of top users

=back

=cut

#############################################
sub getTopUsers {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getTopUsers"); 

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $TopUsers = $UserObj->getTopUsers();

   my $rows = "";
   foreach my $ID (sort{$TopUsers->{$b}->{LastLogin} <=> $TopUsers->{$a}->{LastLogin}} keys %{$TopUsers}) {
      $self->{UserManager}->getUserInfo($TopUsers->{$ID});
      my %Data = ("Users" => $TopUsers->{$ID});
      $rows .= $self->processPage("$Lists::SETUP::DIR_PATH/widgets/top_users_rows.html", \%Data); 
   }

   $self->{TopUserRows} = $rows;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/top_users.html"); 

   return $content;
}

=head2 getRecentComments

Gets the html for the recent comments widget for the side bar

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list of top users

=back

=cut

#############################################
sub getRecentComments {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getRecentComments"); 

   my $UserObj = $self->{DBManager}->getTableObj("User"); 
   my $CommentObj = $self->{DBManager}->getTableObj("Comment");
   my $RecentComments = $CommentObj->getRecentComments();

   my $rows = "";
   foreach my $ID (sort{$RecentComments->{$b}->{CreateDate} <=> $RecentComments->{$a}->{CreateDate}} keys %{$RecentComments}) {
      my $List = $self->{ListObj}->get_by_ID($RecentComments->{$ID}->{ListID});
      $RecentComments->{$ID}->{"ListURL"} = $self->{ListObj}->getListURL($List, $RecentComments->{$ID}->{ListGroup});
      
      my $Commenter = $UserObj->get_by_ID($RecentComments->{$ID}->{CommenterID}); 
      $RecentComments->{$ID}->{"CommenterURL"} = $Lists::SETUP::URL . $self->{UserManager}->getUserURL($Commenter);
      $self->{UserManager}->getUserAvatar($Commenter);
      $RecentComments->{$ID}->{"AvatarDisplay"} = $Commenter->{"AvatarDisplay"};
      #$RecentComments->{$ID}->{"CreateDateFormatted"} = Lists::Utilities::Date::getShortHumanFriendlyDate($RecentComments->{$ID}->{"CreateDate"});
      
      my %Data = ("Comments" => $RecentComments->{$ID});
      $rows .= $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_comments_rows.html", \%Data); 
   }

   $self->{RecentCommentsRows} = $rows;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_comments.html"); 

   return $content;
}


=head2 getRecentUsers

Gets the html for the recent users widget that is displayed on the home page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list of top users

=back

=cut

#############################################
sub getRecentLists {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getRecentLists"); 

   my $RecentLists = $self->{ListObj}->getRecentLists();

   my $rows = ""; my $count = 1;
   foreach my $ID (sort{$RecentLists->{$a}->{SortOrder} <=> $RecentLists->{$b}->{SortOrder}} keys %{$RecentLists}) {
      $self->{ListObj}->getBriefListInfo($RecentLists->{$ID}, $self->{DBManager});
      my %Data = ("List" => $RecentLists->{$ID});
      $rows .= $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_lists_rows.html", \%Data); 
      $count++;
      if($count == 6){
         $rows .= "</ul><ul class='RecentLists'>";
      }
   }
   
   $self->{RecentListsRows} = $rows;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_lists.html"); 

   return $content;
}

=head2 getRecentSearches

Gets the html for the top users box that is displayed on the home page

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object

=item B<Returns :>

   1. $html - The html of the list of top users

=back

=cut

#############################################
sub getRecentSearches {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::getRecentSearches"); 

   my $SearchHistoryObj = $self->{DBManager}->getTableObj("SearchHistory");
   my $RecentSearches = $SearchHistoryObj->getRecentSearches();

   my $rows = "";
   foreach my $ID (sort{$RecentSearches->{$a}->{SortOrder} <=> $RecentSearches->{$b}->{SortOrder}} keys %{$RecentSearches}) {
      if($RecentSearches->{$ID}->{ResultsCount} == 1){
         $RecentSearches->{$ID}->{ResultsText} = "list";
      }else{
         $RecentSearches->{$ID}->{ResultsText} = "lists";
      }

      $RecentSearches->{$ID}->{TimeAgo} = Lists::Utilities::Date::getTimeSince($RecentSearches->{$ID}->{Date});

      $self->{Debugger}->debug("Search - $RecentSearches->{$ID}->{Query}: $RecentSearches->{$ID}->{Date} -> $RecentSearches->{$ID}->{TimeAgo}");

      my %Data = ("Search" => $RecentSearches->{$ID});

      $rows .= $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_searches_rows.html", \%Data); 
   }
   
   $self->{RecentSearchRows} = $rows;
   my $content = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/recent_searches.html"); 

   return $content;
}

=head2 logListHit

Logs a list hit with the list id passed and the current request information

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListID - The list being hit

=back

=cut

#############################################
sub logListHit {
#############################################
   my $self = shift;
   my $List = shift;
   my $referrerEmail = shift;

   if($self->{UserManager}->{ThisUser}->{ID} != $List->{UserID}){
      my $UserID;
      my $Referrer;
      if($self->{UserManager}->{ThisUser}->{ID}){
         $UserID = $self->{UserManager}->{ThisUser}->{ID};
      }elsif($ENV{HTTP_REFERER} !~ m/$Lists::SETUP::URL/ && $ENV{HTTP_REFERER} !~ m/$Lists::SETUP::URL2/){
         $Referrer = $ENV{HTTP_REFERER};
      }elsif($ENV{HTTP_REFERER} =~ m/$Lists::SETUP::URL/ && $ENV{HTTP_REFERER} =~ m/$Lists::SETUP::URL2/){
         $UserID = 0;
      }

      # If email = 1, this is someone emailing a list to that email
      my $email = 0;
      if($referrerEmail){
         $email = 1;
         $Referrer = $referrerEmail;
      }
      my %ListHit = ("ListHits.ListID" => $List->{ID},
                     "ListHits.UserID" => $UserID,
                     "ListHits.Referrer" => $Referrer,
                     "ListHits.Email" => $email,
                     "ListHits.Status" => 1,
                     "ListHits.IP" => $ENV{REMOTE_ADDR}
                     );
      my $ListHitsObj = $self->{DBManager}->getTableObj("ListHits");
      my $ID = $ListHitsObj->store(\%ListHit);
   }
}

=head2 getPageTitle

Given a page name, returns the page title, for the simpler pages that don't involve lists

=over 4

=item B<Parameters :>

   1. $self - Reference to a ListManager object
   2. $ListItems - Reference to a hash with the list items in it
   3. $List - Reference to a hash with the parent list infor

=back

=cut

#############################################
sub getPageTitle {
#############################################
   my $self = shift;

   my $page = $self->{Request}->filename();
   $self->{Debugger}->debug("in Lists::ListManager->getPageTitle $page");

   if($self->{PageTitle}){
      return $self->{PageTitle};
   }

   my $pageTitle = "";
   if($page =~ m/privacy/){
      $pageTitle = "list central privacy policy";
   }elsif($page =~ m/user/ && $self->{PageOwner}->{Username}){
      $pageTitle = "lc: lists by $self->{PageOwner}->{Username}";
   }elsif($page =~ m/terms/){
      $pageTitle = "list central terms of use";
   }elsif($page =~ m/search/){
      $pageTitle = "lc: search - $self->{cgi}->{Query}";
   }elsif($page =~ m/tagcloud/){
      $pageTitle = "list central tag cloud";
   }elsif($page =~ m/tagged/){
      $pageTitle = "lc: lists taged with \"$self->{cgi}->{'Tag.ID'}\"";
   }elsif($page =~ m/forgotpassword/){
      $pageTitle = "list central forgot password";
   }elsif($page =~ m/login/){
      $pageTitle = "list central login";
   }elsif($page =~ m/signup/){
      $pageTitle = "list central sign up";
   }elsif($page =~ m/tagcloud/){
      $pageTitle = "list central tag cloud";
   }elsif($page =~ m/upload_image/){
      $pageTitle = "list central upload image";
   }elsif($page =~ m/settings/){
      $pageTitle = "list central settings";
   }elsif($page =~ m/create_and_edit/){
      $pageTitle = "list central create & edit";
   }elsif($page =~ m/error/){
      $pageTitle = "lc central error";
   }elsif($page =~ m/about.html/){
       $pageTitle= "list central about";
   }elsif($page =~ m/help/){
       $pageTitle= "list central help";
   }elsif($page =~ m/tagcloud/){
      $pageTitle = "list central tag cloud";
   }elsif($page =~ m/messages/){
      $pageTitle = "list central messages";
   }elsif($self->{cgi}->{"ListID"} == $Lists::SETUP::CONSTANTS{'FAQ_LISTID'}){
      $pageTitle = "list central faqs";
   }elsif($page =~ m/lists/) {
      if($self->{PageOwner}->{ID} == $Lists::SETUP::ABOUT_USER_ACCOUNT){
         $pageTitle = "about list central";
      }else{
         $pageTitle = "lc: lists by $self->{PageOwner}->{Username}";
      }      
   }else{
      $pageTitle = $Lists::SETUP::CONSTANTS{'DEFAULT_PAGE_TITLE'};
   }

   return $pageTitle;
}

=head2 getThemeVisuals

Returns the javascript for the member theme visualization

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=itme B<Returns : >

   1. $js - the javascript, array of arrays of theme colours

=back

=cut

#############################################
sub getThemeVisuals {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListManager->getThemeVisuals");

   # Get the Theme Info
   my $ThemeObj = $self->{DBManager}->getTableObj("Theme");
   my $js = $ThemeObj->getThemeVisuals($self->{DBManager});

   return $js;
}

=head2 setThemeID

Returns the javascript for the member theme visualization

=over 4

=item B<Parameters :>

   1. $self - Reference to a ApplicationFramework::Processor object

=itme B<Returns : >

   1. $js - the javascript, array of arrays of theme colours

=back

=cut

#############################################
sub setThemeID {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListsManager::setThemeID self->{cgi}->{UserID}: $self->{cgi}->{UserID}, $self->{file_requested}");

   $self->{ThemeID} = $Lists::SETUP::CONSTANTS{'DEFAULT_THEME'};
   if($self->{cgi}->{UserID}){; 
      $self->{Debugger}->debug("In looking for the theme, found a user id: $self->{cgi}->{UserID}");
      my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings"); 
      my $UserSettings = $UserSettingsObj->getByUserID($self->{cgi}->{UserID});
      $self->{ThemeID} = $UserSettings->{ThemeID};
   }elsif($self->{cgi}->{ListID}){
      $self->{Debugger}->debug("In looking for the theme, found a list id: $self->{cgi}->{ListID}");
      my $List = $self->{ListObj}->get_by_ID($self->{cgi}->{ListID});
      if($List->{UserID}){
         my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings"); 
         my $UserSettings = $UserSettingsObj->getByUserID($List->{UserID});
         $self->{ThemeID} = $UserSettings->{ThemeID};
      }      
   }elsif($self->{UserManager}->{ThisUser}->{ID}){
      if($self->{"file_requested"} =~ m/create_and_edit/ || $self->{"file_requested"} =~ m/settings/ || 
         $self->{"file_requested"} =~ m/upload_image/ || $self->{"file_requested"} =~ m/send_request/ ||
         $self->{"file_requested"} =~ m/messages/){
         my $UserSettingsObj = $self->{DBManager}->getTableObj("UserSettings"); 
         my $UserSettings = $UserSettingsObj->getByUserID($self->{UserManager}->{ThisUser}->{ID});
         $self->{ThemeID} = $UserSettings->{ThemeID};
      }
   }

   if(! $self->{ThemeID}){
      $self->{ThemeID} = $Lists::SETUP::CONSTANTS{'DEFAULT_THEME'};
   }
   $self->{AdServer}->{ThemeID} = $self->{ThemeID};
   $self->{Editor}->{ThemeID} = $self->{ThemeID};

   $self->{Debugger}->debug("setting ThemeID - $self->{ThemeID}");
}

=head2 sendWelcomeEmail

Sends email to IT as per the email in Lists::SETUP::TO_IT_EMAIL

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $User - Reference to a hash with the new user to send the welcome email to

=back

=cut

#############################################
sub sendWelcomeEmail {
#############################################
   my $self = shift;
   my $User = shift;
   my $Mailer = shift;

   $self->{Debugger}->debug("Lists::Utilities::Mailer::sendWelcomeEmail");

   my %Data;
   $Data{"User"} = $User;

   my $subject = "Welcome to List Central";
   my $EmailBodyHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/welcome.html", \%Data);
   my $EmailBodyTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/welcome.txt", \%Data);

   $Data{"BodyHTML"} = $EmailBodyHTML;
   $Data{"BodyTXT"} = $EmailBodyTXT;

   my $EmailHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
   my $EmailTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   $Mailer->sendEmail($User->{Email}, 
                    $Lists::SETUP::MAIL_FROM_LISTS, 
                    $subject, 
                    $EmailHTML, $EmailTXT, $boundary);

}

=head2 sendNotificationEmail

Sends email to IT as per the email in Lists::SETUP::TO_IT_EMAIL

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $MessageID 

=back

=cut

#############################################
sub sendNotificationEmail {
#############################################
   my $self = shift;
   my $MessageID = shift;

   $self->{Debugger}->debug("Lists::Utilities::Mailer::sendNotificationEmail");

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $MessagesObj = $self->{DBManager}->getTableObj("Messages");
   my $MessageActionsObj = $self->{DBManager}->getTableObj("MessageActions");

   my $Messages = $MessagesObj->get_by_ID($MessageID);
   my $MessageActions = $MessageActionsObj->get_all();
   my $User = $UserObj->get_by_ID($Messages->{UserID});
   my $Doer = $UserObj->get_by_ID($Messages->{DoerID});

   my %Data;
   $Data{"Username"} = $User->{Username};
   $Data{"Phrase"} = $MessageActions->{$Messages->{Action}}->{Phrase};
   $Data{"DoerURL"} = $Lists::SETUP::URL.$self->{UserManager}->getUserURL($Doer); 
   $Data{"DoerName"} = $Doer->{Username};
   $Data{"Date"} = Lists::Utilities::Date::getFullHumanFriendlyDate($Messages->{CreateDate});

   my $subject = "";
   if($Messages->{Action} == 1){
      # Comment
      my $List = $self->{ListObj}->get_by_ID($Messages->{SubjectID});
      my $ListGroupName = $self->{ListGroupObj}->get_field_by_ID("Name", $List->{ListGroupID});
      $Data{"SubjectURL"} = $Lists::SETUP::URL.$self->{ListObj}->getListURL($List, $ListGroupName);
      $Data{"SubjectName"} = $List->{Name};
      $subject = "Your list has received a comment at List Central";
   }elsif($Messages->{Action} == 2){
      # Board Post
      $Data{"SubjectURL"} = $Lists::SETUP::URL.'/'.$self->{UserManager}->getUserURL($self->{UserManager}->{ThisUser});
      $Data{"SubjectName"} = "your board";

      $subject = "Someone has written on your board at List Central";
   }

   $Data{"TXT"} = "$Data{DoerName} ($Data{DoerURL}) $Data{Phrase} $Data{SubjectName} ($Data{SubjectURL})";

   
   my $EmailBodyHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/notification.html", \%Data);
   my $EmailBodyTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/notification.txt", \%Data);

   $Data{"BodyHTML"} = $EmailBodyHTML;
   $Data{"BodyTXT"} = $EmailBodyTXT;

   my $EmailHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
   my $EmailTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});
   $Mailer->sendEmail($User->{Email}, 
                    $Lists::SETUP::MAIL_FROM_LISTS, 
                    $subject, 
                    $EmailHTML, $EmailTXT, $boundary);

}


=head2 sendAccountDetailsEmail

Sends the account details to the user, part of the forgot password process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $User - Reference to a hash with the new user to send the email to

=back

=cut

#############################################
sub sendAccountDetailsEmail {
#############################################
   my $self = shift;
   my $User = shift;

   $self->{Debugger}->debug("Lists::ListManager::sendAccountDetailsEmail with user: $User->{Username}");

   my %Data;
   $Data{"User"} = $User;

   my $subject = "List Central account details";
   my $EmailBodyHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/account_details.html", \%Data);
   my $EmailBodyTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/account_details.txt", \%Data);

   $Data{"BodyHTML"} = $EmailBodyHTML;
   $Data{"BodyTXT"} = $EmailBodyTXT;

   my $EmailHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
   my $EmailTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});

   $Mailer->sendEmail($User->{Email}, 
                    $Lists::SETUP::MAIL_FROM_LISTS, 
                    $subject, 
                    $EmailHTML, $EmailTXT, $boundary);

}

=head2 sendFeedbackNotify

Sends the account details to the user, part of the forgot password process

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object

=back

=cut

#############################################
sub sendFeedbackNotify {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("Lists::ListManager::sendFeedbackNotify ");

   my %Data;
   $Data{"User"} = "$self->{UserManager}->{ThisUser}->{Username} ($self->{UserManager}->{ThisUser}->{ID})";
   $Data{"Message"} = $self->{cgi}->{"Feedback.Message"};
   $Data{"Email"} = $self->{cgi}->{"Feedback.Email"};

   my $EmailBodyHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/feedback_notify.html", \%Data);
   my $EmailBodyTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/feedback_notify.txt", \%Data);

   $Data{"BodyHTML"} = $EmailBodyHTML;
   $Data{"BodyTXT"} = $EmailBodyTXT;

   my $EmailHTML = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.html", \%Data);
   my $EmailTXT = $self->processPage("$Lists::SETUP::DIR_PATH/emails/email_template.txt", \%Data);

   my $ip = $ENV{'REMOTE_ADDR'};
   $ip =~ s/\.//g;
   my $boundary = "mimepart_" . time() . "_" . $ip;

   my $Mailer = new Lists::Utilities::Mailer(Debugger=>$self->{Debugger});

   $Mailer->sendEmail($Lists::SETUP::FEEDBACK_TO_LISTS, 
                    $Lists::SETUP::MAIL_FROM_LISTS, 
                    "LC - New feedback", 
                    $EmailHTML, $EmailTXT, $boundary);

}

=head2 getAvatar

Given a UserID returns the users avatar

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $param

=back

=cut

#############################################
sub getAvatar {
#############################################
   my $self = shift;
   my $param = shift;

   $self->{Debugger}->debug("in Lists::ListManager::getAvatar with param: $param");

   my $UserID = ""; 
   my $class = "";
   if($param =~ m/^(\d+)(\D+)/){
      $UserID = $1;
      $class = $2;
   }

   my $UserObj = $self->{DBManager}->getTableObj("User");
   my $User = $UserObj->get_by_ID($UserID);
   $self->{UserManager}->getUserAvatar($User);

   my %Data;
   $Data{"AvatarDisplay"} = $User->{"AvatarDisplay"};
   $Data{"UserURL"} = $self->{UserManager}->getUserURL($User);
   $Data{"Class"} = $class;

   my $avatar = $self->processPage("$Lists::SETUP::DIR_PATH/widgets/avatar.html", \%Data);

   return $avatar;
}

=head2 getUnderAboutImage

Given a UserID returns the users avatar

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object

=back

=cut

#############################################
sub getUnderAboutImage {
#############################################
   my $self = shift;

   $self->{Debugger}->debug("in Lists::ListManager::getUnderAboutImage");

   # Add the graphic for the about account
   if($self->{cgi}->{UserID} == $Lists::SETUP::ABOUT_USER_ACCOUNT){
      return qq~<div class="UnderAboutNav"><img src="/images/aboutArrow.png" alt="" /></div>~;
   }else{
      return "";
   }
}


=head2 getUnderAboutImage

Given a UserID returns the users avatar

=over 4

=item B<Parameters :>

   1. $self - Reference to a Lists object
   2. $ListID

=back

=cut

#############################################
sub setDateMadePublic {
#############################################
   my $self = shift;
   my $ListID = shift;

   $self->{Debugger}->debug("in Lists::ListManager::getUnderAboutImage");

   my $ListPointsObj = $self->{DBManager}->getTableObj("ListPoints");
   my $ListPoints = $ListPointsObj->getByListID($ListID);

   # Only set this once to prevent abuse
   if(! $ListPoints->{DateMadePublic}){
      if(!$ListPoints->{ID}){
         my $Ranker = new Lists::Utilities::Ranker(Debugger => $self->{Debugger}, DBManager => $self->{DBManager});
         $Ranker->setListPopularityPoints($self->{cgi}->{ListID});
      }
      $ListPoints = $ListPointsObj->getByListID($self->{cgi}->{ListID});
      $ListPointsObj->update("DateMadePublic", time(), $ListPoints->{ID});
   }
}

1;

=head1 AUTHOR INFORMATION

   Author: Marilyn Burgess with help from the ApplicationFramework
   Created: 1/11/2007

=head1 BUGS

   Not known

=cut


