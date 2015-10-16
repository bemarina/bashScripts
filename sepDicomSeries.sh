newDirec='series1'
seriesNamesFile='series1.txt'


## No inputs...
seriesLen=$(wc -l < $seriesNamesFile)
echo $seriesLen
mkdir $newDirec
for n1 in `seq 2 $seriesLen`;
    do
        file2move=$(head -$n1 $seriesNamesFile | tail -1)
        cp $file2move $newDirec'/'$file2move
    done



newDirec='series2'
seriesNamesFile='series2.txt'


## No inputs...
seriesLen=$(wc -l < $seriesNamesFile)
echo $seriesLen
mkdir $newDirec
for n1 in `seq 2 $seriesLen`;
    do
        file2move=$(head -$n1 $seriesNamesFile | tail -1)
        cp $file2move $newDirec'/'$file2move
    done



newDirec='series3'
seriesNamesFile='series3.txt'
## No inputs...
seriesLen=$(wc -l < $seriesNamesFile)
echo $seriesLen
mkdir $newDirec
for n1 in `seq 2 $seriesLen`;
    do
        file2move=$(head -$n1 $seriesNamesFile | tail -1)
        cp $file2move $newDirec'/'$file2move
    done
