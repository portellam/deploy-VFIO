#!/bin/bash sh

##
## Author(s):    Alex Portell <github.com/portellam>
##

# declare vars #
str1="1 2 3"
str2="1 Ab 123"
declare -a arr1=("1" "2" "3")
declare -a arr2=("1" "Ab" "123")

# echo declaration #
echo -e 'str1="1 2 3"
str2="1 Ab 123"
declare -a arr1=("1" "2" "3")
declare -a arr2=("1" "Ab" "123")'
echo

# echo as is #
echo -e '$str1:'"'$str1'"
echo -e '$str2:'"'$str2'"
echo -e '$arr1:'"'$arr1'"
echo -e '$arr2:'"'$arr2'"
echo

# echo length of non arrays #
echo -e '${#str1}:'"'${#str1}'"
echo -e '${#str2}:'"'${#str2}'"
echo -e '${#arr1}:'"'${#arr1}'"
echo -e '${#arr2}:'"'${#arr2}'"
echo

# echo length of arrays #
echo -e '${#str1[@]}:'"'${#str1[@]}'"
echo -e '${#str2[@]}:'"'${#str2[@]}'"
echo -e '${#arr1[@]}:'"'${#arr1[@]}'"
echo -e '${#arr2[@]}:'"'${#arr2[@]}'"
echo

# echo entire array #
echo -e '${!str1[@]}:'"'${!str1[@]}'"
echo -e '${!str2[@]}:'"'${!str2[@]}'"
echo -e '${!arr1[@]}:'"'${!arr1[@]}'"
echo -e '${!arr2[@]}:'"'${!arr2[@]}'"
echo

# echo each element by key in arrays #
for k in ${!str1[@]}; do echo -e '${str1['"$k"']:'"'${str1[k]}'"; done && echo
for k in ${!str2[@]}; do echo -e '${str2['"$k"']:'"'${str2[k]}'"; done && echo
for k in ${!arr1[@]}; do echo -e '${arr1['"$k"']:'"'${arr1[k]}'"; done && echo
for k in ${!arr2[@]}; do echo -e '${arr2['"$k"']:'"'${arr2[k]}'"; done && echo

exit 0
