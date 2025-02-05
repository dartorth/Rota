my $view=View->new();
$view->htmlOut();

package View;
use strict; use warnings;

our $VERSION=0.01;

sub new{
	my $class=shift;
	my %params=@_;
	my $self={};
	foreach (qw/showWeekend showOnCall showComments byWeek/){
		$self->{$_}=$params{$_}//1;
	}
	$self->{startDate}=$params{startDate}?new YMD($params{startDate}):new YMD();
	$self->{startDate}=$self->{startDate}->subDay($self->{startDate}->weekday()-1);
	$self->{outFile}=$params{outFile}//"./TestRota.html";
	bless $self,$class;
	return $self;
}

sub htmlOut{
	my ($self,$outFile)=@_;
	open my $fh,">",$outFile//$self->{outFile} or die "Can not save rota file";
	print $fh "<html><head><style>
td{text-align:center}
.am{background-color:lightblue; width:8em;}
.pm{background-color:lightpink; width:8em;}
.oc{background-color:lightyellow; width:16em;}
.comment{background-color:lightgreen; width:16em;}
</style></head><body><table border=1>\n";
	print $fh $self->title("domain","interval","users");
	print $fh $self->weekRow();
	print $fh $self->row($_,0) foreach (qw/aw bs dl am dg sa ic /);
	print $fh "</table></body></html>\n";
	close $fh;
}

sub title{
   my ($self,$domain,$interval,$users)=@_;
   return "  <tr>\n".
          "     <td class=title colspan=15>\n".
		  "       <span class=domain>$domain</span>\n".
		  "       <span class=interval>$interval</span>\n".
		  "       <span class=users>$users</span>\n".
		  "     </td>\n"

}

sub weekRow{
   my $self=shift;
   my $date=$self->{startDate};
   my $cols=4+($self->{showWeekend}?2:0);
   my $row="  <tr>\n    <td>&nbsp;</td>\n";
   foreach my $day (0..$cols){
      $row.="    <th class=weekday colspan=2>".
	        (qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/)[$day].
			($self->{byWeek}?("<br>\n".$date->addDay($day)->toStr("dmy")):"").
			"</th>\n";
   }
   $row.="  </tr>\n";
   
   return $row;
}

sub row{
   my ($self,$user,$weekOffset)=@_;
   my $weekStart=$self->{startDate}->addDay(7*$weekOffset);
   my $rowSpan=1+($self->{showComments}?1:0)+($self->{showOnCall}?1:0);
   my $rowHead="    <th rowspan=$rowSpan>".($self->{byWeek}?$user:$weekStart->toStr())."</th>";
   my @rows=( $self->{showOnCall}?$self->oncallRow($weekStart,$user):(),
              $self->dutyRow($weekStart,$user),
			  $self->{showComments}?$self->commentRow($weekStart,$user):());
   return "  <tr>\n$rowHead\n    ".join ("  </tr>\n  <tr>",@rows)."  </tr>"
}

sub oncallRow{
   my ($self,$date,$user)=@_;
   my $row="";
   $row.= "     <td class=oc  colspan=2>".
          $self->getValue($date->addDay($_),$user,"oc").
          "</td>\n" for (0..($self->{showWeekend}?6:4)) ;
   return $row;
}

sub dutyRow{
   my ($self,$date,$user)=@_;
   my $row="";
   $row.= "     <td class=am>".
          $self->getValue($date->addDay($_),$user,"am").
          "</td>\n    <td class=pm>".
          $self->getValue($date->addDay($_),$user,"pm").
          "</td>\n" for (0..($self->{showWeekend}?6:4)) ;
   return $row;
}

sub commentRow{
   my ($self,$date,$user)=@_;
   my $row="";
   $row.= "     <td class=comment  colspan=2>".
          $self->getValue($date->addDay($_),$user,"co").
          "</td>\n" for (0..($self->{showWeekend}?6:4)) ;
   return $row;
}

sub getValue{
  my ($self,$date,$user,$session)=@_;
  if ($session eq "oc"){return rand()>.9?"oc":"&nbsp;"}
  elsif ($session eq "am"){return ("Elective Clinic", "Fracture Clinic","Elective list","Trauma List","CPD")[5*rand()]}
  elsif ($session eq "pm"){return ("Elective Clinic", "Fracture Clinic","Elective list","Trauma List","CPD")[5*rand()]}
  elsif ($session eq "co"){return "ncr"}
  else {return "poop"};


}



package YMD;
############################################################################################
############################## Date Utilities Class  #######################################
############################################################################################
# This allows date calculations and calendar drawing
    our @wdn=(qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/);
    sub new{
        my ($class,$str,$m,$d, $H,$M,$S)=@_;
        my $self={};
        if (!$str){ # if nothing passed, then today
            (undef,undef,undef,$self->{d},$self->{m},$self->{y}) = localtime;
            $self->{y}+= 1900;
            $self->{m}++;
        }
        elsif (ref $str && $str->{y}){ #if a YMD passed, return a clone of it
            ($self->{y},$self->{m},$self->{d})=($str->{y},$str->{m},$str->{d})
        }
        elsif ($str=~/^\d{8}(T\d{6})?/){  # if a dateString Passed
			my $t=$1;
            ($self->{y},$self->{m},$self->{d})=($str=~/^(\d{4})(\d{2})(\d{2})/);
            if ($t){
				($self->{H},$self->{M},$self->{S})=($t=~/(\d{2})(\d{2})(\d{2})/);
			}
        }
        else {  # if passed with y,m,d 
            ($self->{y},$self->{m},$self->{d})=($str,$m,$d);
        }
        bless $self,$class;
        return $self;
    }
    
    sub today{
        return new ("YMD")
    }
    
    sub toStr{
        my ($self,$format)=@_;
        if ($format){
            return $self->{d}."/".$self->{m}."/".$self->{y} if ($format =~/dmy/);
            return $self->{m}."/".$self->{d}."/".$self->{y} if ($format =~/mdy/);
        }
        return sprintf ("%04d",$self->{y}).sprintf ("%02d",$self->{m}).sprintf ("%02d",$self->{d})
    }

    sub leapYear{
        my $self=shift;
        my $y=ref $self?$self->{y}:$self;
        return (($y%4) - ($y%100) + ($y%400))?0:1;
    }
    

# day 1 of year Gregorian Guassian Method ( https://en.wikipedia.org/wiki/Determination_of_the_day_of_the_week
    sub d1greg{
        my $self=shift;
        return (1+5*(($self->{y}-1)%4)+4*(($self->{y}-1)%100)+6*(($self->{y}-1)%400))%7;
    }
    
# calculate which day of the year a date falls in    
    sub dayOfYear{
        my $self=shift;
        return $self->{d}+                             # which day
               (0,31,59,90,120,151,181,212,243,273,304,334)[$self->{m}-1]+ # which month
               ((leapYear($self->{y})&&($self->{m}>2))?1:0); # leap year compensation
    }
    
# calculate which week of the year a date falls in  
    sub weekOfYear{
        my $self=shift;
        return int((dayOfYear($self)+6)/7);
    }

# calculate which day of the week a date falls in  0..6 with 0 being Sunday    
    sub weekday{
        my $self=shift;
        return (dayOfYear($self)+d1greg($self)-1)%7;
    }
# calculate which day first day of month is    
    sub monthFirstDay{
        my $self=shift;
        return weekday(YMD->new($self->{y},$self->{m},1));
    }
    
# return the number of days in the month (month is 1..12   
    sub daysInMonth{
        my $self=shift;
        return (($self->{m}==2)&&leapYear($self->{y}))?29:(31,28,31,30,31,30,31,31,30,31,30,31)[$self->{m}-1];
    }

# return the name of the day
    sub dayName{
        my $self=shift;
        return (qw/Monday Tuesday Wednesday Thursday Friday Saturday Sunday/)[weekday($self)-1]
    }
    
# set the date to a certain date ... return undef if not valid
    sub setDate{
        my ($self,$date)=@_;
        my $tmp=new YMD($self);
        return undef if $tmp->daysInMonth()<$date;
        $tmp->{d}=$date;
        return $tmp;
    }

# return name of month
    sub monthName{
        my $self=shift;
        return (qw/January February March April May June July August September October November December/)[$self->{m}-1]
    }
     
    sub addDay{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{d}+=$days//1;
        while ($tmp->{d}>daysInMonth($tmp)){
            $tmp->{d}-=(daysInMonth($tmp));
            $tmp->{m}++;
            if ($tmp->{m}>12){
                $tmp->{y}++;
                $tmp->{m}=1;
                }
        };
        return $tmp
    }
    sub subDay{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{d}-=$days//1;
        while ($tmp->{d}<1){
            $tmp->{m}--;
            $tmp->{d}+=daysInMonth($tmp);
            if ($tmp->{m}<1){
                $tmp->{y}--;
                $tmp->{m}=12;
                }
        };
        return $tmp
    }
    sub addMonth{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{m}+=($_[1]//1);
        while ($tmp->{m}>12){
            $tmp->{y}++;
            $tmp->{m}-=12;
        }
        $tmp->{d}=$tmp->{d}<daysInMonth($tmp)?$tmp->{d}:daysInMonth($tmp);
        return $tmp;
    }
    sub subMonth{
        my ($self,$days)=@_;
        my $tmp=new("YMD",$self);
        $tmp->{m}-=($_[1]//1);
        while ($tmp->{m}<1){
            $tmp->{y}--;
            $tmp->{m}+=12;
        }
        $tmp->{d}=$tmp->{d}<daysInMonth($tmp)?$tmp->{d}:daysInMonth($tmp);
        return $tmp;
    }
    
   # get the next date with dayname e.g the next("sunday"), next("TU"), next(2);
    sub next{  
        my ($self,$day)=@_;
        if ($day=~/^(SU|MO|TU|WE|TH|FR|SA)/i){
			$day={su=>0,mo=>1,tu=>2,we=>3,th=>4,fr=>5,sa=>6}->{lc $1}
		}
		return undef unless($day>=0 && $day<7);
        my $tmp=new("YMD",$self);
        my $tDay=weekday($tmp);
		$tmp=$tmp->addDay($day-$tDay+($day<=$tDay?7:0));
		return $tmp;
	}
	
	sub dayListInMonth{ # list of days in a month with a certain date
        my ($self,$day)=@_;
		my $list=[];
        my $tmp=new("YMD",$self);
        my $month=$tmp->{m};
        $tmp->{d}=1;   
        $tmp=$tmp->subDay(1);  
           
        while(1){
			$tmp=$tmp->next($day);
			next if $tmp->{m}<$month;
			last if $tmp->{m}>$month;
			$list=[@$list,$tmp->toStr()],
		}
		return $list;  
	}
	sub nDayInMonth{
        my ($self,$nDay)=@_;
        my($n,$day);
        if ($nDay=~/^(-?\d+)?(su|mo|tu|we|th|fr|sa)/i){
			($n,$day)=($1,$2);
		}
		my $list=$self->dayListInMonth($day);
		return $n?[$list->[$n]]:$list;   
	}
	
	sub inList{
        my ($self,@list)=@_;
        die caller unless $self;
        my $strDate=ref $self?$self->toStr():substr($self,0,8); 
        @list=map{$_?substr($_,0,8):()} map{$_?split ",":() } @list;
        foreach (@list){
			return 1 if $strDate eq $_
		}
        return 0;
	}
	
	# compares two dates, or a another date to itself;
    sub cmp{
        my ($self,$date1,$date2)=@_;
		($date1,$date2)=$date2?(new ("YMD",$date1),new ("YMD",$date2)):(new ("YMD",$self),new ("YMD",$date1));
        return 1  if ($date1->{y}>$date2->{y});
        return -1 if ($date1->{y}<$date2->{y});
        return 1  if ($date1->{m}>$date2->{m});
        return -1 if ($date1->{m}<$date2->{m});
        return 1 if ($date1->{d}>$date2->{d});
        return -1 if ($date1->{d}<$date2->{d});    
        return 0;    
    }
    
    # takes a date in YMD, 8 digit string or y,m,d forms
    #returns a grid of hashes for displaying
    sub monthGrid{ 
        my $date=YMD->new(@_);
        my $preBlanks=($date->monthFirstDay()+6)%7;          # blank days in grid
        my @cells=(("")x$preBlanks,1..$date->daysInMonth()); # dates of month
        push @cells,"" while (@cells%7);                     # full 7 column grid
        # return grid of hashes containing date labels and datestrings (both empty strings if cell is empty)
        @cells=map{{label=>$_,date=>$_?YMD->new($date->{y},$date->{m},$_)->toStr():"",}}@cells;                       # cell contents as hash
        my $grid=[];
        foreach my $row(0..@cells/7-1){
            $grid->[$row]=[@cells[$row*7..$row*7+6]];
        }
        return $grid;                          
    }
    
