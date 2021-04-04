# Instructions for installing KH Coder on Fedora Linux

These instructions have been tested on Fedora 32. Install dependencies

```bash
sudo dnf -y groupinstall "Development Tools"
sudo dnf -y install mysql-devel perl-devel java-1.8.0-openjdk-devel R-devel perl-CPAN
```

Create a directory for KH Coder and go to it

```bash
mkdir khcoder
cd khcoder
```

Download [latest release of KH coder](https://github.com/ko-ichi-h/khcoder/releases/latest)
as well as [Stanford POS tagger](https://nlp.stanford.edu/software/tagger.shtml#Download)

```bash
wget https://nlp.stanford.edu/software/stanford-tagger-4.2.0.zip
unzip stanford-tagger-4.2.0.zip
wget https://github.com/ko-ichi-h/khcoder/archive/refs/tags/3.Beta.03.zip
unzip 3.Beta.03.zip
```

Install R depedencies, create the script below and save it as `InstallRDependencies.R`
in your folder
```Rscript
# Get R Dependenceis for KH Coder
# Modified from 
# https://vbaliga.github.io/verify-that-r-packages-are-installed-and-loaded/
# https://github.com/ko-ichi-h/khcoder/issues/91

packages = c("ade4","amap","Cairo","cluster","codetools",
             "colorspace","dichromat","foreign","ggdendro",
             "ggplot2","ggnetwork","ggsci","gtable","igraph",
             "KernSmooth","lattice","maptools","MASS",
             "Matrix","mgcv","munsell","nlme","nnet","permute",
             "pheatmap","plyr","proto","RColorBrewer","Rcpp",
             "reshape2","rgl","rpart","scales","scatterplot3d",
             "slam","som","sp","spatial","stringr","survival",
             "vegan","wordcloud")

package.check <- lapply(packages,
                        FUN = function(x) {
                                if (!require(x, character.only = TRUE)) {
                                        install.packages(x, 
                                                         dependencies = TRUE, 
                                                         repos = "https://cran.rstudio.com")
                                }
                        }
                        )

```

Run the script
```bash
Rscript InstallRDependencies.R
```

Install Perl depedencies, create the script below and save it as `InstallPerlDependencies.sh`
in your folder
```bash
!#/bin/bash

deps = ( "Jcode", "Tk","DBI","DBD::CSV","File::BOM",
         "Lingua::JA::Regular::Unicode","Net::Telnet",
         "Excel::Writer::XLSX","DBD::mysql",
         "Spreadsheet::ParseExcel::FmtJapan",
         "Spreadsheet::ParseXLSX",
         "Statistics::ChisqIndep",
         "Statistics::Lite","Unicode::Escape",
         "Algorithm::NaiveBayes",
         "Lingua::Sentence","Proc::Background")

for i in "${deps[@]}"
do
   cpan $i
done
```

Run the script
```bash
sudo bash InstallPerlDependencies.sh
```

Configure KH Coder

Configure KH Code (important):

```bash
    nano /config/coder.ini
```
- change java_path: <...>/bin/java.exe
- change stanf_jar_path: <...>/stanford-postagger.jar
- change stanf_tagger_path_en: <...>/models..tagger
 
Start KH Coder
```bash
perl ./kh_coder.pl
```
