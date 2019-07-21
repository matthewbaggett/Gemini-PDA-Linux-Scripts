#!/bin/bash
echo "Copying files to Gemini"
scp -q startup.sh shutdown.sh kernel.sh .gem-config gemini@10.15.19.82:~/;
scp -q -r bin gemini@10.15.19.82:~/;