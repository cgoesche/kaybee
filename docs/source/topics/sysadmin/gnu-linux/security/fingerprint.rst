Fingerprint authentication
===========================

To use a fingerprint for authentication you should first make sure that your system has the needed software tools, libraries and drivers installed
that will be used to interact with the reader.

Prerequisites
-----------------

Debian/Ubuntu
"""""""""""""""""

..  code::

    $ sudo apt update
    $ sudo apt install fprintd libfprint-2-2 libfprint-2-tod1

Fedora/RHEL
""""""""""""""""

..  code::

    $ sudo dnf update
    $ sudo dnf install fprintd fprintd-devel fprintd-pam

..  note::

    ``libpam-fprintd`` and ``fprintd-pam`` are needed to enable fingerprint login through PAM which is used by GNOME for example.


Fprint
-------------

The Fprint project aims to plug a gap in the Linux desktop: support for consumer fingerprint reader devices. 
Part of the project are two important components, namely `fprintd` and `libfprint`.

**libfprint** is the component which does the dirty work of talking to fingerprint reading devices, and processing fingerprint data. 
It is a comprehensive API that enables software developers to create applications that generate and store fingerprint data.

**fprintd** is a tool that actually makes use of `libfprint` and enables fingerprint scanning capabilities via D-Bus.

.. _fprintd-usage:
Usage
~~~~~~~~~~~~~~~

Enroll a fingerprint for a user
""""""""""""""""""""""""""""""""""""

..  code::

    $ fprintd-enroll -f "finger-name" <username>

You will be prompted for the specified user's password and on success can then proceed with the scanning of the finger.
Keep scanning the finger until you see the program return the message ``Enroll result: enroll-completed``. 


Verify a fingerprint 
""""""""""""""""""""""""

To verify an enrolled fingerprint simply run this:

..  code::

    $ fprintd-verify -f <finger-name> <username>

Scan your finger and if the results match what is stored in the database you should see something similar to ``Verify result: verify-match (done)``.

To finally make sure that fingerprint login is active, consult your desktop environments user settings and enable it if possible.

..  note::

    If you are running a Debian/Ubuntu system you can run ``sudo pam-auth-update`` to enable the fingerprint login via PAM otherwise simply
    logout and back in.

Issues
-------------------

Fingerprint reader device not found
""""""""""""""""""""

If `fprintd-enroll` returned an error message similar to the one below, you will have to search for the fingerprint reader's vendor and product 
IDs and install its drivers if available.

..  code::

    Impossible to enroll: GDBus.Error:net.reactivated.Fprint.Error.NoSuchDevice: No devices available

Find the USB device
~~~~~~~~~~~~

Fingerprint readers are mostly implemented as USB devices on the system. So, if the BIOS has the fingerprint device activated and
the Linux USB subsystem detects them you should be able to find its information with one of the methods below.


fwupdmgr
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

..  code::

    $ fwupdmgr get-devices

The output will show a topology of hardware components and general information about the vendor, its function and more.
This context can help you select the right USB device in the other two commands.

lsusb
^^^^^^^^^^^^^^^^^^^

..  code::

    # If you know the manufacturer name
    $ lsusb

    [...]
    Bus 003 Device 002: ID 06cb:00f0 Synaptics, Inc.
    [...]

    # If the manufacturer name is unknown
    lsusb -v

The output of the second command is significantly longer and should give you some clues of the devices functions.

debugfs
^^^^^^^^^^^^^^^
..  code::

    $ cat /sys/kernel/debug/usb/devices

    T:  Bus=03 Lev=00 Prnt=00 Port=02 Cnt=00 Dev#=  2 Spd=10000 MxCh= 1
    B:  Alloc=  0/800 us ( 0%), #Int=  0, #Iso=  0
    D:  Ver= 3.10 Cls=09(hub  ) Sub=00 Prot=03 MxPS= 9 #Cfgs=  1
    P:  Vendor=06cb ProdID=00f0 Rev= 6.14
    S:  Manufacturer=Synaptics, Inc.


The ``Vendor`` and ``ProdID`` fields available in the debugfs are essentially the same information as the string after ``ID`` in 
the ``lsusb`` command output. 

With the vendor and product information you can now go to this page https://fprint.freedesktop.org/supported-devices.html
and search for your specific device and make sure it is supported by the fprint project. 

If it is listed you should either make sure that your system firmware is up to date, that you have properly installed these packages:
``fprintd libfprint-2-2 libfprint-2-tod1``. 

However, in some cases you need to install proprietary drivers like in the case of the DELL Latitude 5300.
The oem driver can be found here: https://git.launchpad.net/~oem-solutions-engineers/libfprint-2-tod1-broadcom/+git/libfprint-2-tod1-broadcom/ .
And is installed as follows:

..  code::

    $ git clone <URL>
    $ cd libfprint-2-tod1-broadcom
    $ chmod +x install.sh 
    $ ./install.sh
    
Wait a few seconds or reboot the system and follow the steps in :ref:`fprintd-usage`.

..  note::

    Should your fingerprint reader not be on the list, then any further effort into this is useless and waiting for 
    future support is the only thing you can do.
