#!/bin/bash
./copy-files-to-gem.sh
echo "Running $1 on Gemini:"
ssh -t gemini@10.15.19.82 "/bin/bash ~/$1"
