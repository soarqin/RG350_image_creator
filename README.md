Before Use
==========
* The structure of RG-350 raw image
  * The block size is 512 bytes
  * It includes 2 partitions in DOS partition table: a FAT32 boot partition started at block 32 and ended at block 819199(400MB in total) and a EXT4 partition started at block 819200

* file `env.sh`

  this file includes environment settings:
  * `filename` is the raw image filename used for all scripts.
  * `part1_size` and `part2_size` are sizes for both partitions in MB.

* All scripts must be run in `root`, just use `sudo`

HOW-TO
======
* create.sh

  Run to create a empty raw image for further use, the partition table and 2 partitions are created, and the core boot binary file `mininit-syspart` is copied to boot partition.

* merge_update.sh

  Update boot partition, need one argument, which is the updater opk built by [TonyJih's updater](https://github.com/tonyjih/RG350_updater).

* copy_data.sh

  Rebuild data partition with given data, need at least one argument, for every argument:
  * If it is an compressed file (like *.tar.gz or *.zip), the file will be decompressed to data partition with top directory stripped out.
  * If it is a folder, all files in the folder will be copied over.
  * If it is an opk, it will be copied to `apps` folder in data partition.
  * If it is an old flashable raw image file, all files in data parition of the image will be copies over.
