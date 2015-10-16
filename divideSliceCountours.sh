# For two shapes in one slice; double check for more 
## to loop over the "fileCoordSlice46xml1.xml" files (that output from findFilesWithCoords.sh) (findFilesWithCoords.sh was previously script9.sh)
## INPUTS required:
slNumMin=25
slNumMax=78
roiNum=1

for ii in `seq $slNumMin $slNumMax`;

    do

        inFileName='fileCoordSlice'$ii'xml'$roiNum'.xml'

        # find image name in the "fileCoordSlice" file
        imgNum=$(grep 'sopInstanceUID' $inFileName | cut -d "=" -f 4 | cut -d "/" -f 1 | sed "s/\"//g")
        areMultCont=$(grep $imgNum multCont.dat)

        if [ -z "${areMultCont}" ]; then
            echo "Slice: "$ii" No multiple contours in this slice"
        fi

        if [ -n "$areMultCont" ]; then
            echo "Slice: "$ii" There are multiple contours!"
            cont1=$(echo $areMultCont | cut -d "," -f 3)
            cont2=$(echo $areMultCont | cut -d "," -f 4)
            #echo $cont1 $cont2

            ## first check that $cont1 + $cont2 gives the total number of coordinates
            let "totalCoords=$cont1 + $cont2"
            #echo $totalCoords

            nc1=$(grep -n '<spatialCoordinateCollection>' $inFileName | cut -d ":" -f 1)
            nc2=$(grep -n '</spatialCoordinateCollection>' $inFileName | cut -d ":" -f 1)

            let "totalCoordsFile=$nc2-$nc1-1"

            if [ $totalCoords -eq $totalCoordsFile ]; then
                echo 'Number of coordinates checks!'
            fi

            # copy the first $cont1 coordinates
            newFileName='fileCoordSlice'$ii'xml'$roiNum'SepCont.xml'
            let "firstContLines=$nc1+$cont1"
            head -$firstContLines $inFileName >> $newFileName

            # add closing GeometricShape tag
            echo '</spatialCoordinateCollection>' >> $newFileName
            echo '</GeometricShape>' >> $newFileName

            # add opening tag for new GeometricShape tag
            echo '<GeometricShape cagridId="0" includeFlag="true" lineColor="255    0    0" shapeIdentifier="2" xsi:type="Polyline">' >> $newFileName
            echo '<spatialCoordinateCollection>' >> $newFileName

            # copy coordinates of second shapes
            let "lastlines=$firstContLines+1"
            filelen=$(wc -l < $inFileName) 
            #echo $filelen
            let "lines2copy=$filelen-$lastlines+1"
            #echo $lines2copy
            tail -$lines2copy $inFileName >> $newFileName

            # replace coordinate ref numbers in the (new) second (and more) shapes
            # create dummy file to store the new coordinates
            dcoords='dummyCoords.txt'
            touch $dcoords

            #LOOP over coordinates to change their indeces
            NewCoordIndx=0
            #For this example I want 50+4 (added 4 lines) to 83 + 4 (added 4 lines above)
            let "coordStart=$lastlines+4"
            let "coordEnd=$nc2-1+4"

            #echo $coordStart
            #echo $coordEnd

            for i in `seq $coordStart $coordEnd`;
                do
                    # this is the actual line that has to be corrected (in the new file)
                    linetocorrect=$(sed -n ${i}p $newFileName)

                    #shopt -s extglob; echo "${linetocorrect//coordinateIndex=\"*([^\"])\"/coordinateIndex=\"124\"}" >> answerbla.txt
                    shopt -s extglob; echo "${linetocorrect//coordinateIndex=\"*([^\"])\"/coordinateIndex=\"$NewCoordIndx\"}" >> $dcoords

                    #advance NewCoordIndx
                    let "NewCoordIndx += 1"
                done
            #combine $newFileName and $dcoords to get the final file
            finalFile='sepContoursSlice'$ii'ROI'$roiNum'.xml'

            touch $finalFile
            let "lasthead=$nc1+$cont1+4"
            head -$lasthead $newFileName >> $finalFile
            cat $dcoords >> $finalFile
            let "lasttail=$filelen-$nc2+1"
            tail -$lasttail $newFileName >> $finalFile
            
            #remove both of them before moving to the next fileSliceXXxml1.xml
            rm $newFileName
            rm $dcoords
        fi ## end of part for two contours per slice
        
    done

    


