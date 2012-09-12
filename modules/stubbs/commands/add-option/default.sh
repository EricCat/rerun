#!/usr/bin/env bash
#
# NAME
#
#   add-option
#
# DESCRIPTION
#
#   add a command option
#

# Source common function library
source $RERUN_MODULES/stubbs/lib/functions.sh || { echo "failed laoding function library" ; exit 1 ; }


# Init the handler
rerun_init 

# Get the options
while [ "$#" -gt 0 ]; do
    OPT="$1"
    case "$OPT" in
        # options without arguments
	# options with arguments
	-o|--option)
	    rerun_option_check "$#"
	    OPTION="$2"
	    shift
	    ;;
	--desc*)
	    rerun_option_check "$#"
	    DESC="$2"
	    shift
	    ;;
	-c|--command)
	    rerun_option_check "$#"
		# Parse if command is named "module:command"
	 	regex='([^:]+)(:)([^:]+)'
		if [[ $2 =~ $regex ]]
		then
			MODULE=${BASH_REMATCH[1]}
			COMMAND=${BASH_REMATCH[3]}
		else
	    	COMMAND="$2"		
	    fi
	    shift
	    ;;
	-m|--module)
	    rerun_option_check "$#"
	    MODULE="$2"
	    shift
	    ;;
	--req*)
	    rerun_option_check "$#"
	    REQ="$2"
	    shift
	    ;;
	--arg*)
	    rerun_option_check "$#"
	    ARGS="$2"
	    shift
	    ;;
	--long)
	    rerun_option_check "$#"
	    LONG="$2"
	    shift
	    ;;
	-range)
	    rerun_option_check "$#"
	    RANGE="$2"
	    shift
	    ;;			
	-d|--default)
	    rerun_option_check "$#"
	    DEFAULT="$2"
	    shift
	    ;;
        # unknown option
	-?)
	    rerun_option_error
	    ;;
	  # end of options, just arguments left
	*)
	    break
    esac
    shift
done

# Post process the options
[ -z "$OPTION" ] && {
    echo "Option: "
    read OPTION
}

[ -z "$DESC" ] && {
    echo "Description: "
    read DESC
}

[ -z "$MODULE" ] && {
    echo "Module: "
    select MODULE in $(rerun_modules $RERUN_MODULES);
    do
	echo "You picked module $MODULE ($REPLY)"
	break
    done
}

[ -z "$COMMAND" ] && {
    echo "Command: "
    select COMMAND in $(rerun_commands $RERUN_MODULES $MODULE);
    do
	echo "You picked command $COMMAND ($REPLY)"
	break
    done
}

[ -z "$REQ" ] && {
    echo "Required (true/false): "
    select REQ in true false;
    do
	break
    done
}


[ -z "$DEFAULT" ] && {
    echo "Default: "
    read DEFAULT
}

# Verify this command exists
#
[ -d $RERUN_MODULES/$MODULE/commands/$COMMAND ] || {
    rerun_die "command does not exist: \""$MODULE:$COMMAND\"""
}

# Generate metadata for new option

(
    cat <<EOF
# generated by stubbs:add-option
# $(date)
NAME=$OPTION
DESCRIPTION="$DESC"
ARGUMENTS=${ARGS:-true}
REQUIRED=${REQ:-true}
SHORT=${OPTION:0:1}
LONG=${LONG:-$OPTION}
DEFAULT=$DEFAULT
RANGE=$RANGE

EOF
) > $RERUN_MODULES/$MODULE/commands/$COMMAND/$OPTION.option || rerun_die
echo "Wrote option metadata: $RERUN_MODULES/$MODULE/commands/$COMMAND/$OPTION.option"


# Generate option parser script.
optionScript=$RERUN_MODULES/$MODULE/commands/$COMMAND/options.sh
rerun_generateOptionsParser \
    $RERUN_MODULES $MODULE \
    $COMMAND > $optionScript || rerun_die
echo "Wrote options script: $optionScript"

# Update variable summary in command script.
commandScript=$RERUN_MODULES/$MODULE/commands/$COMMAND/default.sh
if [ -f "$commandScript" ]
then
    rerun_rewriteCommandScriptHeader \
        $RERUN_MODULES $MODULE $COMMAND > ${commandScript}.$$ || {
        rerun_die "Error updating command script header"
    }
    mv $commandScript.$$ $commandScript || {
        rerun_die "Error updating command script header"
    }
    echo "Updated command script header: $commandScript"
fi

# Done
exit $?

