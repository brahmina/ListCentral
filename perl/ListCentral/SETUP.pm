package ListCentral::SETUP;

##########################################################
# Author : Brahmina Burgess
# Date   : 2/7/2015 .. 21/1/2008
# Version: 1.0
###########################################################


   $DEBUG = 3; # Turn Debug on and off 3 == stderr

   #$URL = "http://192.168.0.150/Lists/";
   #$SCRIPTS_URL = "http://192.168.0.150/perl/scripts/Lists/";
   $URL = "http://listcentral.brahminacreations.com";
   $URL2 = "http://listcentral.brahminacreations.com";
   $ADMIN_URL = "http://listcentral-admin.brahminacreations.com";

   # Start Settings #
   %CONSTANTS = (
                 'DEFAULT_LIST_SEARCH_RESULTS_PER_PAGE' => 10,
                 'DEFAULT_USER_SEARCH_RESULTS_PER_PAGE' => 10,
                 'AMAZON_CHOICE_LIMIT' => 12,
                 'CCIMAGE_CHOICE_LIMIT' => 12,
                 'BOARD_POSTS_PER_PAGE' => 10,
                 'COMMENT_LIMIT_PER_PAGE' => 10,
                 'DEFAULT_THEME' => 1,
                 'FAQ_LISTID' => 193,
                 'SAMPLE_LIST_NAME_LIMIT' => 48,
                 'SAMPLE_LIST_NAME_WITH_IMAGES_LIMIT' => 26,
                 'GOOGLE_IMAGE_GETTER_LIMIT' => 5,
                 'GOOGLE_IMAGE_WIDTH' => 250,
                 'EDIT_LIST_ITEM_GRAPHIC' => "$DIR_PATH/images/icons/edit.gif",
                 'URL' => "http://listcentral.brahminacreations.com",
                 'NUMBER_OF_TOP_LIST_ITEMS_BRIEF_LIST_VIEW' => 3,
                 'USERS_CANT_RATE_THEIR_OWN_LISTS' => 0,
                 'DEFAULT_PAGE_TITLE' => "lc: list central!",
                 'LISTING_ROWS_LIMIT' => 10,
                 'MESSAGE_LIMIT' => 40,
                 'MONITORING' => '209.61.157.78',
                 'DELETE_IMAGES' => 0, 
                 'RECENT_LISTS_LIMIT' => 10,
                 'RECENT_SEARCHES_LIMIT' => 6,
                 'IMAGE_LIST_ITEM_LIMIT' => 15,
                 'IMAGE_IN_EMAIL_LIMIT' => 15, 
                 'LIST_ITEM_LIMIT' => 500,
                 'LIST_ITEM_LIMIT_PER_PAGE' => 150,
                 'LIST_ITEM_SAMPLE_SPACES' => 3,
                 'THREE_D_TAG_CLOUD_LIMIT' => 35,
                 'MAX_LIST_NAME_LENGTH_LISTING' => 72,
                 'EMBED_MAX_WIDTH' => 370,
                 'LWP_TIMEOUT' => 30,
                 'RECENT_COMMENTS_WIDGET_LIMIT' => 5,
                 'SECURE_URL' => 'https://listcentral.brahminacreations.com'
                 );
   
   $BLOCK_IE = 0; # Tell users of IE to go get Firefox
   
   $UNDER_CONSTUCTION = 0;
   $BETA_INVITE_ONLY = 0;
   $USE_FIREBUG_LITE = 0;
   $GOOGLE_CHROME_FRAME = 0;
   $BLOCK_ADMIN = 0;

   @PERMITTED_IPS = ('162.156.161.60');

   $MY_IP_HOME = '162.156.161.60'; # Prevent Hitlog recordings from this IP
   $MY_IP_WORK = '162.156.161.60';

   $DIR_PATH = '/home/apache/listcentral.brahminacreations.com/html'; # The HTML directory
   $LOG_FILE = '/home/apache/listcentral.brahminacreations.com/Listslog.txt'; # # Where to write the log file
   $ROOT_PATH = '/'; # For links in the html templates
   $ADMIN_DIR_PATH = '/home/apache/listcentral-admin.brahminacreations.com/html';

   $CACHE_BASE_DIR = "$DIR_PATH/cache";
   $CACHE_EXPIRY = 5;

   $ABOUT_USER_ACCOUNT = 35;
   #$BLOG_RSS_URL = "http://feeds2.feedburner.com/ListCentralBlog";
   #$BLOG_TEASER_NUMBER_OF_POSTS = 3;
                   
   $ENCRYPT_KEY = "208044796065128821600883616717160739876";

   # Gravatar
   $AVATAR_DEFAULT_IMAGE = "/images/icons/default.gif";
   $GRAVATAR_DEFAULT_SIZE = 100;
   $GRAVATAR_SMALL_SIZE = 40;

   # Google things
   $GOOGLE_SITE_MAP = "$DIR_PATH/google_sitemap";

   # Amazon
   $AMAZON_ENDPOINT = 'ecs.amazonaws.com';
   $AMAZON_BASE_URL = 'http://' . $AMAZON_ENDPOINT . '/onca/xml?Service=AWSECommerceService';
   $AMAZON_ASSOCIATE_TAG = 'listcentral-20';
   
   %AMAZON_REQUESTS;
   # US
   $AMAZON_REQUESTS{'ENDPOINT'}{'US'} = 'ecs.amazonaws.com';
   $AMAZON_REQUESTS{'BASE_URL'}{'US'} = 'http://' . $AMAZON_REQUESTS{'ENDPOINT'}{'US'} . '/onca/xml?Service=AWSECommerceService';
   $AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'US'} = 'listcentral-20';
   # Canada
   $AMAZON_REQUESTS{'ENDPOINT'}{'CA'} = 'ecs.amazonaws.ca';
   $AMAZON_REQUESTS{'BASE_URL'}{'CA'} = 'http://' . $AMAZON_REQUESTS{'ENDPOINT'}{'CA'} . '/onca/xml?Service=AWSECommerceService';
   $AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'CA'} = 'listcentralca-20';
   # UK
   $AMAZON_REQUESTS{'ENDPOINT'}{'UK'} = 'ecs.amazonaws.co.uk';
   $AMAZON_REQUESTS{'BASE_URL'}{'UK'} = 'http://' . $AMAZON_REQUESTS{'ENDPOINT'}{'UK'} . '/onca/xml?Service=AWSECommerceService';
   $AMAZON_REQUESTS{'ASSOCIATE_TAG'}{'UK'} = 'listcentraluk-21';

   $AMAZON_TOKEN = '1JGRS89XPTZD10NSYZ82';
   $AMAZON_SECRET = 'D5o+S9z2y2x69r6WmAslX4RVWF3O0fXm1bJKOVJe';

   #ListCentral.me 
   $GOOGLE_ANALYTICS_CODE = 'UA-5860552-4';
   $MAX_AMAZON_IMAGE_WIDTH = 400;

   %AMAZON_MODES = ("Books" => "Books",
                    "Music" => "Music",
                    "VideoGames" => "Video Games",
                    "Software" => "Software",
                    "DVD" => "DVD",
                    "Apparel" => "Apparel",
                    "Automotive" => "Automotive",
                    "Baby" => "Baby",
                    "Beauty" => "Beauty",
                    "Books" => "Books",
                    "Classical" => "Classical",
                    "DigitalMusic" => "Digital Music",
                    "Electronics" => "Electronics",
                    "GourmetFood" => "Gourmet Food",
                    "HealthPersonalCare" => "Health Personal Care",
                    "HomeGarden" => "HomeGarden",
                    "Industrial" => "Industrial",
                    "Jewelry" => "Jewelry",
                    "Kitchen" => "Kitchen",
                    "Magazines" => "Magazines",
                    "Merchants" => "Merchants",
                    "MusicalInstruments" => "Musical Instruments",
                    "OfficeProducts" => "Office Products",
                    "OutdoorLiving" => "Outdoor Living",
                    "PCHardware" => "PC Hardware",
                    "PetSupplies" => "Pet Supplies",
                    "Photo" => "Photo",
                    "SilverMerchants" => "Silver Merchants",
                    "SportingGoods" => "Sporting Goods",
                    "Tools" => "Tools",
                    "Toys" => "Toys",
                    "Video" => "Video",
                    "Wireless" => "Wireless",
                    "WirelessAccessories" => "Wireless Accessories"
                    );



   $LIST_RATINGS_WIDTH = 18;
   $SOURCE_THEME_IMAGES_DIR = "$DIR_PATH/images/Base";

   $TAG_CLOUD_NUMBER_OF_TAGS = 40;
   $TAG_CLOUD_MIN_SIZE = 8;
   $TAG_CLOUD_MAX_SIZE = 18;

   # Admin constants
   $ACTIVE_USER_REPORT_ROWS = 8;
   $POPULAR_USER_REPORT_ROWS = 20;
   $TROUBLESOME_USER_REPORT_ROWS = 20;
   $POPULAR_LIST_REPORT_ROWS = 20;
   $POPULAR_LIST_BREAKDOWN_ROWS = 10;
   $TOP_REFERRERS_REPORT_LIMIT = 20;
   $SEARCHES_REPORT_LIMIT = 20;
   $REPORT_DAYS_BACK = 90;
   $DEFAULT_ADMIN_PAGE_TITLE = "List Central Admin";
   $BASE_CSS_DIR = "$DIR_PATH/css";
   @SUMMARY_STATS_DAYS_BACK = (1, 2, 3, 4, 5, 6, 7, 0);

   %THEME_POSITION = (
                         1 => "Background Colour",
                         2 => "Main Colour",
                         3 => "Accent Colour",
                         4 => "Secondary Accent Colour",
                         5 => "Tertiary  Accent Colour"
                         );
   @THEME_BASE_COLORS = ('#ffffff', '#121d52', '#1d687a', '#bdeaff', '#f8f8ff');

   $TABLE_TEMPLATE_DIR = "$DIR_PATH/DB/";
   $USER_CONTENT_DIRECTORY = "$DIR_PATH/usercontent";
   $USER_CONTENT_PATH = "/usercontent";

   %LIST_ITEM_EXTRA_FILES = ( "Image" => "$DIR_PATH/listpieces/list_item_image.html",
                              "Amazon" => "$DIR_PATH/listpieces/list_item_amazon.html",
                              "CCImage" => "$DIR_PATH/listpieces/list_item_ccimage.html",
                              "Embed" => "$DIR_PATH/listpieces/list_item_image.html" );

   $PASSWORD_MIN_LENGTH = 6;
   $SALT = 'vu3laEP21AdjAaj9jk2mJen2m1sdA43vn82iisn';

   # Image Stuff
   $TEMP_IMAGE_DIRECTORY = "$DIR_PATH/TEMPIMAGES/";
   $DELETE_ORIGINAL_IMAGE = 0;
   $MAX_IMAGE_WIDTH_LARGE = 850;
   $MAX_IMAGE_WIDTH_MEDIUM = 400;
   $MAX_IMAGE_WIDTH_SMALL = 160;
   $MAX_AVATAR_WIDTH = 100;
   $IMAGE_QUALITY = 100;

   # Templates
   $MAIN_TEMPLATE = "$DIR_PATH/templates/main_template.html";
   $MAIN_TEMPLATE_NO = "$DIR_PATH/templates/main_template_no.html";
   $SMALL_TEMPLATE = "$DIR_PATH/templates/small_template.html";
   $IMAGE_TEMPLATE = "$DIR_PATH/templates/image_template.html";

   $HIDING = "$DIR_PATH/hiding.html";

   # Admin Templates
   $ADMIN_MAIN_TEMPLATE = "$ADMIN_DIR_PATH/main_template.html";
   $ADMIN_SMALL_TEMPLATE = "$ADMIN_DIR_PATH/small_template.html";

   # Main pages
   $INDEX = "$DIR_PATH/index.html";

   ## DB Connect Info
   $HOST_PORT_INFO = "";
   $DB_NAME = "ListCentral";
   $DB = "DBI:mysql:$DB_NAME$HOST_PORT_INFO";
   $USER_NAME = "inorder";
   $PASSWORD = "bywellpriorities";
   $PACKAGE_NAME = "ListCentral";

   # Google apps SMTP emailing
   $MAIL_HOST = 'smtp.gmail.com';
   $MAIL_PORT = 465; # 587 
   $MAIL_FROM_LISTS = 'brahmina@brahminacreations.com';
   $MAIL_FROM_BRAHMINA = 'brahmina@brahminacreations.com';
   $MAIL_FROM_FEEDBACK = 'brahmina@brahminacreations.com';
   $FROM_IT_EMAIL = 'brahmina@brahminacreations.com'; # Where to send tech problem emails
   $MAIL_PASSWORD = 'BrahmanLove8Abundance69';
   @TEST_EMAILS = ('brahmina@brahminacreations.com');

    # Emails
   $FROM_EMAIL = 'brahmina@brahminacreations.com'; # From email address for all emails
   $FROM_EMAIL_LISTS = 'brahmina@brahminacreations.com';
   $DEBUG_TO_EMAIL = 'brahmina@brahminacreations.com'; # Address to send all emails to if debug is turned on
   $TO_IT_EMAIL = 'brahmina@brahminacreations.com'; # Where to send tech problem emails
   $FEEDBACK_TO_LISTS = 'brahmina@brahminacreations.com'; # Where notifications of feedback sent go


   $LENGTH_OF_PERSISTENT_COOKIE_RANDOM_STRING = 24;

   @GOOGLE_IMAGE_GETTER_TEMPLATES = ("$DIR_PATH/Utilites/Google/google_image_getter_template.html", 
                                     "$DIR_PATH/Utilites/Google/google_image_getter_subtemplate.html");

   %SMALL_TEMPLATES = ("$DIR_PATH/email_list.html" => 1,
                       "$DIR_PATH/email_list_success.html" => 1,
                       "$DIR_PATH/upload_image.html" => 1,
                       "$DIR_PATH/upload_image_success.html" => 1,
                       "$DIR_PATH/email_user.html" => 1,
                       "$DIR_PATH/email_user_success.html" => 1
                        );

   %ACCOUNT_ONLY_PAGES = ("$DIR_PATH/settings.html" => 1,
                          "$DIR_PATH/create_and_edit.html" => 1,
                          "$DIR_PATH/messages.html" => 1,
                          "$DIR_PATH/owner/settings.html" => 1,
                          "$DIR_PATH/owner/create_and_edit.html" => 1,
                          "$DIR_PATH/owner/messages.html" => 1
                           );
   %NOT_LOGGED_IN_TODOS = ("AddFeedback" => 1,
                           "AddNotifyOfAlphaRelease" => 1,
                           "AddUser" => 1,
                           "EmailList" => 1,
                           "Login" => 1,
                           "SearchLists" => 1,
                           "SearchUsers" => 1,
                           "SendForgotPassword" => 1);

   @PERMITTED_IMAGE_EXTENSIONS = ('jpeg', 'jpg', 'gif', 'png');

   %MESSAGES = ('AT_LIST_ITEM_LIMIT' => 'We are currently enforcing a 500 list item limit. Please delete items if you would like to add new items to this list',
                'BETA_ONLY' => 'List Central is currently in Private Beta',
                'BLANK_BIRTHDAY' => 'Please fill in your birthday, as we require it for legal reasons to ensure you are 13 or older.',
                'BLANK_BOARD_MESSAGE' => 'Blank board message',
                'BLANK_COMMENT' => 'You must enter something for the comment',
                'BLANK_EMAIL' => 'Blank email address',,
                'BLANK_LIST_NAME' => 'Blank list name',
                'BLANK_LIST_ITEM' => 'You must enter something for the list item!',
                'BLANK_NAME' => 'Blank name',
                'BLANK_PASSWORD' => 'Blank password',
                'BLANK_SEARCH_QUERY' => 'Blank search query',
                'BLANK_TAG' => 'You must enter something for the tag',
                'BLANK_USERNAME' => 'Blank username!',
                'DEACTIVATED_ACCOUNT' => 'Your account has been deactivated. If you feel this is in error, please <a href="/contact.html">contact us</a>',
                'DEACTIVATED_USER' => 'Seems you\'ve stumbled on to a deativated account. Nothing to see here',
                'DELETED_LIST' => 'The list you are looking for has been deleted',
                'DISALLOWED_CHARACTERS' => 'Only alphanumeric characters are permitted',
                'DUPLICATE_EMAIL' =>'There is an account for that email address, please use another',
                'DUPLICATE_USERNAME' => 'That username is taken, please try another',
                'FAIL_RECAPTCHA' => 'Are you sure you are human? You failed the reCAPTCHA, please try again',
                'FAIL_PASSWORD_EDIT_ACCOUNT' => 'Incorrect password, please try again',
                'INCORRECT_PASSWORD' => 'Incorrect password',
                'INCORRECT_USERNAME' => 'Incorrect username',
                'IMAGE_UPLOAD_FAIL' => 'Image upload failed',
                'INSERT_ERROR' => 'There was a problem with the database',
                'INVALID_STATUS_SET' => 'Invalid Status Set',
                'INVALID_EMAIL' => 'The email address you entered is invalid',
                'INVALID_PASSWORD' => 'Your password must be between 6 and 15 characters long, and include both letters and numbers or symbols. Please try again',
                'MALFORMED_DATE' => 'The date you submitted in invalid, please try again.',
                'MISC_ERROR' => 'There was an error!',
                'NO_EMAIL_FOUND' => 'We do not have an account corresponding to the email address: ',
                'NO_FEEDBACK_TYPE' => 'Please Indicate why you are contacting List Central',
                'NO_LIST_ID' => 'Seems this list is no longer available',
                'NO_ONE_LOGGED_IN_COMMENT' => 'You must be logged in to comment',
                'NO_PERMISSION' =>'You do not have permission to access that page. Perhaps you need to log in.',
                'NO_PERMISSION_DELETE_BOARD_POST' => 'You do not have permission to delete that post',
                'NO_PERMISSION_DELETE_COMMENT' => 'You do not have permission to delete that comment',
                'NO_PERMISSION_DELETE_GROUP' => 'You do not have permission to delete that list group',
                'NO_PERMISSION_DELETE_ITEM' => 'You do not have permission to delete that list item',
                'NO_PERMISSION_DELETE_STATUS_SET' => 'You do not have permission to delete that list group',
                'NO_PERMISSION_EDIT_ACCOUNT' => 'You do not have permission to edit that account information',
                'NO_PERMISSION_EDIT_LIST' => 'You are not allowd to edit a list that does not belong to you!',
                'NO_PERMISSION_EDIT_LIST_ITEM' => 'You are not allowd to edit a list item that does not belong to you!',
                'NO_PERMISSION_RATE_LIST' => 'You must be logged in to rate lists',
                'NO_PERMISSION_VIEW_LIST' => 'You do not have permission to see that list, it is private!',
                'NO_TOP_LISTS' => 'No pages of top lists today!',
                'NO_USER' => 'The user you are looking for isn\'t here anymore',
                'NOT_PERMITTED_IMAGE_TYPE' => 'Not a permitted image type',
                'ONLY_ALPHANUMERIC_NAME' => 'Only alphanumeric characters are permitted in names',
                'NO_AT_IN_USERNAME' => 'The @ symbol is not permitted in usernames', 
                'PASSWORD_NONMATCH' => 'Passwords do not match',
                'TOO_YOUNG' => 'We are sorry, but you must be at least 13 years old to be a member of List Central.',
                'TRUNCATED_EMAIL_MESSAGE' => "For the sake of saving bytes, and not overwhelming your email, this list has been truncated.",
                'UNPERMITTED_HTML', 'You entered html that is not permitted!');

   %RANKING_TIMEFRAMES = (
                      'MostRecent' => (60*60*3), # 3 hours
                      '24Hours' => (60*60*24), # 24 hours
                      '72Hours' => (60*60*24*3), # 3 days
                      'LastWeek' => (60*60*24*7), # 1 week
                      'LastMonth' => (60*60*24*30), # 1 month
                      'LastYear' => (60*60*24*365), # 1 year
                      'AllTime' => 0); 

1;

=head1 NAME

   ListCentral::SETUP.pm

=head1 SYNOPSIS

   ListCentral::SETUP

=head1 DESCRIPTION

Holds contants used by Lists

=head1 AUTHOR INFORMATION

   Author: Brahmina Burgess
   Last Updated: 2/7/2015 .. 21/1/2008

=head1 BUGS

   Not known

=head1 SEE ALSO

   Lists.*

=cut







