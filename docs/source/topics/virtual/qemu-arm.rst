QEMU for and on ARM cores
================================

Installing Debian on QEMU's 64-bit ARM “virt” board
-------------------------------------------------------

This post is a 64-bit companion to an earlier post of mine where I described how to get Debian running on QEMU emulating a 32-bit ARM “virt” board. Thanks to commenter snak3xe for reminding me that I’d said I’d write this up…
Why the “virt” board?

For 64-bit ARM QEMU emulates many fewer boards, so “virt” is almost the only choice, unless you specifically know that you want to emulate one of the 64-bit Xilinx boards. “virt” supports supports PCI, virtio, a recent ARM CPU and large amounts of RAM. The only thing it doesn’t have out of the box is graphics.
Prerequisites and assumptions



Prerequisites
""""""""""""""""""""""

..  code::

    $ sudo dnf install qemu libguestfs virt-filesystems

I suggest creating a subdirectory for these and the other files we're going to create.

..  code::

    wget -O installer-linux https://ftp.debian.org/debian/dists/stable/main/installer-arm64/current/images/netboot/debian-installer/arm64/linux
    wget -O installer-initrd.gz https://ftp.debian.org/debian/dists/stable/main/installer-arm64/current/images/netboot/debian-installer/arm64/initrd.gz

Saving them locally as installer-linux and installer-initrd.gz means they won’t be confused with the final kernel and initrd that the installation process produces.

..  note::

    If we were installing on real hardware we would also need a “device tree” file to tell the kernel the details 
    of the exact hardware it’s running on. QEMU’s “virt” board automatically creates a device tree internally and 
    passes it to the kernel, so we don’t need to provide one.


Installing
""""""""""""""""""""""""

First we need to create an empty disk drive to install onto. I picked a 5GB disk but you can make it larger if you like.

..  code::

    qemu-img create -f qcow2 hda.qcow2 5G

Now we can run the installer:

..  code::
	
    qemu-system-aarch64 -M virt -m 1024 -cpu cortex-a53 \
    -kernel installer-linux \
    -initrd installer-initrd.gz \
    -drive if=none,file=hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-pci,drive=hd \
    -netdev user,id=mynet \
    -device virtio-net-pci,netdev=mynet \
    -nographic -no-reboot

The installer will display its messages on the text console (via an emulated serial port). Follow its instructions to install Debian to the virtual disk; it’s straightforward, but if you have any difficulty the Debian installation guide may help.

The actual install process will take a few hours as it downloads packages over the network and writes them to disk. It will occasionally stop to ask you questions.

Late in the process, the installer will print the following warning dialog:

..  code::

    +-----------------| [!] Continue without boot loader |------------------+
    |                                                                       |
    |                       No boot loader installed                        |
    | No boot loader has been installed, either because you chose not to or |
    | because your specific architecture doesn't support a boot loader yet. |
    |                                                                       |
    | You will need to boot manually with the /vmlinuz kernel on partition  |
    | /dev/vda1 and root=/dev/vda2 passed as a kernel argument.             |
    |                                                                       |
    |                              <Continue>                               |
    |                                                                       |
    +-----------------------------------------------------------------------+  

Press continue for now, and we’ll sort this out later.

Eventually the installer will finish by rebooting — this should cause QEMU to exit (since we used the -no-reboot option).

At this point you might like to make a copy of the hard disk image file, to save the tedium of repeating the install later.

Extracting the kernel
""""""""""""""""""""""""""

The installer warned us that it didn’t know how to arrange to automatically boot the right kernel, so we need to do it manually. For QEMU that means we need to extract the kernel the installer put into the disk image so that we can pass it to QEMU on the command line.

There are various tools you can use for this, but I’m going to recommend libguestfs, because it’s the simplest to use. To check that it works, let’s look at the partitions in our virtual disk image:

..  code::
	
    $ virt-filesystems -a hda.qcow2 
    /dev/sda1
    /dev/sda2

If this doesn’t work, then you should sort that out first. A couple of common reasons I’ve seen:

    - if you’re on Ubuntu then your kernels in /boot are installed not-world-readable; you can fix this with ``sudo chmod 644 /boot/vmlinuz*``
    - if you’re running Virtualbox on the same host it will interfere with libguestfs’s attempt to run KVM; you can fix that by exiting Virtualbox 

Looking at what’s in our disk we can see the kernel and initrd in /boot:

..  code::

    $ virt-ls -a hda.qcow2 /boot/
    System.map-4.9.0-3-arm64
    config-4.9.0-3-arm64
    initrd.img
    initrd.img-4.9.0-3-arm64
    initrd.img.old
    lost+found
    vmlinuz
    vmlinuz-4.9.0-3-arm64
    vmlinuz.old

and we can copy them out to the host filesystem:
1
	
..  code::

    virt-copy-out -a hda.qcow2 /boot/vmlinuz-4.9.0-3-arm64 /boot/initrd.img-4.9.0-3-arm64 .

..  note::

    We want the longer filenames, because vmlinuz and initrd.img are just symlinks and virt-copy-out won't copy them.

..  warning::

    An important warning about ``libguestfs``, or any other tools for accessing disk images from the host system: 
    Do not try to use them while QEMU is running, or you will get disk corruption when both the guest OS inside QEMU and 
    ``libguestfs`` try to update the same image.

If you subsequently upgrade the kernel inside the guest, you’ll need to repeat this step to extract the new kernel and initrd, and then update your QEMU command line appropriately.

Running the virtual machine
""""""""""""

To run the installed system we need a different command line which boots the installed kernel and initrd, 
and passes the kernel the command line arguments the installer told us we’d need:

..  code::	

    qemu-system-aarch64 -M virt -m 1024 -cpu cortex-a53 \
    -kernel vmlinuz-4.9.0-3-arm64 \
    -initrd initrd.img-4.9.0-3-arm64 \
    -append 'root=/dev/vda2' \
    -drive if=none,file=hda.qcow2,format=qcow2,id=hd \
    -device virtio-blk-pci,drive=hd \
    -netdev user,id=mynet \
    -device virtio-net-pci,netdev=mynet \
    -nographic

This should boot to a login prompt, where you can log in with the user and password you set up during the install.

The installation has an SSH client, so one easy way to get files in and out is to use “scp” from inside the VM to talk to 
an SSH server outside it. Or you can use libguestfs to write files directly into the disk image (for instance using virt-copy-in) — 
but make sure you only use libguestfs when the VM is not running, or you will get disk corruption.

virt-manager
--------------------------

An easier way to install and start a virtual machine is with ``virt-manager``. 
The ``virt-manager`` application is a desktop user interface for managing virtual machines through ``libvirt``. 
It primarily targets KVM VMs, but also manages Xen and LXC (linux containers).

Installation
""""""""""""""""""""""

..  code::

    $ sudo dnf install @virtualization


Usage
"""""""""""""""""""""""

The usage is fairly straight forward and intuitive. Simply download a GNU/Linux iso file or create one 
using ``mkiso`` or other tools. Create a new virtual machine, add the iso image and configure the virtual
hardware to your liking.

..  note::

    Please make sure that your user is part of the `libvirt` system group in order to use the full
    feature set and enable things like networking.