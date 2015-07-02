package Lists::Utilities::Date;
use strict;

##########################################################
# Lists::Utilities::DAte 
##########################################################

=head1 NAME

   Lists::Utilities::Date.pm

=head1 SYNOPSIS

   Not an object, just use subs

=head1 DESCRIPTION

Used to manipulate the foramt of dates

=head2 getHumanFriendlyDate

Given an epoch date, returns only the date in nice, friendly hunam format

Wednesday November 12 at 10:25

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Friendly date

=back

=cut

#############################################
sub getHumanFriendlyDate {
#############################################
   my $epoch = shift;

   if(! $epoch){
      $epoch = time();
   }

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $WeekDay = getWeekDay($weekday);
   my $Month = getMonth($month);
   $date = getWrittenDate($date);
   $year += 1900;

   my $thisYear = getThisYear();

   my $Date;
   if($thisYear == $year){
      my $am_pm;
      if($hour > 12){
         $hour = $hour - 12;
         $am_pm = "pm";
      }elsif($hour == 12){
         $am_pm = "pm";
      }else{
         $am_pm = "am";
      }
      $Date = sprintf("$WeekDay $Month $date at $hour:%02d$am_pm", $min);
   }else{
      $Date = sprintf("$WeekDay $Month $date, $year");
   }

   return $Date;
}

=head2 getFullHumanFriendlyDate

Given an epoch date, returns only the date in nice, friendly hunam format

Wednesday November 12 at 10:25

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Friendly date

=back

=cut

#############################################
sub getFullHumanFriendlyDate {
#############################################
   my $epoch = shift;

   if(! $epoch){
      $epoch = time();
   }

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $WeekDay = getWeekDay($weekday);
   my $Month = getMonth($month);
   $date = getWrittenDate($date);
   $year += 1900;

   my $thisYear = getThisYear();

   my $am_pm;
   if($hour > 12){
      $hour = $hour - 12;
      $am_pm = "pm";
   }elsif($hour == 12){
      $am_pm = "pm";
   }else{
      $am_pm = "am";
   }
   my $Date = sprintf("$WeekDay $Month $date $year at $hour:%02d$am_pm",$min);

   return $Date;
}

=head2 getShortHumanFriendlyDate

Given an epoch date, returns only the date in nice, friendly hunam format

November 12 at 10:25

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Friendly date

=back

=cut

#############################################
sub getShortHumanFriendlyDate {
#############################################
   my $epoch = shift;

   if(! $epoch){
      $epoch = time();
   }
      
   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $WeekDay = getWeekDay($weekday);
   my $Month = getMonthAbrv($month);
   $year += 1900;
   $date = getWrittenDate($date);

   my $thisYear = getThisYear();

   my $Date;
   if($thisYear == $year){
      my $am_pm;
      if($hour > 12){
         $hour = $hour - 12;
         $am_pm = "pm";
      }elsif($hour == 12){
         $am_pm = "pm";
      }else{
         $am_pm = "am";
      }
      $Date = sprintf("$Month. $date at $hour:%02d$am_pm",$min);
   }else{
      $Date = sprintf("$Month. $date, $year");
   }

   return $Date;
}

=head2 getShortHumanFriendlyDate

Given an epoch date, returns only the date in nice, friendly hunam format

November 12 at 10:25

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Friendly date

=back

=cut

#############################################
sub getBriefHumanFriendlyDate {
#############################################
   my $epoch = shift;

   if(! $epoch){
      $epoch = time();
   }
      
   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $WeekDay = getWeekDay($weekday);
   my $Month = getMonthAbrv($month);
   $year += 1900;
   $date = getWrittenDate($date);

   my $thisYear = getThisYear();

   my $Date = sprintf("$Month $date, $year", $hour,$min);

   return $Date;
}

=head2 getBriefDate

Given an epoch date, returns only the date in brief format day/month/year

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Brief date

=back

=cut

#############################################
sub getBriefDate {
#############################################
   my $epoch = shift;

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $Date = sprintf("%4d/%02d/%02d", $year+1900,$month+1,$date,$hour,$min,$sec);

   return $Date;
}

=head2 getBriefDateAndTime

Given an epoch date, returns only the date in brief format day/month/year hour:minue:second

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Brief date

=back

=cut

#############################################
sub getBriefDateAndTime {
#############################################
   my $epoch = shift;

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime($epoch);
   my $Date = sprintf("%4d/%02d/%02d %02d:%02d:%02d", $year+1900,$month+1,$date,$hour,$min,$sec);

   return $Date;
}

=head2 getWeekDay

Given a number returns corresponding day of the week

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $WeekDay 

=back

=cut

#############################################
sub getWeekDay {
#############################################
   my $weekday = shift;

   my @WeekDays = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

   return $WeekDays[$weekday];
}

=head2 getMonth

Given a number returns corresponding month

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Month

=back

=cut

#############################################
sub getMonth {
#############################################
   my $month = shift;

   my @Months = qw( January February March April May June July August September October November December );

   return $Months[$month];
}

=head2 getMonthAbrv

Given a number returns corresponding month

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Month

=back

=cut

#############################################
sub getMonthAbrv {
#############################################
   my $month = shift;

   my @Months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );

   return $Months[$month];
}

=head2 getWrittenDate

Given a number returns that number with the appropriate ending for friendly date

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date

=back

=cut

#############################################
sub getWrittenDate {
#############################################
   my $date = shift;

   my $lastDigit;
   if($date =~ m/(\d{1})$/){
      $lastDigit = $1;
   }

   if($lastDigit == 1){
      $date .= "st";
   }elsif($lastDigit == 2 && $date !~ m/12$/){
      $date .= "nd";
   }elsif($lastDigit == 3 && $date !~ m/13$/){
      $date .= "rd";
   }else{
      $date .= "th";
   }

   return $date;
}

=head2 getThisYear

Given an epoch date, returns only the date in brief format day/month/year

=over 4

=item B<Returns :>

   1. $thisYear - This year

=back

=cut

#############################################
sub getThisYear {
#############################################

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime(time());
   $year += 1900;

   return $year;
}

=head2 getThisYear

Given an epoch date, returns only the date in brief format day/month/year

=over 4

=item B<Returns :>

   1. $thisYear - This year

=back

=cut

#############################################
sub getTodayAtMidnight {
#############################################

   use POSIX;

   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime(time());
   my $todayAtMidnight = mktime(0, 0, 0, $date, $month, $year, $weekday,$yearday, $isdst);
   return $todayAtMidnight;
}


=head2 getThisYear

Given an epoch date, returns only the date in brief format day/month/year

=over 4

=item B<Returns :>

   1. $thisYear - This year

=back

=cut

#############################################
sub getDateDropDowns {
#############################################
   my $birthfield = shift;
   my $selectname = shift;
   my $class = shift;
   my $value = shift;

   my $options = ""; my $selected = "";
   if($birthfield =~ m/day/i){
      foreach my $index(0..30) {
         my $actualdate = $index + 1;
         $selected = "";
         if($index == $value){
            $selected = " selected";
         }
         $options .= "<option value='$index'$selected>$actualdate</option>";
      }
   }elsif($birthfield =~ m/month/i){
      foreach my $index (0..11) {
         my $month = getMonth($index);
         $selected = "";
         if($index == $value){
            $selected = " selected";
         }
         $options .= "<option value=\"$index\"$selected>$month</option>";
      }
   }elsif($birthfield =~ m/year/i){
      my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime(time());
      for (my $i = ($year+1900); $i > 1910; $i--) {
         $selected = "";
         if($i == $value){
            $selected = " selected";
         }
         $options .= "<option value='$i'$selected>$i</option>";
      }
   }

   my $select = "";
   if($options){
      if($class){
         $class = "class='$class'";
      }
      $select = qq~
                  <select name="$selectname" $class>
                     <option value="">$birthfield</option>
                     $options
                  </select>
               ~;
   }else{
      $select = "SELECT?!?!?";
   }

   return $select;
}


=head2 olderThan12

Given the birth day, month and year, returns true if a person born on the given
date is 13 or older

=over 4

=item B<Params :>

   1. $birthday
   2. $birthmonth
   3. $birthyear

=itme B<Returns :>

   1. True or false

=back

=cut

#############################################
sub olderThan12 {
#############################################
   my $birthday = shift;
   my $birthmonth = shift;
   my $birthyear = shift;


   my $isolder = 0;
   my ($sec,$min,$hour,$date,$month,$year,$weekday,$yearday,$isdst) = localtime(time());
   $year = $year + 1900;

   if($year - $birthyear > 12){
      $isolder = 1;
   }elsif($year - $birthyear == 12){
      if($month > $birthmonth){
         $isolder = 1;
      }elsif($month == $birthmonth){
         if($date >= $birthday){
            $isolder = 1;
         }
      }
   }
   return $isolder;
}


=head2 getTimeSince

Given an epoch date, returns the amount of time since that date in 
nice human fomat

Wednesday November 12 at 10:25

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $TimeSince - Friendly date

=back

=cut

#############################################
sub getTimeSince {
#############################################
   my $epoch = shift;

   my $now = time();

   my $difference = $now - $epoch;

   my $TimeSince = "";
   if($difference < 60){
      $TimeSince = "less than a minute";
   }elsif($difference < 60*60){
      my $minutes = int($difference / 60);
      if($minutes == 1){
         $TimeSince = "$minutes minute";
      }else{
         $TimeSince = "$minutes minutes";
      }
   }elsif($difference < 60*60*24){
      my $hours = int($difference / (60*60));
      if($hours == 1){
         $TimeSince = "$hours hour";
      }else{
         $TimeSince = "$hours hours";
      }
   }elsif($difference < 60*60*24*7){
      my $days = int($difference / (60*60*24));
      if($days == 1){
         $TimeSince = "$days day";
      }else{
         $TimeSince = "$days days";
      }
   }elsif($difference < 60*60*24*7*4){
      my $weeks = int($difference / (60*60*24*7));
      if($weeks == 1){
         $TimeSince = "$weeks week";
      }else{
         $TimeSince = "$weeks weeks";
      }
   }elsif($difference < 60*60*24*7*4*12){
      my $months = int($difference / (60*60*24*7*4));
      if($months == 1){
         $TimeSince = "$months month";
      }else{
         $TimeSince = "$months months";
      }
   }else{
      $TimeSince = "over a year";
   }

   return $TimeSince;
}

=head2 getAge

Given a birth day, month and year, returns and age

=over 4

=item B<Parameters :>

   1. $birthday - The Day of the month
   2. $birthMonth - The birth month
   3. $birthYear

=item B<Returns :>

   1. $age - The age

=back

=cut

#############################################
sub getAge {
#############################################
   my $birthDay = shift;
   my $birthMonth = shift;
   my $birthYear = shift;

   my $now = time();

   # TODO - Calculate age
   my $age = "";

   return $age;
}

=head2 getHumanFriendlyDate

Converts the date and time of the format "12-12-2009 @ 15:29" to epoch time

=over 4

=item B<Parameters :>

   1. $epoch - The epoch date to be formatted

=item B<Returns :>

   1. $Date - Friendly date

=back

=cut

#############################################
sub getEpochDateTime {
#############################################
   my $date = shift;

   my $epoch;
   if(! $date){
      $epoch = 0;
   }elsif($date =~ m/(\d+)-(\d+)-(\d+) @ (\d+):(\d+)/){
      my $day = $1;
      my $month = $2;
      my $year = $3;
      my $hour = $4;
      my $minutes = $5;

      use POSIX;
      $epoch = mktime (0, $minutes, $hour, $day, $month-1, $year-1900);   

   }else{
      $epoch = 0;
   }

   return $epoch;
}


1;

=head1 AUTHOR INFORMATION

   Author:  Marilyn
   Last Updated: 27/05/2008

=head1 BUGS

   Not known

=cut


