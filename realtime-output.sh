exec 5>&1
FF=$(echo aaa|tee /dev/fd/5)
echo $FF
