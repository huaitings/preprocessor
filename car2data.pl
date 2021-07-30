sub car2data{
use Math::Trig; qw/pi deg2rad rad2deg/;	
#use strict;  
#use warnings;
my ($alltype,$href_element)=@_;
my @datafiles = <./input/*.car>; # ./input/all car files in input folder
#print @datafiles;
#@datafiles = glob "/input/*.car";
foreach $tempfile (@datafiles)
{
open file , "<$tempfile";	#open.car in the "input"($tempfile= "./input/XX.car")
@car=();
@car=<file>;
close file;
my @coord1 = grep {if(m/(\w+\d+\s+\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+\s+XXXX\s+\d+\s+xx\s+\w+\s+\d+\.\d+)/){$_ = "$1\n";}} @car;
#print @coord1;
#my @car=grep (($_!~m{^\s*$|^#}),@car00); # remove blank lines
$atom_num  = @coord1;
print "$atom_num\n";
#$atom_num = $car_line_num - 7; ##5 head lines and two end lines are not counted 
#print "$tempfile"." $atom_num\n";
$dataname = $tempfile;
$dataname =~ s/\.|\/input\/|car//g;# remove all "." first, / is a special symbol,use \
$filename = "$dataname".".data";

open data,">./output/$filename";			#export .data

print data "#LAMMPS inputdata file for 2 metal structure\n\n";
print data "$atom_num	atoms\n"; ##all atom types we consider
print data "$alltype  atom types\n\n"; ####could be modifed by a filter ##########################

### The first four lines of a car file shown below are useless for data file.

#!BIOSYM archive 3
#PBC=ON
#Materials Studio Generated CAR File
#!DATE Thu Jun 16 23:49:00 2016

#PBC    5.7899    5.7899    5.7899   90.0000   90.0000   90.0000 (P1)
@pbcbox=split(/\s+/,$car[4]); # the fifth row of a car file

$a = $pbcbox[1];
$b = $pbcbox[2];
$c = $pbcbox[3];
$alpha = deg2rad($pbcbox[4]);
$beta = deg2rad($pbcbox[5]);
$gamma = deg2rad($pbcbox[6]);

$lx = $a;
$xy = $b*cos($gamma);
$xz = $c*cos($beta);
$ly = sqrt($b**2 - $xy**2);
$yz = ($b*$c*cos($alpha)-$xy*$xz)/$ly;
$lz = sqrt($c**2 - $xz**2 - $yz**2);

print data "0.0 $lx xlo xhi\n";
print data "0.0	$ly ylo yhi\n";
print data "0.0	$lz zlo zhi\n";
print data "$xy	$xz	$yz	xy xz yz\n\n";
print data "Atoms\n\n";

for (my $i=0;$i<$atom_num;$i++)					
  {
    @coord = "";	
    @coord=split(/\s+/,$coord1[$i]);
   #if(m/\w+\d+\s+\d+\.\d+\s+\d+\.\d+\s+\d+\.\d+\s+XXXX\s+\d+\s+xx\s+\w+\s+\d+\.\d+/g)
   #{
   #  push @
   #}
    #print @coord;
    $counter = $i + 1;
   	$lmpID = $href_element->{$coord[7]};
    print data "$counter $lmpID $coord[1] $coord[2] $coord[3]\n";	
  }

}
}				#every car file
1;