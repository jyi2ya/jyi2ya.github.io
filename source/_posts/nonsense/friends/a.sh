IFS="
"
for i in $(awk -F： '/：.*\/$/ { print $1" "$2"\n"$2 }' main.md); do
	echo "$i"
	echo "$i" | clip
	read _
done
