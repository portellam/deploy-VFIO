
declare -a arr_rootKernel+=(`ls -1 /boot/vmli* | cut -d "z" -f 2`)

for str_rootKernel in ${arr_rootKernel[@]}; do
    str_output1="+'`lsb_release -i -s` `uname -o`, with `uname` $str_rootKernel (VGA: $str_thisVGA_deviceName)" 
done