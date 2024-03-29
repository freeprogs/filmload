#!/bin/bash

# This script loads a film from YouTube.com, Ok.ru, Vk.com, Mail.ru,
# Rutube.ru, Brighteon.com and Dzen.ru by the url to the output
# filename, selecting an optimal video format (neither very large, nor
# very small) for watching on a tv screen.
# Copyright (C) 2021-2023, Slava <freeprogs.feedback@yandex.ru>
# License: GNU GPLv3

progname=`basename $0`

# Print an error message to stderr
# error(str)
error()
{
    echo "error: $progname: $1" >&2
}

# Print a message to stdout
# msg(str)
msg()
{
    echo "$progname: $1"
}

# Print program usage to stderr
# usage()
usage()
{
    echo "Try \`$progname --help' for more information." >&2
}

# Print program help info to stderr
# help_info()
help_info()
{
    {
        echo "usage: $progname url savename"
        echo ""
        echo "Load a film from YouTube.com, Ok.ru, Vk.com, Mail.ru, Rutube.ru,"
        echo "Brighteon.com and Dzen.ru by url to the output filename, selecting"
        echo "an optimal video format (neither very large, nor very small)"
        echo "for watching on a tv screen."
        echo ""
        echo "  noarg      --  Print program usage information."
        echo "  --help     --  Print program help information."
        echo "  --version  --  Print program version information."
        echo ""
        echo "Example:"
        echo ""
        echo "  $progname https://www.youtube.com/watch?v=a1b2c3d4 videoname.mp4"
        echo ""
        echo "  It will load the video file from YouTube with optimal resolution"
        echo "  and size and save it as videoname.mp4 file."
        echo ""
    } >&2
}

# Print program version information to stderr
# print_version()
print_version()
{
    {
        echo "filmload v1.0.4"
        echo "Copyright (C) 2021-2023, Slava <freeprogs.feedback@yandex.ru>"
        echo "License: GNU GPLv3"
    } >&2
}

# Download YouTube video in selected format
# Ytf(url[, ofile[, fmt=18]])
Ytf()
{
    local fmtn=${3:-18}

    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url [ ofile ] [ fmtn=$fmtn ]"
        return 1
    } 1>&2
    case $# in
      1) youtube-dl -c -f "$fmtn" "$1";;
      *) youtube-dl -c -f "$fmtn" "$1" -o "$2";;
    esac
}

# Download YouTube video in selected format
# Use yt-dlp program
# Ytfn(url[, ofile[, fmt=18]])
Ytfn()
{
    local fmtn=${3:-18}

    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url [ ofile ] [ fmtn=$fmtn ]"
        return 1
    } 1>&2
    case $# in
      1) yt-dlp -c -f "$fmtn" "$1";;
      *) yt-dlp -c -f "$fmtn" "$1" -o "$2";;
    esac
}

# Download YouTube video
# Yt(url[, ofile])
Yt()
{
    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url [ ofile ]"
        return 1
    } 1>&2
    case $# in
      1) youtube-dl -c "$1";;
      *) youtube-dl -c "$1" -o "$2";;
    esac
}

# Download YouTube video
# Use yt-dlp program
# Ytn(url[, ofile])
Ytn()
{
    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url [ ofile ]"
        return 1
    } 1>&2
    case $# in
      1) yt-dlp -c "$1";;
      *) yt-dlp -c "$1" -o "$2";;
    esac
}

# Get available YouTube video file formats
# Ytl(url)
Ytl()
{
    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url"
        return 1
    } 1>&2
    youtube-dl -F "$1" | sed '1,/format code/d'
}

# Get available YouTube video file formats
# Use yt-dlp program
# Ytln(url)
Ytln ()
{
    [ $# -eq 0 -o "$1" = "--help" ] && {
        echo "usage: $FUNCNAME url";
        return 1
    } 1>&2;
    yt-dlp -F "$1" | awk '
$1 == "ID" && $2 == "EXT" { state_show = 1; }
state_show { print }
'
}

# Load file from the YouTube, Ok.ru, Vk.com, Mail.ru, Rutube.ru,
# Brighteon.com or Dzen.ru url to the output file
# load_file(url, ofname)
# args:
#   url - The url for video on YouTube, Ok.ru, Vk.com, Mail.ru,
#         Rutube.ru, Brighteon.com or Dzen.ru
#   ofname - The output file name
# return:
#   none
load_file()
{
    local url=$1
    local ofname=$2
    local urltype
    local UT_YT=0 UT_OK=1 UT_VK=2 UT_MR=3 UT_RT=4 UT_BR=5 UT_DZ=6

    urltype=`detect_url_type "$url"`
    case $urltype in
      $UT_YT) load_file_yt "$url" "$ofname";;
      $UT_OK) load_file_ok "$url" "$ofname";;
      $UT_VK) load_file_vk "$url" "$ofname";;
      $UT_MR) load_file_mr "$url" "$ofname";;
      $UT_RT) load_file_rt "$url" "$ofname";;
      $UT_BR) load_file_br "$url" "$ofname";;
      $UT_DZ) load_file_dz "$url" "$ofname";;
      *) error "Unknown url type: \"$urltype\"";;
    esac
}

# Detect url type that means on which site this url is placed
# detect_url_type(url)
# args:
#   url - The url to video on YouTube, Ok.ru, Vk.com, Mail.ru,
#         Rutube.ru, Brighteon.com or Dzen.ru
# return:
#   "0" - For YouTube url
#   "1" - For Ok.ru url
#   "2" - For Vk.com url
#   "3" - For Mail.ru url
#   "4" - For Rutube.ru url
#   "5" - For Brighteon.com url
#   "6" - For Dzen.ru url
#   none - If unknown url type
detect_url_type()
{
    local url=$1
    local UT_YT=0 UT_OK=1 UT_VK=2 UT_MR=3 UT_RT=4 UT_BR=5 UT_DZ=6
    local urlcore

    urlcore=`echo "$url" | get_url_core`
    if [ "$urlcore" = "www.youtube.com" ]; then
        echo "$UT_YT"
    elif [ "$urlcore" = "ok.ru" ]; then
        echo "$UT_OK"
    elif [ "$urlcore" = "vk.com" ]; then
        echo "$UT_VK"
    elif [ "$urlcore" = "my.mail.ru" ]; then
        echo "$UT_MR"
    elif [ "$urlcore" = "rutube.ru" ]; then
        echo "$UT_RT"
    elif [ "$urlcore" = "www.brighteon.com" ]; then
        echo "$UT_BR"
    elif [ "$urlcore" = "dzen.ru" ]; then
        echo "$UT_DZ"
    fi
}

# Get domain name from url with protocol and path
# get_url_core(url)
# args:
#   url - The url in form https://domain/path
# return:
#   "domain" - Part of url between protocol and path
get_url_core()
{
    sed 's%^https://\([^/]*\)/.*$%\1%'
}

# Load file from YouTube
# load_file_yt(url, ofname)
# args:
#   url - The url for video on YouTube
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_yt()
{
    local url=$1
    local ofname=$2
    local vformat

    msg "Loading file from YouTube to $ofname"
    vformat=`load_file_yt_get_vformat "$url"`
    if [ -z "$vformat" ]; then
        error "Video format is not found"
        return 1
    fi
    msg "Found format $vformat"
    Ytfn "$url" "$ofname" "$vformat"
}

# Determine the optimal format for video on YouTube;
# It returns a format number for different formats; for the 720p format
# otherwise for the 1080p format otherwise for the 480p format if
# previous formats don't exist
# load_file_yt_get_vformat(url)
# args:
#   url - The url for video on YouTube
# return:
#   "N" for 720p |
#   "N" for 1080p |
#   "N" for 480p |
#   none
load_file_yt_get_vformat()
{
    local url=$1

    Ytl "$url" | awk '
/audio only|video only/ {
    next
}
$4 ~ /480p/ {
    has480 = 1
    vformat480 = $1
}
$4 ~ /720p/ {
    has720 = 1
    vformat720 = $1
}
$4 ~ /1080p/ {
    has1080 = 1
    vformat1080 = $1
}
END {
    if (has720) {
       vformat = vformat720
    }
    else if (has1080) {
       vformat = vformat1080
    }
    else if (has480) {
       vformat = vformat480
    }
    print vformat
}
'
}

# Load file from Ok.ru
# load_file_ok(url, ofname)
# args:
#   url - The url for video on Ok.ru
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_ok()
{
    local url=$1
    local ofname=$2
    local vformat

    msg "Loading file from Odnoklassniki to $ofname"
    vformat=`load_file_ok_get_vformat "$url"`
    if [ -z "$vformat" ]; then
        error "Video format is not found"
        return 1
    fi
    msg "Found format $vformat"
    Ytf "$url" "$ofname" "$vformat"
}

# Determine the optimal format for video on Ok.ru;
# It returns the hd format or the sd format if the hd format
# doesn't exist
# load_file_ok_get_vformat(url)
# args:
#   url - The url for video on Ok.ru
# return:
#   "format for hd" - String with format for hd
#   "format for sd" - String with format for sd if no hd
#   none - If no sd and no hd
load_file_ok_get_vformat()
{
    local url=$1

    Ytl "$url" | awk '
state == 0 {
    if ($1 ~ /^(sd|hd)$/)
        state = 1
}
state == 1 {
    if ($1 ~ /^hls-[0-9]+$/) {
        vformat = $1
        state = 0
    }
}
END {print vformat}
'
}

# Load file from Vk.com
# load_file_vk(url, ofname)
# args:
#   url - The url for video on Vk.com
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_vk()
{
    local url=$1
    local ofname=$2
    local vformat

    msg "Loading file from VKontakte to $ofname"
    vformat=`load_file_vk_get_vformat "$url"`
    if [ -z "$vformat" ]; then
        error "Video format is not found"
        return 1
    fi
    msg "Found format $vformat"
    Ytfn "$url" "$ofname" "$vformat"
}

# Determine the optimal format for video on Vk.com;
# It returns hls-form for different formats; for the 720p format
# otherwise for the 1080p format otherwise for the 480p format if
# previous formats don't exist
# load_file_vk_get_vformat(url)
# args:
#   url - The url for video on Vk.com
# return:
#   "hls-NNNN" for 720p |
#   "hls-NNNN" for 1080p |
#   "hls-NNNN" for 480p |
#   none
load_file_vk_get_vformat()
{
    local url=$1

    Ytln "$url" | awk '
$1 ~ /^hls/ && $2 == "mp4" {
    if ($3 ~ /x480$/) {
        has480 = 1
        vformat480 = $1
    }
    else if ($3 ~ /x720$/) {
        has720 = 1
        vformat720 = $1
    }
    else if ($3 ~ /x1080$/) {
        has1080 = 1
        vformat1080 = $1
    }
}
END {
    if (has720) {
       vformat = vformat720
    }
    else if (has1080) {
       vformat = vformat1080
    }
    else if (has480) {
       vformat = vformat480
    }
    print vformat
}
'
}

# Load file from Mail.ru
# load_file_mr(url, ofname)
# args:
#   url - The url for video on Mail.ru
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_mr()
{
    local url=$1
    local ofname=$2
    local vformat

    msg "Loading file from Mail.ru to $ofname"
    vformat=`load_file_mr_get_vformat "$url"`
    if [ -z "$vformat" ]; then
        error "Video format is not found"
        return 1
    fi
    msg "Found format $vformat"
    Ytf "$url" "$ofname" "$vformat"
}

# Determine the optimal format for video on Mail.ru;
# It returns the 720p format otherwise the 1080p format otherwise the
# 480p format if previous formats don't exist
# load_file_mr_get_vformat(url)
# args:
#   url - The url for video on Mail.ru
# return:
#   "720p" |
#   "1080p" |
#   "480p" |
#   none
load_file_mr_get_vformat()
{
    local url=$1

    Ytl "$url" | awk '
$1 ~ /480p/ {
    has480 = 1
    vformat480 = "480p"
}
$1 ~ /720p/ {
    has720 = 1
    vformat720 = "720p"
}
$1 ~ /1080p/ {
    has1080 = 1
    vformat1080 = "1080p"
}
END {
    if (has720) {
       vformat = vformat720
    }
    else if (has1080) {
       vformat = vformat1080
    }
    else if (has480) {
       vformat = vformat480
    }
    print vformat
}
'
}

# Load file from Rutube.ru
# load_file_rt(url, ofname)
# args:
#   url - The url for video on Rutube.ru
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_rt()
{
    local url=$1
    local ofname=$2
    local vformat

    msg "Loading file from Rutube.ru to $ofname"
    vformat=`load_file_rt_get_vformat "$url"`
    if [ -z "$vformat" ]; then
        error "Video format is not found"
        return 1
    fi
    msg "Found format $vformat"
    Ytfn "$url" "$ofname" "$vformat"
}

# Determine the optimal format for video on Rutube.ru;
# It returns m3u8-form for different formats; for the 720p format
# otherwise for the 1080p format otherwise for the 480p format if
# previous formats don't exist
# load_file_rt_get_vformat(url)
# args:
#   url - The url for video on Rutube.ru
# return:
#   "m3u8-NNNN" for 720p |
#   "m3u8-NNNN" for 1080p |
#   "m3u8-NNNN" for 480p |
#   none
load_file_rt_get_vformat()
{
    local url=$1

    Ytl "$url" | awk '
$1 ~ /^m3u8/ && $2 == "mp4" {
    if ($3 ~ /x480$/) {
        has480 = 1
        vformat480 = $1
    }
    else if ($3 ~ /x720$/) {
        has720 = 1
        vformat720 = $1
    }
    else if ($3 ~ /x1080$/) {
        has1080 = 1
        vformat1080 = $1
    }
}
END {
    if (has720) {
       vformat = vformat720
    }
    else if (has1080) {
       vformat = vformat1080
    }
    else if (has480) {
       vformat = vformat480
    }
    print vformat
}
'
}

# Load file from Brighteon.com
# load_file_br(url, ofname)
# args:
#   url - The url for video on Brighteon.com
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_br()
{
    local url=$1
    local ofname=$2
    local m3u8_url

    msg "Loading file from Brighteon.com to $ofname"
    m3u8_url=`load_file_br_get_m3u8_url "$url"`
    if [ -z "$m3u8_url" ]; then
        error "Video m3u8 url is not found"
        return 1
    fi
    msg "Found m3u8 url"
    Ytn "$m3u8_url" "$ofname"
}

# Load m3u8 url for video url from Brighteon.com
# load_file_br_get_m3u8_url(url)
# args:
#   url - The url for video on Brighteon.com
# stdout:
#   The m3u8 url for video url
# return:
#   0 - If source file loaded and parsed
#   1 - If any error
load_file_br_get_m3u8_url()
{
    local url=$1
    curl -s "$url" | sed '
s%^.*"source":\[{"src":"%%
s%","type":.*$%%
q
'
}

# Load file from Dzen.ru
# load_file_dz(url, ofname)
# args:
#   url - The url for video on Dzen.ru
#   ofname - The output filename for saving loaded video
# return:
#   0 - If file loaded
#   1 - If any error
load_file_dz()
{
    local url=$1
    local ofname=$2
    local m3u8_url

    msg "Loading file from Dzen.ru to $ofname"
    m3u8_url=`load_file_dz_get_m3u8_url "$url"`
    if [ -z "$m3u8_url" ]; then
        error "Video m3u8 url is not found"
        return 1
    fi
    msg "Found m3u8 url"
    Ytn "$m3u8_url" "$ofname"
}

# Load m3u8 url for video url from Dzen.ru
# load_file_dz_get_m3u8_url(url)
# args:
#   url - The url for video on Dzen.ru
# stdout:
#   The m3u8 url for video url
# return:
#   0 - If source file loaded and parsed
#   1 - If any error
load_file_dz_get_m3u8_url()
{
    local url=$1
    local url_embed
    local url_final
    local out

    url_embed=$(load_file_dz_load_m3u8_embed "$url")
    url_final=$(load_file_dz_load_m3u8_final "${url_embed}")
    out="${url_final}"
    echo "$out"
}

# Load embed url for video url from Dzen.ru
# load_file_dz_load_m3u8_embed(url)
# args:
#   url - The url for video on Dzen.ru
# stdout:
#   The embed url for video url
# return:
#   0 - If source file loaded and parsed
#   1 - If any error
load_file_dz_load_m3u8_embed()
{
    local url=$1
    local out

    out=$(
        curl -s -b "Session_id=noauth" "$url" | sed -n '
/<meta property="twitter:player:stream"/ {
    s/^.*<meta property="twitter:player:stream" content="\([^"]*\)".*$/\1/p
    q
}
'
    )
    echo "$out"
}

# Load final url for embed video url from Dzen.ru
# load_file_dz_load_m3u8_final(url)
# args:
#   url - The embed url for video on Dzen.ru
# stdout:
#   The final url for embed video url
# return:
#   0 - If source file loaded and parsed
#   1 - If any error
load_file_dz_load_m3u8_final()
{
    local url=$1
    local out

    out=$(
        curl -s "$url" | sed -n '
/"options":\[\],"url":"/ {
    s/^.*"options":\[\],"url":"\([^"]*\).*$/\1/p
    q
}
'
    )
    echo "$out"
}

# Load video from YouTube, Ok.ru, Vk.com, Mail.ru, Rutube.ru, Brighteon.com
# or Dzen.ru with determination of optimal video format
# main([url, ofname])
# args:
#   url - The url for video on YouTube, Ok.ru, Vk.com, Mail.ru, Rutube.ru,
#         Brighteon.com or Dzen.ru
#   ofname - The output filename for the loaded video
# return:
#   0 - If video loaded and saved
#   1 - If any error
main()
{
    local url
    local ofname

    case $# in
      0)
        usage
        return 1
        ;;
      1)
        [ "$1" = "--help" ] && {
            help_info
            return 1
        }
        [ "$1" = "--version" ] && {
            print_version
            return 1
        }
        ;;
      2)
        usage
        url=$1
        ofname=$2
        load_file "$url" "$ofname" || return 1
        ;;
      *)
        error "unknown arglist: "$*""
        return 1
        ;;
    esac
    return 0
}

main "$@" || exit 1

exit 0
