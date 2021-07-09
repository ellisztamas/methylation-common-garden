#!/usr/bin/perl

# Perl script from Eriko Sasaki to calculate methylation levels in
# CG, CHG and CHH sequence contexts.
#
# This writes a .tsv.gz file listing each annotated TE, with columns for
# the number of methylated and total reads in the CG, CHH and CHG
# contexts.
#
# I modified the script to take filenames of the format
# `allc_sequencetags.tsv.gz`
# where the original required only
# `sequence_tags`

use strict;
use warnings;

my $DatDir=$ARGV[0];
my $Info_full=$ARGV[1];
my $OutDir=$ARGV[2];
my $Fname=$ARGV[3];

my @FList;
opendir(DH, $DatDir) || die;
    while(my $v=readdir(DH)){
        if($v=~/^$Fname$/){
            push(@FList, $v);
        }
    }
closedir(DH);

my %CG;
my %CHG;
my %CHH;
my %tCG;
my %tCHG;
my %tCHH;
foreach(@FList){
    my $fname="$DatDir\/$_";
    open(IN, "gzip -dc $fname | ") || die;
        while(my $Red=<IN>){
            $Red=~s/\n//;
            my @Ary=split(/\t/, $Red);
            my $Dep=$Ary[5];
            if($Ary[0]=~/^Chr([1-5])/){
                my $Chr=$1;
                
                    if($Ary[3]=~/^CG[ATGC]$/){
                        $CG{"$Chr\_$Ary[1]"}=$Ary[4];
                        $tCG{"$Chr\_$Ary[1]"}=$Ary[5];
                    }elsif($Ary[3]=~/^C[ATC]G$/){
                        $CHG{"$Chr\_$Ary[1]"}=$Ary[4];
                        $tCHG{"$Chr\_$Ary[1]"}=$Ary[5];
                    }elsif($Ary[3]=~/^C[ATC][ATC]$/){
                        $CHH{"$Chr\_$Ary[1]"}=$Ary[4];
                        $tCHH{"$Chr\_$Ary[1]"}=$Ary[5];
                    }
            }
        }
    close(IN);
}


open(OUT, "> $OutDir/$Fname") || die;
    print OUT "Locus\tmCG\tmCHG\tmCHH\tcCG\tcCHG\tcCHH\n";
    open(IN, $Info_full) || die;
    
        while(my $Red=<IN>){
            $Red=~s/\n//;
            my @Ary=split(/\t/, $Red);
            if($Ary[0]=~/AT([1-5]).*/){
                my $Chr=$1;
                 
                    my $Start=$Ary[1];
                    my $End=$Ary[2];
                    my $i=$Start;
                    
                    my $mCG=0;
                    my $cCG=0;
                    my $mCHG=0;
                    my $cCHG=0;
                    my $mCHH=0;
                    my $cCHH=0;

                    while($i<$End){
                            my $Loc="$Chr\_$i";
                            if(exists($CG{$Loc})){
                                $mCG=$mCG+$CG{$Loc};
                                $cCG=$cCG+$tCG{$Loc};
                            }
                            
                            if(exists($CHG{$Loc})){
                                $mCHG=$mCHG+$CHG{$Loc};
                                $cCHG=$cCHG+$tCHG{$Loc};
                            }
                            
                            if(exists($CHH{$Loc})){
                                $mCHH=$mCHH+$CHH{$Loc};
                                $cCHH=$cCHH+$tCHH{$Loc};
                            }
                        $i++;
                    }
                
                print OUT "$Ary[0]\t$mCG\t$mCHG\t$mCHH\t$cCG\t$cCHG\t$cCHH\n";
            }   
        }
    close(IN);
close(OUT);

