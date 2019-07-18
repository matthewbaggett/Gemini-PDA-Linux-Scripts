SHELL := /bin/bash

clean:
	-rm -Rf ./KERNEL_OUT
	-[ -d ./kernel-3.18 ] && sudo umount ./kernel-3.18 && rm -Rf ./kernel-3.18

clone:
	[ -d kernel-3.18-clean ] || git clone https://github.com/gemian/gemini-linux-kernel-3.18 kernel-3.18-clean
	mkdir ./kernel-3.18 ./KERNEL_OUT
	sudo mount -t tmpfs tmpfs ./kernel-3.18
	rsync -ar --info=progress2 --exclude='.git/' ./kernel-3.18-clean/* ./kernel-3.18

kernel: clean clone
	cp kernel.config ./KERNEL_OUT/.config
	make O=../KERNEL_OUT -C kernel-3.18 -j4
