

export BASE=`pwd`

export FGLRESOURCEPATH=$BASE/etc
export FGLPROFILE=$BASE/etc/profile
export FGLIMAGEPATH=$FGLDIR/lib/image2font.txt:$FGLDIR/lib:../../pics

cd ../bin3x

fglrun widgets.42r
