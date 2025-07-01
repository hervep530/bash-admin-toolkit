#!/bin/bash
# 
# Base folder    : $OPT_PREFIX/bash-admin-toolkit
# Filename       : launcher.sh
# Description    : One to manage all... this script will call sub-script directly, or helper matching with trigger which includes helper config
#                  will take all files with execution right and extension sh, conf, args, or env
#                  *.sh will be standalone script, and other extensions are for configuration files used to call helpers in sbin tree
# Author         : Hervé Pineau - Copyright [2025]
# Date           : 2025-06-30
# Version        : 0.1.0
# License        : Apache 2.0
#
# Usage          : sudo ./opt/bash-admin-toolkit/launcher.sh  (default will take trigger in ./opt/bash-admin-toolkit/launcher.d/
# Examples       : sudo bash -c "PREFIX=$(realpath ./) TRIGGER_TYPE=postinstall opt/bash-admin-toolkit/launcher.sh" _(trigger in postinstall.d)
#
# Notes          : Need bash, grep, sed.
#                  Bash >= 4.0
#
#==============================#


#Global variables
TRIGGER_DIR=$(realpath ${BASH_SOURCE[0]} | sed -e 's/\.sh/.d/g')
[ -z $TRIGGER_TYPE ] || TRIGGER_DIR=$(dirname $(realpath ${BASH_SOURCE[0]}))/${TRIGGER_TYPE}.d
PREFIX_DIR="/usr"
[ -z $PREFIX ] || PREFIX_DIR=$PREFIX
HELPER_DIR="$PREFIX_DIR/sbin"
# Trigger files / path patterns
TRIGGER_SED_PATTERN="[0-9]\+-\([a-zA-Z0-9_-]\+\)\.\(sh\|conf\|config\|env\|args\)"
TRIGGER_CONF_PATTERN='CMD_LINE_OPTIONS=\"\?\(-[a-zA-Z]\|--[a-z-]\+\)\"\?'
# Patterns to identify parms and args lines in files trigger
ARG_KEY_GREP_PATTERN='(-[a-zA-Z]|--[a-z]+(-[a-z]+)*)'
VALUE_GREP_PATTERN='[a-zA-Z0-9./_][a-zA-Z0-9./_-]*' ;
ENV_GREP_PATTERN="^[A-Z_]+=$VALUE_GREP_PATTERN( *[ ;] *[A-Z_]+=$VALUE_GREP_PATTERN)*$"
ARGS_GREP_PATTERN="^ *$ARG_KEY_GREP_PATTERN(  *$VALUE_GREP_PATTERN)?(  *$ARG_KEY_GREP_PATTERN(  *$VALUE_GREP_PATTERN)?)* *$"
SEPARATOR_SED_PATTERN="\( *; *\| \+\)"

function get_helper_path() {
    local TRIGGER_FILE=$1
    local base_name=$(eval "sed -e 's/$TRIGGER_SED_PATTERN/\1/g' <<< \"$TRIGGER_FILE\"")
    echo "$HELPER_DIR/bat-${base_name}-helper.sh"
}

function get_trigger_type() {
    local TRIGGER_FILE=$1
    local trigger_type=$(eval "sed -e 's/$TRIGGER_SED_PATTERN/\2/g' <<< \"$TRIGGER_FILE\"")
    [ -x $TRIGGER_DIR/$TRIGGER_FILE ] || trigger_type="invalid"
    echo "$trigger_type"
}


for trigger in $(ls -1 $TRIGGER_DIR) ;do
# cmd_line_option=$(parm_to_args $parm_values)
    ls -l $TRIGGER_DIR/$trigger
    trigger_type=$(get_trigger_type $trigger)
    case $trigger_type in
	"args" ) 
	    # For each valid line (matches with args pattern), launch helper with arguments from line
	    while IFS= read -r args ;do
		if [[ "$args" =~ $ARGS_GREP_PATTERN ]] ;then
		    # clean options and call helper
		    cmd_line_option=$(eval "sed -e 's/$SEPARATOR_SED_PATTERN/ /g' <<< \"$args\"")
		    echo "[i] Launch helper"
		    $(get_helper_path $trigger) $cmd_line_option 
		fi
	    done < $TRIGGER_DIR/$trigger ;;
	"env" ) 
	    # For each valid line (matches with env pattern), launch helper with command environment variable from line
	    while IFS= read -r env_line ;do
		if [[ "$env_line" =~ $ENV_GREP_PATTERN ]] ;then
		    # clean environnement variables, and call helper
		    env_variables=$(eval "sed -e 's/$SEPARATOR_SED_PATTERN/ /g' <<< \"$env_line\"")
		    echo "[i] Launch helper"
		    /bin/bash -c "$env_variables $(get_helper_path $trigger)" 
		fi
	    done < $TRIGGER_DIR/$trigger ;;
	"conf" ) 
	    echo "[i] Launch helper with parameter from config file :$TRIGGER_DIR/$trigger"
	    $(get_helper_path $trigger) -c $TRIGGER_DIR/$trigger ;;
	"sh" )
	    echo "[i] Launch helper"
	    /bin/bash $TRIGGER_DIR/$trigger ;;
	* ) echo "$trigger_type";;
    esac
done


