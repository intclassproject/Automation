#!/bin/bash
service=$1
ip=$2
num=2
text=hello' '$RANDOM
check_result () {
exitCode=$?
message=$1
if [ $exitCode -eq 0 ]; then
	echo [SUCCESS] $message
else
	echo [FAILED] $message

fi
           }     

installDependencies () {
	if `! dpkg -s jq &>/dev/null`; then apt -y install j1 &>/dev/null; fi
}

validate_intdb () {
	echo "Verify DB is up before inserind data"
	STATUS=$(curl -s -o /dev/null -w '%{http_code}' $ip:27017)
        if [ $STATUS -eq 200 ]; then
    		echo "[SUCESS] Got 200! DB Up --continuing to next test!"

  	else
		echo "[FAILED] Got $STATUS :( DB Server not up yet..."
		exit 1
	fi
}

validate_intapi(){
	STATUS=$(curl -s  -o /dev/null -w '%{http_code}' http://$ip:3000)
	if [ $STATUS -eq 200 ]; then
                echo "[SUCESS] Got 200! API Server Up --continuing to next test!"

        else
                echo "[FAILED] Got $STATUS :( API Server not up yet..."
                exit 1
        fi
}




validate_intweb () {
	mymsg=$text
	res=$(curl -s -X POST -H "Content-Type:application/json" http://$ip:3000/postMessage \
		-d '{"userId":"'"$num"'","msg":"'"$text"'"}' | jq  '.success')
	if [ "$res" == "true" ]; then
		echo "[SUCCESS]  data inserted:$mymsg!"
		find_in_web $mymsg $num
		else
		echo "[FAILED] Got $res :( Information  Not saved ..."
		exit 1
	fi
}


find_in_web () {
        msg=$1' '$2
	num=$3
	tag1=th
	tag2=td
	curl  -d "userId=$num"  "http://$ip:5000/result" > result.html 2>&1
	sed -n "/<$tag1>/,/<\/$tag2>/p"  result.html  | grep  -i   -A1   "\b$msg\b" | grep -q  $num
	check_result "searching for $msg "
}


installDependencies
validate_$service
