#!/usr/bin/env bash

deflate() {
    archive="$1"
    exit_code=1
    if [ -z "$archive" ]
    then
        msg="ERROR:  no archive file specified"
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        print_help
        exit $exit_code
    fi
    exit_code=2
    if [ ! -e "$archive" ]
    then
        msg="No such file:  $archive"
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    archive_type=$(IFS='.'; echo $archive | rev | cut -d ' ' -f 1 | rev)
    canhaz_msg="Successfully extracted $archive!!"
    sadclown_msg="ERROR:  Failed to extract $archive"
    workdir=$(pwd)
    archive_dir=$(echo $archive | sed  "s/\.$archive_type$//")
    archive_name="$archive_dir"
    archive_dir="$workdir/$archive_dir"
    if [ ! -d "$archive_dir" ]
    then
        mkdir $archive_dir
    fi
    echo "Deflating archive $archive" >> $log_file
    case "$archive_type" in
        cbr)
            exit_code=3
            has_unrar=$(which unrar)
            if [ -z "$has_unrar" ]
            then
                msg="ERROR:  unrar not installed.  Install unrar-free and try again."
                echo $msg > /dev/stderr
                echo $msg >> $log_file
                exit $exit_code
            fi
            exit_code=4
            unrar e -r -y $archive $archive_dir >> $log_file
            if [ "$?" -gt 0 ]
            then
                emsg="$!"
                echo "$sadclown_msg:  $emsg" > /dev/stderr
                echo "$sadclown_msg:  $emsg" >> $log_file
                exit $exit_code
            else
                echo $canhas_msg >> $log_file
            fi
            ;;
        cbz)
            exit_code=5
            has_unzip=$(which unzip)
            if [ -z "$has_unzip" ]
            then
                msg="ERROR:  unzip not installed.  Install unzip and try again."
                echo $msg > /dev/stderr
                echo $msg >> $log_file
                exit $exit_code
            fi
            exit_code=6
            unzip $archive -d $archive_dir >> $log_file
            if [ "$?" -gt 0 ]
            then
                emsg="$!"
                echo "$sadclown_msg:  $emsg" > /dev/stderr
                echo "$sadclown_msg:  $emsg" >> $log_file
                exit $exit_code
            fi
            ;;
        cbt)
            exit_code=7
            has_tar=$(which tar)
            if [ -z "$has_tar" ]
            then
                msg="ERROR:  WTF?!  How do you not have tar?!"
                echo $msg > /dev/stderr
                echo $msg >> $log_file
                exit $exit_code
            fi
            exit_code=8
            tar -xvzf $archive $archive_dir >> $log_file
            if [ "$?" -gt 0 ]
            then
                emsg="$!"
                echo "$sadclown_msg:  $emsg" > /dev/stderr
                echo "$sadclown_msg:  $emsg" >> $log_file
                exit $exit_code
            fi
            ;;
        cba)
            exit_code=9
            has_unace=$(which unace)
            if [ -z "$has_unace" ]
            then
                msg="ERROR:  unace not installed.  Install unace and try again."
                echo $msg > /dev/stderr
                echo $msg >> $log_file
                exit $exit_code
            fi
            exit_code=10
            cp $archive $archive_dir
            cd $archive_dir
            unace e -y $archive >> $log_file
            if [ "$?" -gt 0 ]
            then
                emsg="$!"
                echo "$sadclown_msg:  $emsg" > /dev/stderr
                echo "$sadclown_msg:  $emsg" >> $log_file
                exit $exit_code
            fi
            cd ..
            ;;
        cb7)
            exit_code=11
            has_7zr=$(which 7zr)
            if [ -z "$has_7zr" ]
            then
                msg="ERROR:  7zr not installed.  Install 7zr and try again."
                echo $msg > /dev/stderr
                echo $msg >> $log_file
                exit $exit_code
            fi
            exit_code=12
            7zr e -y $archive $archive_dir >> $log_file
            if [ "$?" -gt 0 ]
            then
                emsg="$!"
                echo "$sadclown_msg:  $emsg" > /dev/stderr
                echo "$sadclown_msg:  $emsg" >> $log_file
                exit $exit_code
            fi
            ;;
    esac
    echo $archive_dir
}

make_tiffs() {
    exit_code=13
    archive_dir="$1"
    has_convert=$(which convert)
    if [ -z "$has_convert" ]
    then
        msg="ERROR:  convert not installed.  Install imagemagick and try again."
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    tiff_list=()
    for f in $archive_dir/*
    do
        safe_name=$(echo "$f" | sed 's/ /_/g')
        if [ "$f" != "$safe_name" ]
        then
            echo "Copying file '$f' to unproblematic name '$safe_name'" >> $log_file
            cp "$f" $safe_name
        fi
        ftype=$(IFS='.'; echo $safe_name | rev | cut -d ' ' -f 1 | rev)
        fname=$(echo $safe_name | sed 's/\.$ftype$//')
        ftiff="${fname}.tiff"
        is_img_file=$(file --mime-type -b $safe_name | grep image)
        if [ -z "$is_img_file" ]
        then
            echo "$safe_name is not an image file.  Skipping..."
            continue
        fi
        exit_code=14
        echo "Converting $safe_name to $ftiff" >> $log_file
        convert -density 300x300 -compress None -type TrueColor $safe_name $ftiff >> $log_file
        if [ "$?" -gt 0 ]
        then
            msg="On noes!1  Failed to convert $safe_name to $ftiff"
            echo $msg > /dev/stderr
            echo $msg >> $log_file
            exit $exit_code
        fi
        tiff_list+=("$ftiff")
    done
    echo ${tiff_list[@]}
}

make_multipage_tiff() {
    tiff_list=("$@")
    exit_code=15
    has_tiffcp=$(which tiffcp)
    if [ -z "$has_tiffcp" ]
    then
        msg="ERROR:  tiffcp not installed.  Install libtiff and try again."
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    exit_code=16
    mptiff="${archive_dir}.tiff"
    echo "Creating multipage TIFF $mptiff" >> $log_file
    t=$'\t'
    for tf in ${tiff_list[@]}
    do
        echo "${t}including file $tf" >> $log_file
    done
    tiffcp -c none ${tiff_list[@]} $mptiff >> $log_file
    if [ "$?" -gt 0 ]
    then
        msg="ERROR:  Failed to create multipage TIFF."
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    echo $mptiff
}

make_pdf() {
    mptiff="$1"
    exit_code=17
    has_tiff2pdf=$(which tiff2pdf)
    if [ -z "$has_tiff2pdf" ]
    then
        msg="ERROR:  tiff2pdf not Installed.  Install libtiff-tools and try again."
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    exit_code=18
    pdfname=$(echo $mptiff | sed 's/tiff$/pdf/')
    echo "Creating PDF file $pdfname from multipage TIFF $mptiff" >> $log_file
    tiff2pdf -o $pdfname -p letter -F $mptiff >> $log_file
    tiff_exit="$?"
    tiff_msg="$!"
    rm $mptiff
    if [ "$tiff_exit" -gt 0 ]
    then
        msg="ERROR:  Failed to create PDF from multipage TIFF:  $tiff_msg"
        echo $msg > /dev/stderr
        echo $msg >> $log_file
        exit $exit_code
    fi
    echo $pdfname
}

print_help() {
    echo "Usage:"
    echo
    echo "$0 /path/to/<archive name>.<archive format>"
    echo
    echo "Produces:"
    echo "    <archive name>.pdf"
    echo "    <archive name>.tiff (multi-page TIFF)"
    echo
    echo "Eligible formats:  cba, cbr, cbt, cbz cb7"
    echo
    echo "Requirements"
    echo "    General"
    echo "        convert  (imagemagick)"
    echo "        tiffcp   (libtiff)"
    echo "        tiff2pdf (libtiff-tools)"
    echo "        file     (core/standard)"
    echo "    Format-specific"
    echo "        cba"
    echo "            unace"
    echo "        cbr"
    echo "            unrar-free"
    echo "        cbt"
    echo "            tar"
    echo "        cbz"
    echo "            unzip"
    echo "        cb7"
    echo "            7zr"
}

decode_exit() {
    exit_code="$1"
    exit_msgs=("Success" "No archive specified" "Specified archive does not exist" "unrar not installed" "Failed to unrar archive" "unzip not installed" "Failed to unzip archive" "tar not installed" "Failed to untar archive" "unace not installed" "Failed to unace archive" "7zr not installed" "Failed to deflate 7zip archive" "imagemagick/convert not installed" "Failed to convert image to TIFF" "libtiff/tiffcp not installed" "Failed to create multi-page TIFF" "libtiff-tools/tiff2pdf not installed" "Failed to create PDF from multi-page TIFF")
    echo ${exit_msgs[$exit_code]}
}

flavor=$(uname -s)
log_file=$(echo $0 | sed 's/sh/log/')
case "$1" in
    -h|--help|help)
        print_help
        exit 0
        ;;
    diag*)
        shift
        decode_exit $@
        ;;
    '')
        deflate
        ;;
    *)
        archive="$1"
        ;;
esac
echo "Processing archive $archive" | tee -a $log_file
archive_dir=$(deflate $@)
tiff_list=($(make_tiffs $archive_dir))
mptiff=$(make_multipage_tiff ${tiff_list[@]})
rm -rf $archive_dir
pdfname=$(make_pdf $mptiff)
echo "Finished creating $pdfname from archive $archive" | tee -a $log_file
exit 0
