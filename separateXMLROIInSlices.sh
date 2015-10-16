## Idea would be to insert ONLY the input file name and the 'ext3' variable
inputfile='annotationFile.xml'
ext3='xml1'

#!--------------

#get all instances of 'sopInstanceUID' and save them in a file
grep 'sopInstanceUID' $inputfile > sopInstanceUID.txt

#get original uniqueID 
uniqueIDWithquotes=$(grep 'uniqueIdentifier=' $inputfile | awk '{print $11}' | cut -d "=" -f 2)
#echo $uniqueIDWithquotes

#count number of slices
numslices=$(wc -l sopInstanceUID.txt | awk '{print $1}')
echo $numslices' Slices'

## other variables
name='fileSlice'
ext2='NoCoord'
ext='.xml'
last='"'

## this should be a sequence from 1 to $numslices
for n1 in `seq 1 $numslices`;  #`seq 30 32`;
#for n1 in `seq 1 2`;  #`seq 30 32`;
	do
		#generate the two ID strings of the slice
		#sopInsUID
		sopInsUID=$(head -$n1 sopInstanceUID.txt | tail -1 | awk '{print $4}' | cut -d "/" -f 1)
		#echo $sopInsUID
		stringtest='Slice '$n1' ...'
		echo $stringtest

		#imRefUID
		imRefUID=$(echo ${sopInsUID/sopInstance/imageReference})
		#echo $imRefUID
		
		#lenNumber=3 ## this is Hard coded - length of slice ID
		## sopInstanceUID
		#lenSopID=$(echo ${#sopInsUID}) #find length of string
		#let "ind=lenSopID-lenNumber-1"
		#partialSopID=$(echo ${sopInsUID:0:$ind})
		## imageReferenceUID
		#lenImRefID=$(echo ${#imRefUID}) #find length of string
		#let "ind1=lenImRefID-lenNumber-1"
		#partialImRefID=$(echo ${imRefUID:0:$ind1})
		## number of first slice--- this should be n1 instead?
		#number=$(echo ${sopInsUID:$ind:$lenNumber})

	
		imRefCol1=$(grep -n '<imageReferenceCollection>' $inputfile | cut -d : -f 1)
		imCol1=$(grep -n '<imageCollection>' $inputfile | cut -d : -f 1)
		let "tail1=imCol1-imRefCol1+1"
		imCol2=$(grep -n '</imageCollection>' $inputfile | cut -d : -f 1)
		imRefCol2=$(grep -n '</imageReferenceCollection>' $inputfile | cut -d : -f 1)

		## opening tags of geometricShapeCollection 
		nGeo1=$(grep -n '<geometricShapeCollection>' $inputfile | cut -d : -f 1)
		nGeo2=$(grep -n '<spatialCoordinateCollection>' $inputfile | cut -d : -f 1)
		let "tail2=nGeo2-nGeo1+1"

		filename=$name$n1$ext2$ext3$ext
		touch $filename 
		head -2 $inputfile >> $filename
		cat user.txt >> $filename
	
		## copy some opening tags
		head -$imCol1 $inputfile | tail -$tail1 >> $filename 
		
		#copy the ONE line with corresponding sopInstanceUID
		head -$n1 sopInstanceUID.txt | tail -1 >> $filename
				
		#copy all the closing tags until </imageReferenceCollection>
		head -$imRefCol2 $inputfile | tail -$tail1 >> $filename
		
		#copy the opening tags of the geometricShapeCollection
		head -$nGeo2 $inputfile | tail -$tail2 >> $filename	
			
		## An IF construct to check whether there are/aren't coordinates
		checkSlices=$(grep $imRefUID $inputfile)
		
		# IF there are NO coordinates
		if [ -z "${checkSlices}" ]; then
			#echo "No coordinates"
			#just copy the tail of the inpufile
			tail -8 $inputfile >> $filename
		fi
		
		# IF there are coordinates
		if [ -n "${checkSlices}" ]; then
			namec='coordSlice'
			coordfile=$namec$n1$ext3$ext
			touch $coordfile
			#echo "There ARE coordinates"
	
			#copy the lines with corresponding imageReferenceUID (coordinates)
			grep $imRefUID $inputfile >> $filename
			
			#now, correct the indeces so that they start from 0
			
			#find line number of first coordinate 
			coordStart=$(grep -n '<spatialCoordinateCollection>' $filename | cut -d : -f 1)
			coordStartf=$coordStart
			#copy tail of file
			tail -8 $inputfile >> $filename
			#find line number of last coordinate
			coordEnd=$(grep -n '</spatialCoordinateCollection>' $filename | cut -d : -f 1)
			
			let "coordStart += 1"
			let "coordEnd -= 1"
				
			#LOOP over coordinates to change their indeces		
			NewCoordIndx=0
								
			for i in `seq $coordStart $coordEnd`;
			#for i in `seq $coordStart $coordStart`;
				do						
					# this is the actual line that has to be corrected
					linetocorrect=$(sed -n ${i}p $filename)
				
					#shopt -s extglob; echo "${linetocorrect//coordinateIndex=\"*([^\"])\"/coordinateIndex=\"124\"}" >> answerbla.txt
					shopt -s extglob; echo "${linetocorrect//coordinateIndex=\"*([^\"])\"/coordinateIndex=\"$NewCoordIndx\"}" >> $coordfile
										
					#remove line with old coordinate -- not sure how to do this!! Nothing worked so far!									
					let "NewCoordIndx += 1"	
				
				done
		fi  
						
		#change the ROI labels
		sed -i".bak" 's/codeMeaning="???"/codeMeaning="ROI Only"/g' $filename
		sed -i".bak" 's/codeValue="???"/codeValue="ROI"/g' $filename
		sed -i".bak" 's/codingSchemeDesignator="???"/codingSchemeDesignator="ROI Only"/g' $filename
        nameUID='slice'
        sed -i".bak" "s/$uniqueIDWithquotes/$last$nameUID$n1$ext3$last/g" $filename
		        
		#combine $filename and $coordfile into $filename1 (this should be the FINAL file)
		#ONLY if there are coordinates
		if [ -n "${checkSlices}" ]; then
			namef='fileCoordSlice'
			filename1=$namef$n1$ext3$ext
			touch $filename1
		
			#echo $coordStartf
			head -$coordStartf $filename >> $filename1
			cat $coordfile >> $filename1
			tail -8 $filename >> $filename1
			
			#rm coordinates*
			rm $coordfile
			#rm *NoCoord.xml
			rm $filename			
		fi						
		
		# before the next iteration, move to the next slice number
		let "n1+=1"
		
		#remove bak files
		rm *.bak
				
	done

#### Other things I tried .... 
#### ----------------------------

#uniqueIDWithquotes=$(grep 'uniqueIdentifier=' fileSlice1NoCoordxml1.xml| awk '{print $13}' | cut -d "=" -f 2)
#echo $uniqueIDWithquotes

#sed -i".bak" "s/$uniqueIDWithquotes/$filename/g" $filename
#sed -i".bak" "s/$uniqueIDWithquotes/$last$filename$last/g" $filename
#sed "s/$txt_ori/$txt_rplc/g" $text > text.out

#linee=$(sed -n 24p $filename)
#echo $linee
#echo "${linee/coordinateIndex=\"13789\"/coordinateIndex="124"}"   ## this works - changes 13789 to 124

#oldCoord=13789
#echo "${linee/coordinateIndex=\"$oldCoord\"/coordinateIndex="124"}"   ## this works - changes 13789 to 124

#these two DO work
#string12='UID="78990"'
#echo "$(echo $string12 | awk -F '"' '{print $2}')" ## this extracts the old coordinate

## this works...!
#string12='coordinateIndex="78990"'
#echo $string12
#oldCoord=$(echo "$(echo $string12 | awk -F '"' '{print $2}')") ## this extracts the old coordinate
#echo "${string12/coordinateIndex=\"$oldCoord\"/coordinateIndex="124"}"   ## this works - changes 13789 to 124

#line='<Coordinate text1="0" coordinateIndex="78?907??" anotherID="9098" yetanoher="1.2.3" xyz:text="abc"/>'
#echo $line

#works!!!
#shopt -s extglob; echo "${line//coordinateIndex=\"*([^\"])\"/coordinateIndex=\"124\"}" >> answerbla.txt

#str=$(cat << EOF
#line='<Coordinate text1="0" coordinateIndex="78?907??" anotherID="9098" yetanoherID="1.2.3" xyz:text="abc"/>'
#EOF
#)

#works
#echo "$str" |perl -pe 's|(coordinateIndex=)".*?"|$1"abc"|g'
#works
#echo "$str" |perl -pe 's|(coordinateIndex=)".*?"|$1"124"|g'

#works!!!
#var=coordinateIndex
#value=124
#if [[ $line =~ $var=\"([0-9|\?]+)\" ]]; then
#    echo ${line/$var=\"${BASH_REMATCH[1]}\"/$var=\"$value\"}
#fi

## -------------------------------
## try to extract the string sopInsUID automatically from the original file
#sopInsUIDaut=$(echo $sopInsUID | awk '{print $1}') ## this extracts the old coordinate
#echo $sopInsUIDaut

#sopInsUIDaut=$(echo $sopInsUID | awk '{print $4}') ## this should extract the sopInsUID string FROM THE FILE

#n1=1
#head -$n1 sopInsXML3.txt | awk '{print $4}' | cut -d "/" -f 1 
#string1=$(head -$n1 sopInsXML3.txt | awk '{print $4}' | cut -d "/" -f 1) 
#echo $string1

#head -1 sopInsXML3.txt | awk '{print $4}' | cut -d "/" -f 1  ### this gives the string I want (first field before the delimiter)
#head -1 sopInsXML3.txt | awk '{print $4}' | cut -d "/" -f 2  ### this gives (second field after the delimiter)

## try to generate automatically imRefUID, given sopInsUID
#tempstring=$sopInsUID
#imRefUIDaut=$(echo ${tempstring/sopInstance/imageReference})
#echo $imRefUIDaut





