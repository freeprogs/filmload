#!/bin/bash

# Loads a film from YouTube.com, Ok.ru, Vk.com, Mail.ru and Brighteon.com
# by url to output filename, selecting right format of the video.
# Copyright (C) 2021-2022, Slava <freeprogs.feedback@yandex.ru>

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
    echo "usage: $progname url savename" >&2
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

# Load file from the YouTube, Ok.ru, Vk.com, Mail.ru or Brighteon.com url
# to the output file
# load_file(url, ofname)
# args:
#   url - The url for video on YouTube, Ok.ru, Vk.com, Mail.ru
#         or Brighteon.com
#   ofname - The output file name
# return:
#   none
load_file()
{
    local url=$1
    local ofname=$2
    local urltype
    local UT_YT=0 UT_OK=1 UT_VK=2 UT_MR=3 UT_BR=4

    urltype=`detect_url_type "$url"`
    case $urltype in
      $UT_YT) load_file_yt "$url" "$ofname";;
      $UT_OK) load_file_ok "$url" "$ofname";;
      $UT_VK) load_file_vk "$url" "$ofname";;
      $UT_MR) load_file_mr "$url" "$ofname";;
      $UT_BR) load_file_br "$url" "$ofname";;
      *) error "Unknown url type: \"$urltype\"";;
    esac
}

# Detect url type that means on which site this url is placed
# detect_url_type(url)
# args:
#   url - The url to video on YouTube, Ok.ru, Vk.com, Mail.ru
#         or Brighteon.com
# return:
#   "0" - For YouTube url
#   "1" - For Ok.ru url
#   "2" - For Vk.com url
#   "3" - For Mail.ru url
#   "4" - For Brighteon.com url
#   none - if unknown url type
detect_url_type()
{
    local url=$1
    local UT_YT=0 UT_OK=1 UT_VK=2 UT_MR=3 UT_BR=4
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
    elif [ "$urlcore" = "www.brighteon.com" ]; then
        echo "$UT_BR"
    fi
}

# Get domain name from url with protocol and path
# get_url_core(url)
# args:
#   url - The url in form https://domain/path
# return:
#   "domain" - part of url between protocol and path
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
#   0 if file loaded
#   1 if any error
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
#   0 if file loaded
#   1 if any error
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
#   "format for hd" - string with format for hd
#   "format for sd" - string with format for sd if no hd
#   none - if no sd and no hd
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
#   0 if file loaded
#   1 if any error
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
    Ytf "$url" "$ofname" "$vformat"
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

    Ytl "$url" | awk '
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
#   0 if file loaded
#   1 if any error
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
#   "720p" | "1080p" | "480p" | none
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

# Load file from Brighteon.com
# load_file_mr(url, ofname)
# args:
#   url - The url for video on Brighteon.com
#   ofname - The output filename for saving loaded video
# return:
#   0 if file loaded
#   1 if any error
load_file_br()
{
    local url=$1
    local ofname=$2
    local m3u8_url
    local duration

    msg "Loading file from Brighteon.com to $ofname"
    m3u8_url=`load_file_br_get_m3u8_url "$url"`
    if [ -z "$m3u8_url" ]; then
        error "Video m3u8 url is not found"
        return 1
    fi
    msg "Found m3u8 url"
    duration=`load_file_br_get_duration "$url"`
    if [ -z "$duration" ]; then
        error "Duration is not found"
        return 1
    fi
    msg "Duration of video is $duration"
    msg "No resume. Start from beginning."
    Yt "$m3u8_url" "$ofname" 2>&1 | \
        load_file_br_wrapper_wrap_to_hdr_times
}

# Load m3u8 url for video url from Brighteon.com
# load_file_br_get_m3u8_url(url)
# args:
#   url - The url for video on Brighteon.com
# stdout:
#   the m3u8 url for video url
# return:
#   0 if source file loaded and parsed
#   1 if any error
load_file_br_get_m3u8_url()
{
    local url=$1
    curl -s "$url" | sed '
s%^.*"source":\[{"src":"%%
s%","type":.*$%%
q
'
}

# Load duration for video from Brighteon.com
# load_file_br_get_duration(url)
# args:
#   url - The url for video on Brighteon.com
# stdout:
#   duration of video
# return:
#   0 if source file loaded and parsed
#   1 if any error
load_file_br_get_duration()
{
    local url=$1
    curl -s "$url" | sed '
s%^.*"duration":"%%
s%","is.*$%%
q
'
}

# Wrap lines from stdin while downloading from Brighteon.com
# to header lines and time lines and print them to stdout
# load_file_br_wrapper_wrap_output()
# stdin:
#   lines - The output of download from Brighteon.com
# stdout:
#   header lines - Three header lines
#   time lines - Lines with time points in video
# return:
#   0 if wrapped
#   1 if any error
load_file_br_wrapper_wrap_to_hdr_times()
{
    sed -n '
1,3p
4,$ {
  /frame=/ {
    s/^.*time=//
    s/ bitrate.*$//
    p
  }
}
'
}

# Load video from YouTube, Ok.ru, Vk.com, Mail.ru or Brighteon.com
# with determination of optimal video format
# main([url, ofname])
# args:
#   url - The url for video on YouTube, Ok.ru, Vk.com, Mail.ru or Brighteon.com
#   ofname - The output filename for the loaded video
# return:
#   0 - if video loaded and saved
#   1 - if any error
main()
{
    case $# in
      0) usage; return 1;;
      2) load_file "$1" "$2" && return 0;;
      *) error "unknown arglist: "$*""; return 1;;
    esac
}

main "$@" || exit 1

exit 0
