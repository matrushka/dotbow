function bow {
	arguments=""
	for item in "$@"
	do
		arguments="$arguments $item"
	done
	output=`~/.bow/bow.sh$arguments`
	command=`echo $output |cut -d':' -f1`
	if [ "$command" == "execute" ]
	then
		to_run=`echo $output |cut -d':' -f2`
		$to_run
	else
		printf "%b\n" "$output"
	fi
}