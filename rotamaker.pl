#!/usr/env perl
use strict; use warnings;

my $date=200;
my @users=(qw/aw bs dl am dg sa ic /);
my $showUser=1;
my $showWeekend=1;
my $showOnCall=1;
my $showComments=1;

print table(
          title("domain","interval","users"),
		  weekRow($date,1,1),
		  map {row($date,$_,1,1,1,1,1)}(qw/aw bs dl am dg sa ic /)
		  );


sub title{
   my ($domain,$interval,$users)=@_;
   return "  <tr>\n".
          "     <td class=title>\n".
		  "       <span class=domain>$domain</span>\n".
		  "       <span class=interval>$interval</span>\n".
		  "       <span class=users>$users</span>\n".
		  "     <\td>\n"

}

sub weekStart{

}

sub weekRow{
   my ($date,$showDate,$showWeekend)=@_;
   $date=weekStart($date);
   my $cols=4+$showWeekend?2:0;
   my $row="  <tr>\n    <td>&nbsp;</td>\n";
   foreach my $day (0..$cols){
      $row.="    <th class=weekday>".
	        (qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/)[$day].
			($showDate?("<br>\n".toDateStr($date+$day)):"").
			"</th>\n";
   }
   $row.="  </tr>\n";
   
   return $row;
}

sub row{
   my ($date,$user,$showUser,$showDate,$showWeekend,$showOnCall,$showComments)=@_;
   my $rowSpan=1+($showWeekend?1:0)+($showOnCall?1:0);
   my $rowHead="    <th rowspan=$rowSpan>".($showUser?"$user<br>":"").($showDate?toDateStr($date):"")."<\th>";
   my @rows=( $showOnCall?oncallRow($date,$user,$showWeekend):(),
              dutyRows($date,$user,$showWeekend),
			  $showComments?commentRow($date,$user,$showWeekend):());
   return "  <tr>\n$rowHead\n    ".join ("  <\tr>,  <tr>",@rows)."  <\tr>"
}

sub oncallRow{
   my ($date,$user,$showWeekend)=@_;

}

sub dutyRow{
   my ($date,$user,$showWeekend)=@_;
}

sub commentRow{
   my ($date,$user,$showWeekend)=@_;

}

sub table{
    my $table="<table>\n";
	$table.= $_ foreach @_;
	$table.="<\table>\n";
	return $table;

}



sub  toDateStr{
   return "dd/mm/yyyy/"
}