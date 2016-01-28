#!/bin/bash

rm -rf build
mkdir -p build

ssd=adfs.ssd

# Create a blank SSD image
tools/mmb_utils/blank_ssd.pl build/${ssd}
echo

cd src
for top in  `ls top_*.asm`
do
    name=`echo ${top%.asm} | cut -c5-`
    echo "Building $name..."

    # Assember the ROM
    ../tools/beebasm/beebasm -i ${top} -v >& ../build/${name}.log

    # Check if ROM has been build, otherwise fail early
    if [ ! -f ../build/${name} ]
    then
        cat ../build/${name}.log
        echo "build failed to create ${name}"
        exit
    fi

    # Create the .inf file
    echo -e "\$."${name}"\t8000\t8000" > ../build/${name}.inf

    # Add into the SSD
    ../tools/mmb_utils/putfile.pl ../build/${ssd} ../build/${name}

done
cd ..

echo
tools/mmb_utils/info.pl  build/${ssd}
