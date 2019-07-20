#!/bin/bash
./script-inject.sh
ssh -t gemini@10.15.19.82 "/bin/bash ~/startup.sh"