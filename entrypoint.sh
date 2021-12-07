#!/bin/sh
cd arangodb
echo "-----------"
clang-format --version
echo "-----------"
echo "clang-format -style=file -i $@"
echo "-----------"
clang-format -style=file -i $@
echo "erledigt"