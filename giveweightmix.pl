sub giveweightmix {

open file , "<./input/Mix.txt";#prepared by DFT file (need the specific format # can be used) 
@tempMix=<file>;
close file;
# remove beginning space and change line symbol
# you may also modify the follwoing to use the reference data you want
@array = map {my $temp=$_;$temp=~ s/^\s*//g;chomp($temp);$temp} @tempMix;
# skip the space line and the line with marker "#"
#we can use "#" in the file for comment
@refinput = grep (($_!~m/^\s*$/ && $_!~m/#/ && $_!~m/Failed/),@array);
#refdata  TiZr_Fine_000_d000	    -4.830787631" the format of an element of @refinput 

#foreach my $i (0..(@refinput-1)){
# print "used Mixdata $i $refinput[$i]\n";
#}

@carfiles = <./input/*.car>;

# used for data file manipulation by lammps
open mixin, "> ./output/mixindex.in"; 
print mixin "variable filename index "; 
foreach my $i (@refinput){
		
		@temp = split(/\s+/,$i);		
		@temp2 = grep (/$temp[1]/,@carfiles);  #match  
        if(!@temp2){die "No $temp[1].car file! You need to put it in the input folder\n"};
		print mixin " & \n$temp[1]".".data"; # need to watch the sequence in Crystal.txt
}
close mixin;

$tempnum = @refinput;
$newfile = "Mix"."W.txt";
unlink "./output/$newfile";
$mixweight = 5;
$mixweight_larger = $mixweight*4;

open ss,"> ./output/$newfile";
#print "$tempnum";
foreach $i (@refinput){
  @temp = split(/\s+/,$i);
  if($temp[2] <= 0) {
    print ss "$i"." $mixweight\n";
  }else{
    print ss "$i"." $mixweight_larger\n";#positive energy
  }
  
  
}
close ss;	
}
1;  
 
 
