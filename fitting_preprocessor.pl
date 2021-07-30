=begin
This perl script can be used to generate all required data and files for MEAM fitting process
developed by Prof. Shin-Pon Ju at NSYSU 2016/06/23

#########
It should be noted that once the alloy binding energy is stronger than the average binding energy of single elements,
the Cmax of atom pair of the same atom with the stronger binding energy should be smaller than 1.4 for stability   
##########
Required files from DFT:
1. Alloy_Summary.Alloy_Summary ## may modified this to be txt format
2. 2016/10/05: make alpha, Re, Ec of ally to be fitted.
3. lmp_rc_mix.in is used to make supercell with the box length larger than 2 times cutoff
input:Alloy_Summary
=cut 

system ('rmdir /s/q output');# remove old dir
system ('mkdir output');# create output dir

require './car2data.pl';
## collect all car files and then make all optimized car files to data files
require './giveweight.pl';
# give weighting for crystal files
require './giveweightmix.pl';
# give weighting for mixing files

###### geometry scale (used when the DFT optimized geometry is slightly different than 
# the experimental cell. If not, scale.in is useless.
unlink ">scale.in";
open scale , ">scale.in";
print scale "variable latticedft equal 4.5765\n";
print scale "variable latticeexp equal 4.4570\n";
print scale 'variable latticescale equal ${latticeexp}/${latticedft}';
print scale "\n";
print scale 'change_box all x scale ${latticescale} y scale ${latticescale} z scale ${latticescale} remap units box';  
close scale;
##############
#@crystalfiles = ("TiZr"); ## You need to follow the sequence in your Crystal.txt


@lattice =("b2"); #All lattice types considered in this fitting procedure.
$elastic = "Yes"; ## consider elastic constants or not (arrange related elastic constants from csv files)
# L1213 means L12 lattice type with one first element and three second one 
$printformat ="%12.3f"; ##for fitting parameter format
@atompair1 = ("Al","Mo","Nb","Ta","Ti","Zr");                     
#@atompair1 = ("Zr","Mo");
@atompair2 = @atompair1;
$pair1num =@atompair1;
$pair2num =$pair1num;

for (my $i=1; $i<=$pair1num ;$i++)
	{
	$r = $i-1;
	$element{$atompair1[$r]} = $i;# convert element symbol in car file to lammps type
	# seems a little strange, used for lammps type? 
	#$element {"sym"} = integer
#	print "$element{$atompair2[$r]}\n";
}

open alloy , "<./input/00crystal_refdata.txt";
@alloy ="";
@alloy=<alloy>;  #read data from alloy line by line to an array
close alloy;

### You need to pay attention to the sequence of data. The order is the same as in Dmol3
# the following files can be used to check the details even though they are not used for PSO directly.
open part2 , ">./output/crosselement_part2.meam";# Ec, alpha...
printf part2 "\n";
printf part2 "#####***The following data is used to fitted from the minor modification of Dmol3 data***######\n\n";

open part3 , ">./output/crosselement_part3.meam";# Cmax, Cmin....
printf part3 "\n";
printf part3 "#####***The following data is used to be fitted by randomly generating values within ranges***######\n\n";

##-- making the upper and lower bounds for PSO
open PSOmax,">./output/PSOmax.dat";# upper bound of PSO parameters
open PSOmin,">./output/PSOmin.dat";# lower bound of PSO parameters

open PSOmaxdmol,">./output/PSOmaxdmol.dat";#?
open PSOmindmol,">./output/PSOmindmol.dat";#?

##Ec, Re, alpha are the change percentage and the other are the real upper and lower bounds 
%paramax =(
      Ec => 0.01, 
      Re =>0.01,											#shortest range shouldn't be change
      alpha => 0.05,
      rho0 => 1.2,
      attract => 0.1,
      repuls => 0.1,
      Cmin => 2.0,
      Cmax => 2.8    
      );
      
%paramin =(
      Ec => 0.01,
      Re =>0.01,											#shortest range shouldn't be change
      alpha => 0.05,
      rho0 => 0.8,
      attract => -0.1,									
      repuls => -0.1,
      Cmin => 0.01,
      Cmax => 1.0     
      );      
########################      

$readlinenum = 0;
##$tempsub
&car2data($pair1num,\%element);# $pair1num: atomtype #
$tempsub="Crystal";
&giveweight();# filter by #

########## create a index for LAMMPS crystal for manipulating all other data files
unlink "> ./output/crystalindex.in";
open cryin, "> ./output/crystalindex.in";
print cryin "variable filename index";
#@Finedata = <./output/*_Fine.data>	;
#@cryfile = ("BCC","FCC");
#foreach (@crystalfiles){
		#print cryin " & \n$_"."_Fine.data"; # need to watch the sequence in Crystal.txt
#}
#close(cryin);
for ($ipair1 =0; $ipair1 <$pair1num ; $ipair1++) {
	   $lmpt1 = $element{$atompair1[$ipair1]};
	    if($ipair1 == 0){
	           printf part3 "rho0(%d)= 1\n\n",$lmpt1;	## set the rho of the first atom type is 1. This parameter is just a relative value.
	    }
   for ($ipair2 =0; $ipair2 <$pair2num ; $ipair2++) {
      
     $eval = $ipair1-$ipair2; # MS perl needs to use this format. I don't know the reason so far.
         
     if($eval < 0.0) { # not consider the same pair with different atom sequence (C-Ta or Ta-C should be used for only one)
	 
      $filename = "$atompair1[$ipair1]"."$atompair2[$ipair2]";
      $crytempfile = "$filename"."_Fine";
			print cryin" & \n$crytempfile.data";
      $readlinenum = $readlinenum+1;
      
      $lmpt2 = $element{$atompair1[$ipair2]};
       
      @alloytemp= split(/,/,$alloy[$readlinenum]);# csv file
      
####### get the lammps data files and reference data with weight (elastic constants, pxx, and binding energies)
      print "#### Atom pair : $filename\n\n";
            
##### Making Header of each pair
        print part2 "## For $filename, lammps types: $lmpt1,$lmpt2\n\n";
        
##### Making trivial things for lammps MEAM alloy
        print part2 "nn2($lmpt1,$lmpt2)= 1\n";
        print part2 "zbl($lmpt1,$lmpt2)= 0\n";
        print part2 "lattce($lmpt1,$lmpt2)= 'b2'\n";

##### Making Ec(I,J) 
        $tempEc = -$alloytemp[1]; ## lammps needs the positive value for the binding energy, Ec(I,J) 
        #printf part2 "Ec(%d,%d)= %s\n",$lmpt1,$lmpt2,$tempEc;
        printf part2 "Ec(%d,%d)= %s\n",$lmpt1,$lmpt2,$printformat;
        $tempmax = $tempEc*(1+$paramax{Ec});
        $tempmin = $tempEc*(1-$paramin{Ec});
        print PSOmaxdmol "$tempmax\n";
        print PSOmindmol "$tempmin\n";
##### Making re(I,J)
				$tempRe = $alloytemp[4];
				#printf part2 "re(%d,%d)= %s\n",$lmpt1,$lmpt2,$tempRe;
        printf part2 "re(%d,%d)= %s\n",$lmpt1,$lmpt2,$printformat;
        $tempmax = $tempRe*(1+$paramax{Re});
        $tempmin = $tempRe*(1-$paramin{Re});
        print PSOmaxdmol "$tempmax\n";
        print PSOmindmol "$tempmin\n";
        

##### Making alpha

        $vol = $alloytemp[3]; ##A**3 , Volume from dmol3 has been normalized by the atom number
        $vol=$vol*1e-30; #--> m**3

        $B= $alloytemp[2]; # GPa from Dmol3
        $B=$B*1e9;#GPa -> Pa(the same as N/m**2)
 
        $Ec = $alloytemp[1];# eV, Binding energy from dmol3 has been normalized by the atom number
        $Ec = $Ec*1.6021773e-19;#Joule
        #print "$vol, $B, $Ec \n";
        $alpha = (-9*$B*$vol/$Ec)**0.5; #Ec is negative, so we have to make it positive for square root by -9
        printf part2 "alpha(%d,%d)= %s\n",$lmpt1,$lmpt2,$printformat;
       
        $tempmax = $alpha*(1+$paramax{alpha});
        $tempmin = $alpha*(1-$paramin{alpha});
        print PSOmaxdmol "$tempmax\n";
        print PSOmindmol "$tempmin\n";
        
        printf part2 "\n";
#############################################################################################
##--- making parameters to be fitted -- lammps default values are used first.
        print part3 "##For $filename, Lammps types: $lmpt1,$lmpt2\n\n";        
        printf part3 "attrac(%d,%d)= %s\n",$lmpt1,$lmpt2,$printformat;
        
        print PSOmax "$paramax{attract}\n";
        print PSOmin "$paramin{attract}\n";
        
        printf part3 "repuls(%d,%d)= %s\n",$lmpt1,$lmpt2,$printformat;
        
        print PSOmax "$paramax{repuls}\n";
        print PSOmin "$paramin{repuls}\n";
        
           for ($ipair3 =0; $ipair3 <$pair1num ; $ipair3++) {
           	 $lmpt3 = $element{$atompair1[$ipair3]};
           	 printf part3 "Cmin(%d,%d,%d)= %s\n",$lmpt1,$lmpt2,$lmpt3,$printformat;
           	 
           	 print PSOmax "$paramax{Cmin}\n";
             print PSOmin "$paramin{Cmin}\n"; 
           	 
           	 printf part3 "Cmax(%d,%d,%d)= %s\n",$lmpt1,$lmpt2,$lmpt3,$printformat;
           	 
           	 print PSOmax "$paramax{Cmax}\n";
             print PSOmin "$paramin{Cmax}\n";           	 
           	           	 
           }
           
       } ## pair loop by "if" (skip the same pair but with different atom sequence
       
    } #for loop before if
    
######################### make Cmax and Cmin for the same first two ID
         for ($ipair4 =0; $ipair4 <$pair1num ; $ipair4++) {
           	 $lmpt4 = $element{$atompair1[$ipair4]};
           	 if($lmpt1 != $lmpt4){
           	    printf part3 "Cmin(%d,%d,%d)= %s\n",$lmpt1,$lmpt1,$lmpt4,$printformat;
           	 
           	    print PSOmax "$paramax{Cmin}\n";
                print PSOmin "$paramin{Cmin}\n";
           	 
           	    printf part3 "Cmax(%d,%d,%d)= %s\n",$lmpt1,$lmpt1,$lmpt4,$printformat;
           	 
           	    print PSOmax "$paramax{Cmax}\n";
                print PSOmin "$paramin{Cmax}\n";           	 
           	}         	 
           }
           
	         if($ipair1 != 0){
	           printf part3 "rho0(%d)= %s\n",$lmpt1,$printformat; #rho0 is significant for alloy instead of single element
             print PSOmax "$paramax{rho0}\n";
             print PSOmin "$paramin{rho0}\n";
           } #arrange rho, the rho value of the first element in the array is set to 1

########################    
   
}# element loop (pick element one by one in the array
print part3 "\n";
close part2;
close part3;
close PSOmax;
close PSOmin;
close PSOmaxdmol;
close PSOmindmol;


#######################
#### merge PSOmax (PSOmin) and PSOmaxdmol (PSOmindmol)files to be one
open part1 , "< ./output/PSOmaxdmol.dat";
open part2 , "< ./output/PSOmax.dat";
open part3 , "< ./output/PSOmindmol.dat";
open part4 , "< ./output/PSOmin.dat";

$allpart1 = "";
$allpart2 = "";
$allpart3 = "";
$allpart4 = "";

#open ss,"<grade_sheet.txt";
while($_=<part1>){$allpart1.=$_;}
while($_=<part2>){$allpart2.=$_;}
while($_=<part3>){$allpart3.=$_;}
while($_=<part4>){$allpart4.=$_;}

close part1;
close part2;
close part3;
close part4;

open PSOmax , "> ./output/ALLPSOmax.dat";
print PSOmax "$allpart1";
print PSOmax "$allpart2\n\n";
close PSOmax;

open PSOmin , "> ./output/ALLPSOmin.dat";
print PSOmin "$allpart3";
print PSOmin "$allpart4\n\n";
close PSOmin;


#######################
#### merge the MEAM files to be one
open part1 , "<./input/crosselement_part1.meam";# known parameters
open part2 , "<./output/crosselement_part2.meam";
open part3 , "<./output/crosselement_part3.meam";

$allpart1 = "";
$allpart2 = "";
$allpart3 = "";

#open ss,"<grade_sheet.txt";
while($_=<part1>){$allpart1.=$_;}
while($_=<part2>){$allpart2.=$_;}
while($_=<part3>){$allpart3.=$_;}

close part1;
close part2;
close part3;

$tempfile= "";
for ($ipair1 =0; $ipair1 <$pair1num ; $ipair1++) 
  {
	  $tempfile = "$tempfile"."$atompair1[$ipair1]";	
  }

open MEAM , "> ./output/Template.meam";
print MEAM "$allpart1\n\n";
print MEAM "$allpart2\n\n";
print MEAM "$allpart3";
close MEAM;

###-----------The following is for mixing system..### no completely built (use loop for each pair undone)
&giveweightmix;
### The following is to check whether the box size is larger than 2 times rcut
unlink ">./output/allrefdata.in";
open data , ">./output/allrefdata.in"; # manipulate data files by lammps
#<./input/*.car>
@allfiles = glob "./output/*.data";

print data "variable filename index  ";
 print @allfiles;
foreach my $data (@allfiles){
$dataname = $data;
$dataname =~ s/\.\/output\///g;# remove ./output/ and leave the XX.data
print data "&  \n$dataname ";
}

close data;

system ('rmdir /s/q modified_datafiles');# remove old dir
system ('mkdir modified_datafiles');# create output dir

########## to redifine box size ##########
$tempa=system ('lmp_serial  -sc none -in lmp_rc_eval.in');
