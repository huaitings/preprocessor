Prepared by Prof. Shin-Pon Ju at UCLA on Feb 7 2019.

## main Script: fitting_preprocessor.pl

#subroutine
require './car2data.pl'; # convert all car files (in input folder, 
         even though # is used to mark some skipped mix structurs in Mix.txt) to data files 
require './giveweight.pl';
require './giveweightmix.pl';
lmp_rc_mix.in --> could be merged into car2data in the future

#########################################
The files you need to put in the "input" folder:

1. Alloy_Summary.csv: the data from DFT 
** for setting Ec, Re, and deriving alpha (From bulk module and Vol) 

2. Crystal.txt: all reference data for crystal
** the thrid column is the reference data (from DFT)

3. Mix.txt: all other data
**the thrid column is the reference data (from DFT)
** the second column is the file name for all mix reference structure (both car and data)
 
4. all car files you want to use 
** the files will be converted to data files by the file names in the second column of Mix.txt 

5. known parameter file: for MEAM (crosselement_part1.meam), single element parameters like Cmax, Cmin....

Output files
1.crystalindex.in (built according to @crystalfiles in fitting_preprocessor.pl)** should be modified
** the crystal data files you want to manipuate in sequence by lammps 

2.mixindex.in (built according to Mix.txt in the input folder)** should be modified
** the mix data files you want to manipuate in sequence by lammps
** through giveweightmix.pl