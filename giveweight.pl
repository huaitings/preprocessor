 #@alloytemp= split(/,/,$alloy[$readlinenum]);
 
 #system("copy output.dt $lmpout");
sub giveweight {

 my $press_weight = 1e-9;# pressure or stress 
 my $bulk_weight = 0.001;# pressure or stress 
 my $elastic_weight = 0.01;# elastic constant
 my $boxlen_weight = 1e5;# box length
 my $boxang_weight = 1e5;# box angle
 my $deform_weight = 20;# maximum for the optimized crystal cell (-5 to 5 index from MS output)
 # tensile and compressive Energy
 my $mdsetting_weight = 10; # result from MD stability
  
#my($tempfile)=@_;#data transferred from the main script
my @ref_crystal=<file>;
open file , "<./input/Crystal.txt";# original reference data for crystal
@ref_crystal=<file>;
close file; 

my @array = map {my $temp=$_;$temp=~ s/^\s*//g;chomp($temp);$temp} @ref_crystal;
#remove the space line and the line with marker "#"
#we can use "#" in the file for comment
my @refinput = grep (($_!~m/^\s*$/ && $_!~m/#/ && $_!~m/Failed/),@array);# we can use "#" in the file for comment
 
$tempnum = @refinput;
open ss,"> ./output/CrystalW.txt";

### give the weighting values according to different conditions 
foreach my $i (0..(@refinput-1)){
  #print "i: $i $refinput[$i]\n";
#//: match operator (or m//),
#. indicates any one,+ for one or more,\b: boundary
#\D: any letter instead of a number,\d: any number
#//i: not case-sensitive,{2,4} (2 to 4 times),{2} only 2 times

  if($refinput[$i] =~ m/bulk/i){ #bulk
     print "***bulk matched, $i $refinput[$i]\n";
	 print ss "$refinput[$i]"." $bulk_weight\n";
	}
 if($refinput[$i] =~ m/\bp\D{2}\b/i){ #pxx, pyy,pzz (stress)...
     print "***press (stress) matched, $i $refinput[$i]\n";
	 print ss "$refinput[$i]"." $press_weight\n";
	}
  elsif($refinput[$i] =~ m/\bc\d{2}\b/i){ # c11, c12 (elastic constants)..
     print "***elastic constant matched, $i $refinput[$i]\n";
	 print ss "$refinput[$i]"." $elastic_weight\n";
	
	}
  elsif($refinput[$i] =~ m/\bl\D\b/i){ #lx, ly, lz (box length)
     print "***matched box length $i $refinput[$i]\n";
     print ss "$refinput[$i]"." $boxlen_weight\n";
	}  
  elsif($refinput[$i] =~ m/\bcell\D{4,6}\b/i){#cellalpha, cellbeta, cellgamma (box angles)
     print "***cell angle matched, $i $refinput[$i]\n";
     print ss "$refinput[$i]"." $boxang_weight\n";
	}
  elsif($refinput[$i] =~ m/\bmd.+\b/i){#MD reference data 
     print "***mdsetting matched, $i $refinput[$i]\n";
     print ss "$refinput[$i]"." $mdsetting_weight\n";
	}
  elsif( $refinput[$i] !~ m/refdata/i){
     print "***else property matched (mainly for tensile and compressive cell energy), $i $refinput[$i]\n";
     #print "$refinput[$i]\n";
	 my @temp = split(/\s+/,$refinput[$i]);
	 my $deform  = $deform_weight/exp(abs($temp[1]));
	 print ss "$refinput[$i]"." $deform\n";    
	}
}

close ss;
}
1;  
 
 
