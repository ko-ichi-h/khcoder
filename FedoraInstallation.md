# Instructions for installing KH Coder on Fedora Linux

These instructions have been tested on Fedora 32. Install dependencies

```bash
$ sudo dnf -y groupinstall "Development Tools"
$ sudo dnf -y install mysql-devel perl-devel java-1.8.0-openjdk-devel R-devel perl-CPAN
```

Create a directory for KH Coder and go to it

```bash
$ mkdir khcoder
$ cd khcoder
```

Download [latest release of KH coder](https://github.com/ko-ichi-h/khcoder/releases/latest)
as well as [Stanford POS tagger](https://nlp.stanford.edu/software/tagger.shtml#Download)

```bash
$ wget https://nlp.stanford.edu/software/stanford-tagger-4.2.0.zip
$ unzip stanford-tagger-4.2.0.zip
$ wget https://github.com/ko-ichi-h/khcoder/archive/refs/tags/3.Beta.03.zip
$ unzip 3.Beta.03.zip
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
$ Rscript InstallRDependencies.R
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
$ sudo bash InstallPerlDependencies.sh
```

Now setup database. MariaDB can replace Mysql, but needs to be
configured. Information is adapted from the 
[Fedora Mariadb wiki](https://fedoraproject.org/wiki/MariaDB)

```bash
$ sudo systemctl enable mariadb
$ sudo systemctl start mariadb
$ mysql_secure_installation

Set root password? [Y/n] y
Remove anonymous users? [Y/n] y
Disallow root login remotely? [Y/n] y
Remove test database and access to it? [Y/n] y
Reload privilege tables now? [Y/n] y

$ mysql -uroot -p
Enter password: 
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 26
Server version: 10.4.18-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> CREATE USER 'khcoder'@'localhost' IDENTIFIED BY 'SecurePassword';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> GRANT ALL ON *.* TO 'khcoder'@'localhost';
Query OK, 0 rows affected (0.00 sec)

MariaDB [(none)]> exit
Bye

```
Configure KH Coder

```bash
    nano /config/coder.ini
```
- change java_path: <...>/bin/java.exe
- change stanf_jar_path: <...>/stanford-postagger.jar
- change stanf_tagger_path_en: <...>/models..tagger
- change sql_username, sql_password, sql_host (localhost), sql_port (3306)
 
Start KH Coder
```bash
perl ./kh_coder.pl
```
