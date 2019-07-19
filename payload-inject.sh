#!/bin/bash
scp -q startup.sh shutdown.sh .gem-config gemini@10.15.19.82:~/;
scp -q -r bin gemini@10.15.19.82:~/;
ssh -t gemini@10.15.19.82 "/bin/bash ~/startup.sh"