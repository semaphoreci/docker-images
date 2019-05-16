
for f in *; do 
	echo "Processing $f file.."
	version=$(echo $f | cut -d "-" -f "3,4,5" | sed s/-/\./g )
	prefix=$(echo $f | cut -d "-" -f "1,2")
        sufix=$(echo $f | cut -d "-" -f 6-)
	echo "prefix: " $prefix
	echo "sufix: " $sufix
	echo "version: $version"
	if [[ $sufix != '' ]]; then
		echo $f $prefix-$version-$sufix
		mv $f $prefix-$version-$sufix
	else
		echo $f $prefix-$version
		mv $f $prefix-$version
	fi
done

