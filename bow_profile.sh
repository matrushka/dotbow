function bow {
	arguments=""
	for item in "$@"
	do
		arguments="$arguments $item"
	done
	output=`~/.bow/bow.sh$arguments`
	command=`echo $output |cut -d':' -f1`
	if [[ "$command" == "execute" ]]
	then
		to_run=`echo $output |cut -d':' -f2`
		$to_run
	elif [[ "$command" == "execute_and_refresh" ]]
	then
		to_run=`echo $output |cut -d':' -f2`
		$to_run
		touch ~/.bow/vhosts
	else
		printf "%b\n" "$output"
	fi
}

function _bow {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"

	if [[ ${cur} == * && ${prev} == "bow" ]] ; then
		opts="list switch edit clear install uninstall server"
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi

	if [[ ${cur} == * && (${prev} == "switch" || ${prev} == "edit") ]] ; then
		opts=`ls ~/.bow/vhosts | sed -e 's/\.[a-zA-Z]*$//'`
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}

complete -F _bow bow